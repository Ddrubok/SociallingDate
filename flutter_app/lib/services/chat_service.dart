import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart'; // MessageModel 필요 시 import

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. [기존] 1:1 채팅방 생성 또는 가져오기 (기존 유지)
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    try {
      final existingRoom = await _firestore
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUserId)
          .where('type', isEqualTo: 'private') // 1:1 구분 추가 권장
          .get();

      for (var doc in existingRoom.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(otherUserId) && participants.length == 2) {
          return doc.id;
        }
      }

      final newRoom = await _firestore.collection('chat_rooms').add({
        'type': 'private', // 1:1 채팅 타입 명시
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, otherUserId: 0},
      });

      return newRoom.id;
    } catch (e) {
      rethrow;
    }
  }

  // 2. [신규] 소셜링 그룹 채팅방 생성 (강제 생성)
  Future<String> createGroupChat({
    required String hostId,
    required String groupTitle,
    required String initialMessage,
  }) async {
    try {
      final newRoom = await _firestore.collection('chat_rooms').add({
        'type': 'group', // 그룹 채팅 타입 명시
        'title': groupTitle, // 채팅방 이름 (소셜링 제목)
        'participants': [hostId], // 초기 참여자는 주최자 1명
        'lastMessage': initialMessage,
        'lastMessageSenderId': 'system',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {hostId: 0},
        // 그룹 채팅은 participantNames를 관리하기 어려우므로,
        // 각자 로컬에서 유저 정보를 조회하거나 별도 필드로 관리합니다.
      });
      return newRoom.id;
    } catch (e) {
      rethrow;
    }
  }

  // 3. [신규] 그룹 채팅방 참여 (소셜링 참여 시 호출)
  Future<void> joinGroupChat(String roomId, String userId) async {
    try {
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'participants': FieldValue.arrayUnion([userId]), // 참여자 목록에 추가
        'unreadCount.$userId': 0, // 내 읽지 않음 카운트 0으로 초기화
      });
    } catch (e) {
      rethrow;
    }
  }

  // 4. [수정] 메시지 전송 (1:1 및 그룹 공용)
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    try {
      // 메시지 추가
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'text': text,
            'timestamp': FieldValue.serverTimestamp(),
            'isModerated': false,
            'status': 'safe',
            'isRead': false,
          });

      // 채팅방 정보 업데이트 (읽지 않음 카운트 로직 개선)
      final roomRef = _firestore.collection('chat_rooms').doc(roomId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final participants = List<String>.from(data['participants'] ?? []);
        final currentUnreadCount = Map<String, dynamic>.from(
          data['unreadCount'] ?? {},
        );

        // [핵심] 나(보낸 사람)를 제외한 모든 참여자의 unreadCount를 +1
        for (var userId in participants) {
          if (userId != senderId) {
            final count = (currentUnreadCount[userId] as num?)?.toInt() ?? 0;
            currentUnreadCount[userId] = count + 1;
          }
        }

        transaction.update(roomRef, {
          'lastMessage': text,
          'lastMessageSenderId': senderId,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': currentUnreadCount,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  // 5. 메시지 스트림 (기존 유지)
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // 6. 채팅방 목록 스트림 (기존 유지)
  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatRoomModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // 7. 읽음 처리 (기존 유지)
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    try {
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      // 문서가 없거나 권한 문제 시 무시
    }
  }

  Future<void> leaveChatRoom(String roomId, String userId) async {
    try {
      final roomRef = _firestore.collection('chat_rooms').doc(roomId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomRef);
        if (!snapshot.exists) return;

        final participants = List<String>.from(
          snapshot.data()?['participants'] ?? [],
        );

        // 참여자 목록에서 나(userId) 제거
        participants.remove(userId);

        if (participants.isEmpty) {
          // 남은 사람이 없으면 방 자체를 삭제 (선택 사항)
          transaction.delete(roomRef);
        } else {
          // 남은 사람이 있으면 참여자 목록 갱신 & 내 읽음 카운트 삭제
          transaction.update(roomRef, {
            'participants': participants,
            'unreadCount.$userId': FieldValue.delete(),
          });
        }
      });
    } catch (e) {
      rethrow;
    }
  }
}

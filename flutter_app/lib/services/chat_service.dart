import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 채팅방 생성 또는 기존 채팅방 가져오기
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    try {
      // 기존 채팅방 찾기
      final existingRoom = await _firestore
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingRoom.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // 새 채팅방 생성
      final newRoom = await _firestore.collection('chat_rooms').add({
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

  // 메시지 전송
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    try {
      // 1. 배치(Batch) 생성: 여러 작업을 한 번에 묶음
      final batch = _firestore.batch();

      // 2. 메시지 추가 작업 준비
      final messageRef = _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc(); // ID 자동 생성

      final messageData = {
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isModerated': false,
        'status': 'safe',
        'isRead': false,
      };

      batch.set(messageRef, messageData);

      final roomRef = _firestore.collection('chat_rooms').doc(roomId);
      final roomDoc = await roomRef.get();

      if (roomDoc.exists) {
        final participants = List<String>.from(
          roomDoc.data()?['participants'] ?? [],
        );
        final otherUserId = participants.firstWhere(
          (id) => id != senderId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          batch.update(roomRef, {
            'lastMessage': text,
            'lastMessageSenderId': senderId,
            'lastMessageAt': FieldValue.serverTimestamp(),
            'unreadCount.$otherUserId': FieldValue.increment(1),
          });
        }
      }

      // 4. 한 번에 전송 (네트워크 비용 1회)
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // 메시지 스트림
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

  // 사용자의 채팅방 목록 스트림
  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        // .orderBy('lastMessageAt', descending: true) // [삭제] 이 줄 때문에 인덱스가 필요했습니다.
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map((doc) => ChatRoomModel.fromFirestore(doc.data(), doc.id))
              .toList();

          // [추가] 앱 내부에서 최신순으로 정렬합니다.
          rooms.sort((a, b) {
            // null 체크: 시간이 없으면 아주 예전 시간으로 취급
            final aTime =
                a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime); // 내림차순 정렬 (최신순)
          });

          return rooms;
        });
  }

  // 읽음 처리
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    try {
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      rethrow;
    }
  }
}

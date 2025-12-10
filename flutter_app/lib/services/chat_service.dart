import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 채팅방 생성 또는 가져오기
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    // 1:1 채팅방은 참가자 조합으로 유니크하게 관리하는 것이 좋음
    // 여기서는 간단하게 기존 로직 유지하되, 쿼리 효율성을 위해 participant로 검색

    // 이미 존재하는 방인지 확인 (participants에 두 명이 모두 포함된 방)
    // Firestore 쿼리 한계로 인해, 배열 검색은 'arrayContains' 하나만 가능하거나 복잡함.
    // 실무 팁: 1:1 채팅은 ID를 'user1_user2' (알파벳순 정렬) 형식으로 만드는 게 가장 확실함.

    List<String> ids = [currentUserId, otherUserId];
    ids.sort(); // 알파벳순 정렬 (A_B)
    String chatRoomId = "${ids[0]}_${ids[1]}";

    final docRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      // 방이 없으면 새로 생성
      ChatRoomModel newRoom = ChatRoomModel(
        roomId: chatRoomId,
        participants: [currentUserId, otherUserId],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: {currentUserId: 0, otherUserId: 0},
        type: 'individual',
      );

      await docRef.set(newRoom.toFirestore());
    }

    return chatRoomId;
  }

  // 1-1. 그룹 채팅방 생성 (소셜링용)
  Future<String> createGroupChat({
    required String hostId,
    required String groupTitle,
    required String initialMessage,
  }) async {
    final docRef = _firestore.collection('chat_rooms').doc(); // 랜덤 ID 생성

    ChatRoomModel newRoom = ChatRoomModel(
      roomId: docRef.id,
      participants: [hostId], // 초기엔 호스트만
      lastMessage: initialMessage,
      lastMessageTime: DateTime.now(),
      unreadCount: {hostId: 0},
      title: groupTitle,
      type: 'group',
    );

    await docRef.set(newRoom.toFirestore());
    return docRef.id;
  }

  // 2. 메시지 보내기
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    final timestamp = DateTime.now();

    // 메시지 저장
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'text': text,
          'timestamp': Timestamp.fromDate(timestamp),
          'isRead': false,
        });

    // 채팅방 정보 업데이트 (마지막 메시지, 시간, 안 읽은 수)
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);

    // 트랜잭션으로 안 읽은 수 증가 처리
    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) return;

      final data = roomSnapshot.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      Map<String, dynamic> unreadCount = Map<String, dynamic>.from(
        data['unreadCount'] ?? {},
      );

      // 나를 제외한 모든 참가자의 unreadCount + 1
      for (var uid in participants) {
        if (uid != senderId) {
          unreadCount[uid] = (unreadCount[uid] ?? 0) + 1;
        }
      }

      transaction.update(roomRef, {
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'unreadCount': unreadCount,
      });
    });
  }

  // 3. 메시지 목록 스트림
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return MessageModel(
              id: doc.id,
              senderId: data['senderId'],
              text: data['text'],
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              isRead: data['isRead'] ?? false,
            );
          }).toList();
        });
  }

  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        // [삭제] .orderBy('lastMessageTime', descending: true) -> 깜빡임 원인 제거
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatRoomModel.fromFirestore(doc);
          }).toList();
        });
  }

  // 5. 메시지 읽음 처리
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);

    // 내 안 읽은 수(unreadCount)를 0으로 초기화
    await roomRef.update({'unreadCount.$userId': 0});
  }

  // 6. 채팅방 나가기
  Future<void> leaveChatRoom(String roomId, String userId) async {
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final participants = List<String>.from(
        snapshot.data()!['participants'] ?? [],
      );
      participants.remove(userId);

      if (participants.isEmpty) {
        // 남은 사람이 없으면 방 삭제 (선택사항)
        // transaction.delete(roomRef);
        // 메시지 서브컬렉션 삭제는 별도 로직 필요하므로 일단 유지
        transaction.update(roomRef, {'participants': []});
      } else {
        transaction.update(roomRef, {
          'participants': participants,
          'unreadCount.$userId': FieldValue.delete(), // 내 카운트 삭제
        });
      }
    });
  }
}

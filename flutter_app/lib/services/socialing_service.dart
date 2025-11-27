import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';
import '../models/socialing_model.dart';

class SocialingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  // 1. 소셜링 개설하기 (모임 생성 + 채팅방 생성)
  Future<void> createSocialing({
    required String hostId,
    required String title,
    required String content,
    required String location,
    required DateTime dateTime,
    required int maxMembers,
    required List<String> tags,
    String? imageUrl,
  }) async {
    try {
      // (1) 그룹 채팅방 먼저 생성
      final chatRoomId = await _chatService.createGroupChat(
        hostId: hostId,
        groupTitle: title,
        initialMessage: '모임이 개설되었습니다! 👋',
      );

      // (2) 소셜링 문서 생성
      await _firestore.collection('socialings').add({
        'hostId': hostId,
        'title': title,
        'content': content,
        'imageUrl': imageUrl ?? '',
        'location': location,
        'dateTime': Timestamp.fromDate(dateTime),
        'maxMembers': maxMembers,
        'members': [hostId], // 주최자는 자동 참여
        'tags': tags,
        'chatRoomId': chatRoomId, // 생성된 채팅방 ID 연결
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // 2. 소셜링 참여하기
  Future<void> joinSocialing(String socialingId, String userId) async {
    try {
      // 트랜잭션으로 인원수 체크 및 참여 처리
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('socialings').doc(socialingId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception("모임이 존재하지 않습니다.");

        final data = snapshot.data()!;
        final currentMembers = List<String>.from(data['members'] ?? []);
        final maxMembers = data['maxMembers'] as int;
        final chatRoomId = data['chatRoomId'] as String;

        if (currentMembers.contains(userId)) {
          return; // 이미 참여 중이면 무시
        }

        if (currentMembers.length >= maxMembers) {
          throw Exception("모집 인원이 마감되었습니다.");
        }

        // (1) 멤버 명단에 추가
        transaction.update(docRef, {
          'members': FieldValue.arrayUnion([userId]),
        });

        // (2) 채팅방에도 참여 (Transaction 밖에서 호출해도 되지만, 데이터 일관성을 위해 여기서 처리)
        // 단, ChatService가 Transaction을 지원하지 않으므로 직접 업데이트
        final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
        transaction.update(chatRoomRef, {
          'participants': FieldValue.arrayUnion([userId]),
          'unreadCount.$userId': 0,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  // 3. 소셜링 목록 가져오기
  Stream<List<SocialingModel>> getSocialingsStream() {
    return _firestore
        .collection('socialings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialingModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}

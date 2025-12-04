import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';
import '../models/socialing_model.dart';

class SocialingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  // 1. 소셜링 생성 (기존 동일)
  Future<void> createSocialing({
    required String hostId,
    required String title,
    required String content,
    required String location,
    required DateTime dateTime,
    required int maxMembers,
    required List<String> tags,
    required String category,
    String? imageUrl,
  }) async {
    try {
      final chatRoomId = await _chatService.createGroupChat(
        hostId: hostId,
        groupTitle: title,
        initialMessage: '모임이 개설되었습니다! 👋',
      );

      await _firestore.collection('socialings').add({
        'hostId': hostId,
        'title': title,
        'content': content,
        'imageUrl': imageUrl ?? '',
        'location': location,
        'dateTime': Timestamp.fromDate(dateTime),
        'maxMembers': maxMembers,
        'members': [hostId],
        'tags': tags,
        'chatRoomId': chatRoomId,
        'createdAt': FieldValue.serverTimestamp(),
        'category': category,
        // [기본값] 승인제 활성화 (기획서에 따라 기본값을 true로 할지 선택)
        'isApprovalRequired': true,
        'applicants': [],
        'genderRule': 'any',
      });
    } catch (e) {
      rethrow;
    }
  }

  // 2. [수정] 참여 신청 (승인제 로직 적용)
  Future<void> joinSocialing(String socialingId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('socialings').doc(socialingId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception("모임이 존재하지 않습니다.");

        final data = snapshot.data()!;
        final currentMembers = List<String>.from(data['members'] ?? []);
        final applicants = List<String>.from(data['applicants'] ?? []);
        final maxMembers = data['maxMembers'] as int;
        final isApprovalRequired = data['isApprovalRequired'] ?? false;
        final chatRoomId = data['chatRoomId'] as String;

        // 이미 멤버거나 신청 중이면 패스
        if (currentMembers.contains(userId) || applicants.contains(userId))
          return;

        if (currentMembers.length >= maxMembers) {
          throw Exception("모집 인원이 마감되었습니다.");
        }

        if (isApprovalRequired) {
          // [승인제] 신청자 목록(applicants)에 추가
          transaction.update(docRef, {
            'applicants': FieldValue.arrayUnion([userId]),
          });
        } else {
          // [선착순] 즉시 멤버 추가 및 채팅방 초대
          transaction.update(docRef, {
            'members': FieldValue.arrayUnion([userId]),
          });

          final chatRoomRef = _firestore
              .collection('chat_rooms')
              .doc(chatRoomId);
          transaction.update(chatRoomRef, {
            'participants': FieldValue.arrayUnion([userId]),
            'unreadCount.$userId': 0,
          });
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  // 3. [신규] 신청 승인 (호스트 전용)
  Future<void> approveApplicant(String socialingId, String applicantId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('socialings').doc(socialingId);
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data()!;
        final chatRoomId = data['chatRoomId'] as String;

        // 1) 신청 목록에서 제거하고 멤버 목록에 추가
        transaction.update(docRef, {
          'applicants': FieldValue.arrayRemove([applicantId]),
          'members': FieldValue.arrayUnion([applicantId]),
        });

        // 2) 채팅방 초대
        final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
        transaction.update(chatRoomRef, {
          'participants': FieldValue.arrayUnion([applicantId]),
          'unreadCount.$applicantId': 0,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  // 4. [신규] 신청 거절 (호스트 전용)
  Future<void> rejectApplicant(String socialingId, String applicantId) async {
    try {
      await _firestore.collection('socialings').doc(socialingId).update({
        'applicants': FieldValue.arrayRemove([applicantId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // 5. 목록 가져오기 (기존 유지)
  Stream<List<SocialingModel>> getSocialingsStream({String? category}) {
    Query query = _firestore.collection('socialings');
    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }
    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => SocialingModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    });
  }

  Future<void> cancelApplication(String socialingId, String userId) async {
    try {
      await _firestore.collection('socialings').doc(socialingId).update({
        'applicants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }
}

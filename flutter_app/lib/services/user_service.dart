import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 모든 사용자 가져오기 (관심사 기반 필터링)
  Future<List<UserModel>> getAllUsers({
    String? currentUserId,
    List<String>? interestFilter,
    double? minMannerScore,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // 차단되지 않은 사용자만
      query = query.where('isBlocked', isEqualTo: false);

      // 매너 점수 필터
      if (minMannerScore != null) {
        query = query.where('mannerScore', isGreaterThanOrEqualTo: minMannerScore);
      }

      final snapshot = await query.get();
      
      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((user) => user.uid != currentUserId)
          .toList();

      // 관심사 필터링 (메모리에서 처리)
      if (interestFilter != null && interestFilter.isNotEmpty) {
        users = users.where((user) {
          return user.interests.any((interest) => interestFilter.contains(interest));
        }).toList();
      }

      // 매너 점수 순으로 정렬
      users.sort((a, b) => b.mannerScore.compareTo(a.mannerScore));

      return users;
    } catch (e) {
      rethrow;
    }
  }

  // 특정 사용자 가져오기
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 차단
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 신고
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 신고 카운트 증가
      await _firestore.collection('users').doc(reportedUserId).update({
        'reportCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // 매너 점수 업데이트
  Future<void> updateMannerScore(String userId, double scoreChange) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final currentScore = (userDoc.data()?['mannerScore'] as num?)?.toDouble() ?? 50.0;
        final newScore = (currentScore + scoreChange).clamp(0.0, 100.0);
        
        await _firestore.collection('users').doc(userId).update({
          'mannerScore': newScore,
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}

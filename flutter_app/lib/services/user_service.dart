import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // [필수] 거리 계산용
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // [수정] 모든 사용자 가져오기 (거리 필터 및 정렬 포함)
  Future<List<UserModel>> getAllUsers({
    String? currentUserId,
    List<String>? interestFilter,
    double? minMannerScore,
    // [추가] 위치 기반 정렬을 위한 파라미터
    double? currentLat,
    double? currentLng,
    double? maxDistanceKm,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // 1. 차단되지 않은 사용자만
      query = query.where('isBlocked', isEqualTo: false);

      // 2. 매너 점수 필터
      if (minMannerScore != null) {
        query = query.where(
          'mannerScore',
          isGreaterThanOrEqualTo: minMannerScore,
        );
      }

      final snapshot = await query.get();

      // 내 정보 가져오기 (매칭 여부 확인용)
      UserModel? currentUser;
      if (currentUserId != null) {
        final currentUserDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();
        if (currentUserDoc.exists) {
          currentUser = UserModel.fromFirestore(
            currentUserDoc.data()!,
            currentUserId,
          );
        }
      }

      List<UserModel> users = snapshot.docs
          .map(
            (doc) => UserModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where((user) => user.uid != currentUserId) // 나는 제외
          .where(
            (user) => !(currentUser?.matches.contains(user.uid) ?? false),
          ) // 이미 매칭된 사람 제외
          .toList();

      // 3. 관심사 필터 (메모리)
      if (interestFilter != null && interestFilter.isNotEmpty) {
        users = users.where((user) {
          return user.interests.any(
            (interest) => interestFilter.contains(interest),
          );
        }).toList();
      }

      // 4. [추가] 거리 필터 (maxDistanceKm)
      if (currentLat != null && currentLng != null && maxDistanceKm != null) {
        users = users.where((user) {
          if (user.latitude == null || user.longitude == null) return false;
          final distanceInMeters = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            user.latitude!,
            user.longitude!,
          );
          return (distanceInMeters / 1000) <= maxDistanceKm; // km 비교
        }).toList();
      }

      // 5. [수정] 정렬 로직 (나를 좋아함 > 거리순 > 매너순)
      users.sort((a, b) {
        // (1) 나를 좋아한 사람 최우선
        final aLikesMe = currentUser?.receivedLikes.contains(a.uid) ?? false;
        final bLikesMe = currentUser?.receivedLikes.contains(b.uid) ?? false;

        if (aLikesMe && !bLikesMe) return -1; // a가 위로
        if (!aLikesMe && bLikesMe) return 1; // b가 위로

        // (2) 거리순 정렬 (내 위치가 있을 때만)
        if (currentLat != null && currentLng != null) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;

          final distA = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            a.latitude!,
            a.longitude!,
          );
          final distB = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            b.latitude!,
            b.longitude!,
          );
          return distA.compareTo(distB);
        }

        // (3) 그 외엔 매너 점수순
        return b.mannerScore.compareTo(a.mannerScore);
      });

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

  // 사용자 차단 해제
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
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
        final currentScore =
            (userDoc.data()?['mannerScore'] as num?)?.toDouble() ?? 50.0;
        final newScore = (currentScore + scoreChange).clamp(0.0, 100.0);

        await _firestore.collection('users').doc(userId).update({
          'mannerScore': newScore,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // 위치 공유 켜기
  Future<void> updateUserLocation(String userId, double lat, double lng) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': lat,
        'longitude': lng,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isSharingLocation': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // 위치 공유 끄기
  Future<void> stopSharingLocation(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSharingLocation': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // 좋아요 보내기 및 매칭
  Future<bool> likeUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final targetRef = _firestore.collection('users').doc(targetUserId);
      final myRef = _firestore.collection('users').doc(currentUserId);

      return await _firestore.runTransaction((transaction) async {
        final myDoc = await transaction.get(myRef);
        if (!myDoc.exists) throw Exception("내 정보를 찾을 수 없습니다.");

        final myData = UserModel.fromFirestore(myDoc.data()!, currentUserId);

        if (myData.receivedLikes.contains(targetUserId)) {
          // 매칭 성사
          transaction.update(myRef, {
            'matches': FieldValue.arrayUnion([targetUserId]),
            'receivedLikes': FieldValue.arrayRemove([targetUserId]),
          });
          transaction.update(targetRef, {
            'matches': FieldValue.arrayUnion([currentUserId]),
          });
          return true;
        } else {
          // 좋아요 보냄
          transaction.update(targetRef, {
            'receivedLikes': FieldValue.arrayUnion([currentUserId]),
          });
          return false;
        }
      });
    } catch (e) {
      rethrow;
    }
  }
}

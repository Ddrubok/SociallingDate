import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import 'dart:math'; // [추가] 랜덤 추출용

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. [수정] 모든 사용자 가져오기 (필터 기능 대폭 강화)
  Future<List<UserModel>> getAllUsers({
    String? currentUserId,
    List<String>? interestFilter,
    double? minMannerScore,
    // 위치
    double? currentLat,
    double? currentLng,
    double? maxDistanceKm,
    // [v2.0 추가] 상세 필터
    String? gender, // 성별 필터 (오늘의 추천용)
    String? religion, // 종교 필터
    List<String>? lifestyle, // 라이프스타일 필터
  }) async {
    try {
      Query query = _firestore.collection('users');
      query = query.where('isBlocked', isEqualTo: false);

      if (minMannerScore != null) {
        query = query.where(
          'mannerScore',
          isGreaterThanOrEqualTo: minMannerScore,
        );
      }

      // [추가] 성별 필터 (DB단에서 1차 필터링)
      if (gender != null) {
        query = query.where('gender', isEqualTo: gender);
      }

      // [추가] 종교 필터
      if (religion != null) {
        query = query.where('religion', isEqualTo: religion);
      }

      final snapshot = await query.get();

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
          .where((user) => user.uid != currentUserId)
          .where((user) => !(currentUser?.matches.contains(user.uid) ?? false))
          .toList();

      // 1. 관심사 필터
      if (interestFilter != null && interestFilter.isNotEmpty) {
        users = users.where((user) {
          return user.interests.any(
            (interest) => interestFilter.contains(interest),
          );
        }).toList();
      }

      // 2. [추가] 라이프스타일 필터 (하나라도 겹치면 추천)
      if (lifestyle != null && lifestyle.isNotEmpty) {
        users = users.where((user) {
          return user.lifestyle.any((style) => lifestyle.contains(style));
        }).toList();
      }

      // 3. 거리 필터
      if (currentLat != null && currentLng != null && maxDistanceKm != null) {
        users = users.where((user) {
          if (user.latitude == null || user.longitude == null) return false;
          final distanceInMeters = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            user.latitude!,
            user.longitude!,
          );
          return (distanceInMeters / 1000) <= maxDistanceKm;
        }).toList();
      }

      // 4. 정렬 로직 (기존 유지)
      users.sort((a, b) {
        final aLikesMe = currentUser?.receivedLikes.contains(a.uid) ?? false;
        final bLikesMe = currentUser?.receivedLikes.contains(b.uid) ?? false;

        if (aLikesMe && !bLikesMe) return -1;
        if (!aLikesMe && bLikesMe) return 1;

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
        return b.mannerScore.compareTo(a.mannerScore);
      });

      return users;
    } catch (e) {
      rethrow;
    }
  }

  // 2. [신규] 오늘의 추천 (랜덤 5명)
  Future<List<UserModel>> getDailyRecommendations(
    String currentUserId,
    String myGender,
  ) async {
    try {
      // 이성 추천 (남 -> 여, 여 -> 남)
      String targetGender = (myGender == 'male') ? 'female' : 'male';

      // 모든 이성 유저 가져오기 (실무에선 limit와 커서 페이징 사용 권장)
      List<UserModel> candidates = await getAllUsers(
        currentUserId: currentUserId,
        gender: targetGender,
        minMannerScore: 50.0, // 기본 매너 점수 이상
      );

      // 랜덤 셔플 후 상위 5명 추출
      candidates.shuffle(Random());
      return candidates.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  // 3. 기존 메서드들 유지 (getUser, blockUser, unblockUser, reportUser, updateMannerScore, updateUserLocation, stopSharingLocation, likeUser)
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null)
      return UserModel.fromFirestore(doc.data()!, doc.id);
    return null;
  }

  Future<void> blockUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([targetUserId]),
    });
  }

  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([targetUserId]),
    });
  }

  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
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
  }

  Future<void> updateMannerScore(String userId, double scoreChange) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final currentScore =
          (userDoc.data()?['mannerScore'] as num?)?.toDouble() ?? 50.0;
      final newScore = (currentScore + scoreChange).clamp(0.0, 100.0);
      await _firestore.collection('users').doc(userId).update({
        'mannerScore': newScore,
      });
    }
  }

  Future<void> updateUserLocation(String userId, double lat, double lng) async {
    await _firestore.collection('users').doc(userId).update({
      'latitude': lat,
      'longitude': lng,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
      'isSharingLocation': true,
    });
  }

  Future<void> stopSharingLocation(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isSharingLocation': false,
    });
  }

  Future<bool> likeUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final targetRef = _firestore.collection('users').doc(targetUserId);
    final myRef = _firestore.collection('users').doc(currentUserId);
    return await _firestore.runTransaction((transaction) async {
      final myDoc = await transaction.get(myRef);
      if (!myDoc.exists) throw Exception("내 정보를 찾을 수 없습니다.");
      final myData = UserModel.fromFirestore(myDoc.data()!, currentUserId);
      if (myData.receivedLikes.contains(targetUserId)) {
        transaction.update(myRef, {
          'matches': FieldValue.arrayUnion([targetUserId]),
          'receivedLikes': FieldValue.arrayRemove([targetUserId]),
        });
        transaction.update(targetRef, {
          'matches': FieldValue.arrayUnion([currentUserId]),
        });
        return true;
      } else {
        transaction.update(targetRef, {
          'receivedLikes': FieldValue.arrayUnion([currentUserId]),
        });
        return false;
      }
    });
  }
}

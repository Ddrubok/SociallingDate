import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 모든 사용자 가져오기
  Future<List<UserModel>> getAllUsers({
    String? currentUserId,
    List<String>? interestFilter,
    double? minMannerScore,
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

      final snapshot = await query.get();

      // 내 정보 가져오기 (나를 좋아한 사람 목록 확인용)
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
          ) // 이미 매칭된 사람 제외 (선택사항)
          .toList();

      if (interestFilter != null && interestFilter.isNotEmpty) {
        users = users.where((user) {
          return user.interests.any(
            (interest) => interestFilter.contains(interest),
          );
        }).toList();
      }

      // [핵심] 정렬 로직 변경
      // 1순위: 나를 좋아요 한 사람 (receivedLikes에 내 ID가 있는 사람 X -> 내가 그 사람의 receivedLikes에 있는 게 아니라, 그 사람이 내 receivedLikes에 있는 경우)
      // *수정*: UserModel에는 '내가 받은 좋아요(receivedLikes)'가 저장되어 있음.
      // 따라서, currentUser.receivedLikes 에 포함된 유저를 맨 위로 올려야 함.

      if (currentUser != null) {
        users.sort((a, b) {
          final aLikesMe = currentUser!.receivedLikes.contains(a.uid);
          final bLikesMe = currentUser.receivedLikes.contains(b.uid);

          if (aLikesMe && !bLikesMe) return -1; // a가 위로
          if (!aLikesMe && bLikesMe) return 1; // b가 위로

          // 2순위: 매너 점수
          return b.mannerScore.compareTo(a.mannerScore);
        });
      } else {
        users.sort((a, b) => b.mannerScore.compareTo(a.mannerScore));
      }

      return users;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> likeUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final targetRef = _firestore.collection('users').doc(targetUserId);
      final myRef = _firestore.collection('users').doc(currentUserId);

      return await _firestore.runTransaction((transaction) async {
        final myDoc = await transaction.get(myRef);
        // final targetDoc = await transaction.get(targetRef); // 필요 시 사용

        if (!myDoc.exists) throw Exception("내 정보를 찾을 수 없습니다.");

        final myData = UserModel.fromFirestore(myDoc.data()!, currentUserId);

        // 1. 상대방이 이미 나를 좋아했는지 확인 (매칭 성사 여부)
        if (myData.receivedLikes.contains(targetUserId)) {
          // [매칭 성공!]
          // 서로의 matches 목록에 추가하고, receivedLikes에서는 제거(선택)
          transaction.update(myRef, {
            'matches': FieldValue.arrayUnion([targetUserId]),
            'receivedLikes': FieldValue.arrayRemove([targetUserId]), // 목록 정리
          });
          transaction.update(targetRef, {
            'matches': FieldValue.arrayUnion([currentUserId]),
            // 상대방이 보낸 좋아요는 이미 내 receivedLikes에 있었으니, 상대방 입장에선 변동 없음
            // (만약 상대방도 '보낸 좋아요'를 관리한다면 거기서 지워야 함)
          });
          return true; // 매칭 성사됨 (true 반환)
        } else {
          // [짝사랑] 그냥 좋아요만 보냄
          // 상대방의 receivedLikes에 내 ID 추가
          transaction.update(targetRef, {
            'receivedLikes': FieldValue.arrayUnion([currentUserId]),
          });
          return false; // 아직 매칭 안 됨 (false 반환)
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  // 2. 특정 사용자 가져오기
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

  // 3. 사용자 차단
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // 4. 사용자 차단 해제
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // 5. 사용자 신고
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

  // 6. 매너 점수 업데이트
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

  // 7. [복구] 위치 공유 켜기
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

  // 8. [복구] 위치 공유 끄기
  Future<void> stopSharingLocation(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSharingLocation': false,
      });
    } catch (e) {
      rethrow;
    }
  }
}

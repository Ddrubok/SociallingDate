import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String profileImageUrl;
  final String authStatus;
  final double mannerScore;
  final List<String> interests;
  final String bio;
  final int age;
  final String gender;
  final String location;
  final DateTime? createdAt;
  final bool isBlocked;
  final List<String> blockedUsers;
  final int reportCount;

  // 위치 및 매칭 관련 필드 (기존)
  final double? latitude;
  final double? longitude;
  final bool isSharingLocation;
  final List<String> receivedLikes;
  final List<String> matches;

  // [v2.0 추가] 상세 프로필 및 친구 요청 시스템
  final String religion; // 종교 (예: 기독교, 무교)
  final List<String> lifestyle; // 라이프스타일 (예: 아침형, 비흡연)

  // 친구 요청 상태 관리 (Map 구조: {targetUserId, status, timestamp})
  final List<Map<String, dynamic>> friendRequestsSent;
  final List<Map<String, dynamic>> friendRequestsReceived;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.profileImageUrl,
    required this.authStatus,
    required this.mannerScore,
    required this.interests,
    required this.bio,
    required this.age,
    required this.gender,
    required this.location,
    this.createdAt,
    this.isBlocked = false,
    this.blockedUsers = const [],
    this.reportCount = 0,
    this.latitude,
    this.longitude,
    this.isSharingLocation = false,
    this.receivedLikes = const [],
    this.matches = const [],
    // [추가] 초기화 (기본값 설정)
    this.religion = '',
    this.lifestyle = const [],
    this.friendRequestsSent = const [],
    this.friendRequestsReceived = const [],
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      authStatus: data['authStatus'] as String? ?? 'pending',
      mannerScore: (data['mannerScore'] as num?)?.toDouble() ?? 50.0,
      interests: List<String>.from(data['interests'] as List? ?? []),
      bio: data['bio'] as String? ?? '',
      age: data['age'] as int? ?? 20,
      gender: data['gender'] as String? ?? '',
      location: data['location'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isBlocked: data['isBlocked'] as bool? ?? false,
      blockedUsers: List<String>.from(data['blockedUsers'] as List? ?? []),
      reportCount: data['reportCount'] as int? ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isSharingLocation: data['isSharingLocation'] as bool? ?? false,
      receivedLikes: List<String>.from(data['receivedLikes'] as List? ?? []),
      matches: List<String>.from(data['matches'] as List? ?? []),
      // [추가] Firestore 데이터 매핑
      religion: data['religion'] as String? ?? '',
      lifestyle: List<String>.from(data['lifestyle'] as List? ?? []),
      friendRequestsSent: List<Map<String, dynamic>>.from(
        data['friendRequestsSent'] as List? ?? [],
      ),
      friendRequestsReceived: List<Map<String, dynamic>>.from(
        data['friendRequestsReceived'] as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'authStatus': authStatus,
      'mannerScore': mannerScore,
      'interests': interests,
      'bio': bio,
      'age': age,
      'gender': gender,
      'location': location,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isBlocked': isBlocked,
      'blockedUsers': blockedUsers,
      'reportCount': reportCount,
      'latitude': latitude,
      'longitude': longitude,
      'isSharingLocation': isSharingLocation,
      'receivedLikes': receivedLikes,
      'matches': matches,
      // [추가] Firestore 저장
      'religion': religion,
      'lifestyle': lifestyle,
      'friendRequestsSent': friendRequestsSent,
      'friendRequestsReceived': friendRequestsReceived,
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? profileImageUrl,
    String? authStatus,
    double? mannerScore,
    List<String>? interests,
    String? bio,
    int? age,
    String? gender,
    String? location,
    DateTime? createdAt,
    bool? isBlocked,
    List<String>? blockedUsers,
    int? reportCount,
    double? latitude,
    double? longitude,
    bool? isSharingLocation,
    List<String>? receivedLikes,
    List<String>? matches,
    // [추가]
    String? religion,
    List<String>? lifestyle,
    List<Map<String, dynamic>>? friendRequestsSent,
    List<Map<String, dynamic>>? friendRequestsReceived,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      authStatus: authStatus ?? this.authStatus,
      mannerScore: mannerScore ?? this.mannerScore,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      reportCount: reportCount ?? this.reportCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
      receivedLikes: receivedLikes ?? this.receivedLikes,
      matches: matches ?? this.matches,
      religion: religion ?? this.religion,
      lifestyle: lifestyle ?? this.lifestyle,
      friendRequestsSent: friendRequestsSent ?? this.friendRequestsSent,
      friendRequestsReceived:
          friendRequestsReceived ?? this.friendRequestsReceived,
    );
  }
}

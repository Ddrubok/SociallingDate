import 'package:cloud_firestore/cloud_firestore.dart';

class SocialingModel {
  final String sid;
  final String hostId;
  final String title;
  final String content;
  final String imageUrl;
  final String location;
  final DateTime dateTime;
  final int maxMembers;
  final List<String> members;
  final List<String> tags;
  final String chatRoomId;
  final DateTime createdAt;
  final String category;

  // [v2.0 추가] 승인제 및 규칙 관련 필드
  final List<String> applicants; // 참여 신청 대기자 UID 목록
  final String genderRule; // 성별 규칙 ('any', 'male_only', 'female_only')
  final bool isApprovalRequired; // 승인제 여부 (true: 승인 필요, false: 선착순)

  static const List<String> categories = [
    'small',
    'large',
    'oneday',
    'weekend',
  ];

  SocialingModel({
    required this.sid,
    required this.hostId,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.location,
    required this.dateTime,
    required this.maxMembers,
    required this.members,
    required this.tags,
    required this.chatRoomId,
    required this.createdAt,
    required this.category,
    // [추가] 초기화
    this.applicants = const [],
    this.genderRule = 'any',
    this.isApprovalRequired = false,
  });

  factory SocialingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SocialingModel(
      sid: id,
      hostId: data['hostId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      maxMembers: data['maxMembers'] ?? 4,
      members: List<String>.from(data['members'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      chatRoomId: data['chatRoomId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] ?? categories.first,
      // [추가] Firestore 데이터 매핑
      applicants: List<String>.from(data['applicants'] ?? []),
      genderRule: data['genderRule'] ?? 'any',
      isApprovalRequired: data['isApprovalRequired'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'maxMembers': maxMembers,
      'members': members,
      'tags': tags,
      'chatRoomId': chatRoomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      // [추가] Firestore 저장
      'applicants': applicants,
      'genderRule': genderRule,
      'isApprovalRequired': isApprovalRequired,
    };
  }
}

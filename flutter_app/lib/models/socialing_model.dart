import 'package:cloud_firestore/cloud_firestore.dart';

class SocialingModel {
  final String sid; // 소셜링 ID
  final String hostId; // 주최자 ID
  final String title; // 모임 제목
  final String content; // 모임 내용
  final String imageUrl; // 커버 이미지
  final String location; // 장소
  final DateTime dateTime; // 일시
  final int maxMembers; // 최대 인원
  final List<String> members; // 참여자 ID 리스트
  final List<String> tags; // 태그 (예: #맛집, #독서)
  final String chatRoomId; // 연결된 그룹 채팅방 ID
  final DateTime createdAt;

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
    };
  }
}

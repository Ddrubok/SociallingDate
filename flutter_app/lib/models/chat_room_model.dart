import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final String type; // 'private' or 'group'
  final String title;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;

  ChatRoomModel({
    required this.roomId,
    required this.type,
    required this.title,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatRoomModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatRoomModel(
      roomId: id,
      type: data['type'] as String? ?? 'private',
      title: data['title'] as String? ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] ?? {},
      ),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  String getOtherParticipantName(String currentUserId) {
    if (type == 'group') return title;
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantNames[otherUserId] ?? '알 수 없음';
  }

  String getOtherParticipantId(String currentUserId) {
    if (type == 'group') return '';
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCountForUser(String? userId) {
    if (userId == null) return 0;
    return unreadCount[userId] ?? 0;
  }
}

// [중요] MessageModel 클래스 추가 (이게 없어서 에러가 났습니다!)
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
    );
  }
}

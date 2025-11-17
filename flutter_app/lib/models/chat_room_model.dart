import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final Map<String, int> unreadCount;

  ChatRoomModel({
    required this.roomId,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageAt,
    this.createdAt,
    this.unreadCount = const {},
  });

  factory ChatRoomModel.fromFirestore(Map<String, dynamic> data, String roomId) {
    return ChatRoomModel(
      roomId: roomId,
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] as Map? ?? {}),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(data['unreadCount'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    };
  }

  String getOtherParticipantName(String currentUserId) {
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantNames[otherUserId] ?? '알 수 없음';
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }
}

class MessageModel {
  final String? messageId;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  final bool isModerated;
  final String status;
  final bool isRead;

  MessageModel({
    this.messageId,
    required this.senderId,
    required this.text,
    this.timestamp,
    this.isModerated = false,
    this.status = 'safe',
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data, String? messageId) {
    return MessageModel(
      messageId: messageId,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isModerated: data['isModerated'] as bool? ?? false,
      status: data['status'] as String? ?? 'safe',
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'isModerated': isModerated,
      'status': status,
      'isRead': isRead,
    };
  }
}

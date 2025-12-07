import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final List<String> participants;
  final String? lastMessage;
  // [추가] 마지막 메시지 시간 (이게 없어서 에러가 났습니다!)
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final String? title;
  final String type; // 'individual' (1:1) or 'group' (그룹)

  ChatRoomModel({
    required this.roomId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.title,
    this.type = 'individual',
  });

  // Firestore 데이터 -> 모델 변환
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatRoomModel(
      roomId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      // [수정] Timestamp를 DateTime으로 변환
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      // 맵핑 처리 (데이터가 int가 아닐 수도 있는 경우 대비)
      unreadCount:
          (data['unreadCount'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      title: data['title'],
      type: data['type'] ?? 'individual',
    );
  }

  // 모델 -> Firestore 데이터 변환
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      // [수정] DateTime을 Timestamp로 변환
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'title': title,
      'type': type,
    };
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

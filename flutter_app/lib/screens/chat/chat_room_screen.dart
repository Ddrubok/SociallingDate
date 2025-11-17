import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_room_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;
  final String otherUserId;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final currentUserId = context.read<AuthProvider>().currentUserId;
    if (currentUserId != null) {
      await _chatService.markMessagesAsRead(widget.roomId, currentUserId);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = context.read<AuthProvider>().currentUserId;
    if (currentUserId == null) return;

    try {
      await _chatService.sendMessage(
        roomId: widget.roomId,
        senderId: currentUserId,
        text: text,
      );
      _messageController.clear();
    } catch (e) {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      '메시지를 보내보세요!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            CircleAvatar(
                              radius: 16,
                              child: Text(widget.otherUserName[0]),
                            ),
                          if (!isMe) const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.timestamp != null
                                        ? timeago.format(message.timestamp!, locale: 'ko')
                                        : '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 8),
                          if (isMe)
                            CircleAvatar(
                              radius: 16,
                              child: Text(
                                  context.read<AuthProvider>().currentUserProfile?.displayName[0] ??
                                      'U'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

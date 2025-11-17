import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_room_model.dart';
import 'chat_room_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ko', timeago.KoMessages());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('채팅')),
      body: currentUserId == null
          ? const Center(
              // 사용자가 로그인하지 않았거나 ID를 가져올 수 없는 경우
              child: Text('로그인이 필요합니다.'),
            )
          : StreamBuilder<List<ChatRoomModel>>(
              stream: _chatService.getChatRoomsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }

                final chatRooms = snapshot.data ?? [];

                if (chatRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '아직 채팅이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = chatRooms[index];
                    final unreadCount = room.getUnreadCountForUser(
                      currentUserId,
                    );

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          room.getOtherParticipantName(currentUserId)[0],
                        ),
                      ),
                      title: Text(
                        room.getOtherParticipantName(currentUserId),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        room.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadCount > 0
                              ? Colors.black
                              : Colors.grey[600],
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            room.lastMessageAt != null
                                ? timeago.format(
                                    room.lastMessageAt!,
                                    locale: 'ko',
                                  )
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              roomId: room.roomId,
                              otherUserName: room.getOtherParticipantName(
                                currentUserId,
                              ),
                              otherUserId: room.getOtherParticipantId(
                                currentUserId,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

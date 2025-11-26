import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
// [중요] 번역 파일 임포트
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_room_model.dart';
import 'chat_room_screen.dart';

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
    // [번역] 변수 선언
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatListTitle)), // "채팅"
      body: currentUserId == null
          ? Center(
              // (로그인 상태가 아니면 접근 불가하겠지만 예외 처리)
              child: Text(l10n.error),
            )
          : StreamBuilder<List<ChatRoomModel>>(
              stream: _chatService.getChatRoomsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('${l10n.error}: ${snapshot.error}'),
                  );
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
                          l10n.noConversations, // "아직 대화가 없습니다"
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
                    final otherUserName = room.getOtherParticipantName(
                      currentUserId,
                    );

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          otherUserName.isNotEmpty ? otherUserName[0] : '?',
                        ),
                      ),
                      title: Text(
                        otherUserName,
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
                                    locale: Localizations.localeOf(
                                      context,
                                    ).languageCode, // 현재 언어에 맞게 시간 표시
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
                              otherUserName: otherUserName,
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

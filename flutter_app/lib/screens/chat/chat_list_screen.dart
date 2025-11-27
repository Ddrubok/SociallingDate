import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
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
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().currentUserId;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatListTitle)),
      body: currentUserId == null
          ? Center(child: Text(l10n.error))
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
                          l10n.noConversations,
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

                    // [수정] 채팅방 타입에 따라 정보 결정
                    final isGroup = room.type == 'group';
                    final String displayTitle;
                    final String targetUserId; // 1:1일 때만 사용

                    if (isGroup) {
                      displayTitle = room.title; // 그룹명
                      targetUserId = ''; // 그룹은 상대 ID 없음
                    } else {
                      displayTitle = room.getOtherParticipantName(
                        currentUserId,
                      ); // 상대 이름
                      targetUserId = room.getOtherParticipantId(currentUserId);
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isGroup
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: isGroup
                            ? const Icon(
                                Icons.groups,
                                color: Colors.black54,
                              ) // [그룹 아이콘]
                            : Text(
                                displayTitle.isNotEmpty ? displayTitle[0] : '?',
                              ), // [이니셜]
                      ),
                      title: Text(
                        displayTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                                    locale: localeCode,
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
                        // [수정] 채팅방 입장 시 올바른 인자 전달
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              roomId: room.roomId,
                              otherUserName: displayTitle, // 그룹명 또는 상대 이름
                              otherUserId: targetUserId, // 그룹이면 빈 문자열('')
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

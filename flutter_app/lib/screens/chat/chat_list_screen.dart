import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/chat_room_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  List<UserModel> _allMatchedFriends = [];
  bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _loadAllMatchedFriends();
  }

  Future<void> _loadAllMatchedFriends() async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    try {
      final friends = await _userService.getMatchedUsers(currentUser.uid);
      if (mounted) {
        setState(() {
          _allMatchedFriends = friends;
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  Future<void> _onFriendTap(UserModel friend) async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    final roomId = await _chatService.createOrGetChatRoom(
      currentUserId: currentUser.uid,
      otherUserId: friend.uid,
      currentUserName: currentUser.displayName,
      otherUserName: friend.displayName,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          roomId: roomId,
          otherUserName: friend.displayName,
          otherUserId: friend.uid,
        ),
      ),
    );
  }

  String _formatDate(DateTime date, String localeCode) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat.jm(localeCode).format(date);
    } else {
      return DateFormat.MMMd(localeCode).format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final currentUserId = context.watch<AuthProvider>().currentUserId;

    if (currentUserId == null)
      return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabChat)),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _chatService.getChatRoomsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. 데이터 가져오기 (정렬 안 된 상태)
          var chatRooms = snapshot.data ?? [];

          // 2. [핵심] 앱 내부에서 최신순 정렬 (Null 안전 처리 포함)
          chatRooms.sort((a, b) {
            if (a.lastMessageTime == null) return -1; // 시간 없으면 뒤로
            if (b.lastMessageTime == null) return 1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!); // 내림차순
          });

          // 3. 대화 중인 상대방 ID 추출 (필터링용)
          final Set<String> talkingUserIds = {};
          for (var room in chatRooms) {
            if (room.type == 'individual') {
              final otherId = room.participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              // 메시지가 있거나 방금 만든 방이면 '대화 중'으로 간주
              if (otherId.isNotEmpty &&
                  (room.lastMessage != null && room.lastMessage!.isNotEmpty)) {
                talkingUserIds.add(otherId);
              }
            }
          }

          // 4. 새로운 매칭 목록 (대화 안 한 친구만)
          final newMatches = _allMatchedFriends.where((friend) {
            return !talkingUserIds.contains(friend.uid);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 상단: 새로운 매칭 ---
              if (newMatches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.newMatches,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: newMatches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final friend = newMatches[index];
                      return GestureDetector(
                        onTap: () => _onFriendTap(friend),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    friend.profileImageUrl,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 60,
                              child: Text(
                                friend.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 1, height: 1),
              ],

              // --- 하단: 채팅방 목록 ---
              Expanded(
                child: chatRooms.isEmpty && newMatches.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noConversations,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: chatRooms.length,
                        itemBuilder: (context, index) {
                          final room = chatRooms[index];

                          // 빈 방은 숨김 (상단에 있을테니)
                          if ((room.lastMessage == null ||
                                  room.lastMessage!.isEmpty) &&
                              room.type == 'individual') {
                            return const SizedBox();
                          }

                          String otherUserId = '';
                          String roomTitle = room.title ?? 'Chat';

                          if (room.type == 'individual') {
                            otherUserId = room.participants.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => '',
                            );
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[200],
                              child: room.type == 'group'
                                  ? const Icon(Icons.groups, color: Colors.grey)
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                            ),
                            title: Text(
                              roomTitle,
                              style: TextStyle(
                                fontWeight:
                                    (room.unreadCount[currentUserId] ?? 0) > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              room.lastMessage ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  room.lastMessageTime != null
                                      ? _formatDate(
                                          room.lastMessageTime!,
                                          localeCode,
                                        )
                                      : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if ((room.unreadCount[currentUserId] ?? 0) >
                                    0) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${room.unreadCount[currentUserId]}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
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
                                    otherUserName: roomTitle,
                                    otherUserId: otherUserId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

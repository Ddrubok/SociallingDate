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

  // 캐싱된 친구 목록 (빠른 로딩용)
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

  // 상단 친구 아이콘 클릭 -> 채팅방 입장
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

  // [핵심] 리스트 타일(채팅방 한 줄)을 그려주는 함수
  Widget _buildChatTile(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
    String name,
    String? imageUrl,
    String otherUserId,
    String localeCode,
  ) {
    final unreadCount = room.unreadCount[currentUserId] ?? 0;

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null
            ? (room.type == 'group'
                  ? const Icon(Icons.groups, color: Colors.grey)
                  : const Icon(Icons.person, color: Colors.grey))
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        room.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unreadCount > 0 ? Colors.black87 : Colors.grey,
          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            room.lastMessageTime != null
                ? _formatDate(room.lastMessageTime!, localeCode)
                : '',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
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
              otherUserName: name,
              otherUserId: otherUserId,
            ),
          ),
        );
      },
    );
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

          var chatRooms = snapshot.data ?? [];

          // 최신순 정렬
          chatRooms.sort((a, b) {
            if (a.lastMessageTime == null) return -1;
            if (b.lastMessageTime == null) return 1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          // 대화 중인 유저 ID 추출
          final Set<String> talkingUserIds = {};
          for (var room in chatRooms) {
            if (room.type == 'individual') {
              final otherId = room.participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              if (otherId.isNotEmpty &&
                  (room.lastMessage != null && room.lastMessage!.isNotEmpty)) {
                talkingUserIds.add(otherId);
              }
            }
          }

          // 새로운 매칭 목록 필터링
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

                          // 빈 방 숨김 (상단에 표시되므로)
                          if ((room.lastMessage == null ||
                                  room.lastMessage!.isEmpty) &&
                              room.type == 'individual') {
                            return const SizedBox();
                          }

                          // 1. 그룹 채팅인 경우
                          if (room.type == 'group') {
                            return _buildChatTile(
                              context,
                              room,
                              currentUserId,
                              room.title ?? 'Group Chat',
                              null, // 그룹 이미지가 있다면 여기에
                              '',
                              localeCode,
                            );
                          }
                          // 2. 1:1 채팅인 경우 -> 상대방 이름 찾아야 함
                          else {
                            final otherUserId = room.participants.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => '',
                            );

                            // (A) 캐시된 친구 목록에서 먼저 찾기 (빠름)
                            UserModel? targetUser;
                            try {
                              targetUser = _allMatchedFriends.firstWhere(
                                (u) => u.uid == otherUserId,
                              );
                            } catch (_) {
                              // 캐시에 없음
                            }

                            if (targetUser != null) {
                              return _buildChatTile(
                                context,
                                room,
                                currentUserId,
                                targetUser.displayName,
                                targetUser.profileImageUrl,
                                otherUserId,
                                localeCode,
                              );
                            }
                            // (B) 캐시에 없으면 DB에서 불러오기 (FutureBuilder 사용)
                            else {
                              return FutureBuilder<UserModel?>(
                                future: _userService.getUser(otherUserId),
                                builder: (context, snapshot) {
                                  final user = snapshot.data;
                                  final name =
                                      user?.displayName ??
                                      '알 수 없음'; // 로딩 중이거나 없으면
                                  final image = user?.profileImageUrl;

                                  return _buildChatTile(
                                    context,
                                    room,
                                    currentUserId,
                                    name,
                                    image,
                                    otherUserId,
                                    localeCode,
                                  );
                                },
                              );
                            }
                          }
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

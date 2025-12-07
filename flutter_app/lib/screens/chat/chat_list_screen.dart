import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 매칭된 친구 목록
  List<UserModel> _matchedFriends = [];
  bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _loadMatchedFriends();
  }

  // 매칭된 친구 불러오기
  Future<void> _loadMatchedFriends() async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    try {
      final friends = await _userService.getMatchedUsers(currentUser.uid);
      if (mounted) {
        setState(() {
          _matchedFriends = friends;
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  // 친구 아이콘 클릭 시 -> 채팅방으로 이동 (없으면 생성)
  Future<void> _onFriendTap(UserModel friend) async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    try {
      // 채팅방 생성 or 가져오기
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
    } catch (e) {
      // error handling
    }
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
      appBar: AppBar(title: Text(l10n.tabChat)), // "채팅"
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------
          // 1. 상단: 새로운 매칭 (가로 스크롤)
          // ---------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.newMatches, // "새로운 매칭"
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),

          SizedBox(
            height: 100, // 높이 고정
            child: _isLoadingMatches
                ? const Center(child: CircularProgressIndicator())
                : _matchedFriends.isEmpty
                ? Center(
                    child: Text(
                      l10n.noMatchesYet, // "아직 매칭된 친구가 없습니다"
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _matchedFriends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final friend = _matchedFriends[index];
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
                                  backgroundColor: Colors.grey[200],
                                ),
                                // 온라인 상태 표시 (선택사항 - 지금은 장식용)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(thickness: 1, height: 1),

          // ---------------------------------------------
          // 2. 하단: 채팅방 목록 (세로 리스트)
          // ---------------------------------------------
          Expanded(
            child: StreamBuilder<List<ChatRoomModel>>(
              stream: _chatService.getChatRoomsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noConversations,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = chatRooms[index];

                    // 상대방 정보 찾기 (1:1인 경우)
                    String otherUserId = '';
                    String roomTitle = room.title ?? 'Chat';

                    if (room.type == 'individual') {
                      otherUserId = room.participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );
                      // 방 제목이 없으면 상대 이름 표시 로직 필요하지만,
                      // 보통 ChatRoomModel 생성 시 title을 미리 세팅하거나 여기서 fetch 해야 함.
                      // 간소화를 위해 우선 저장된 title 사용
                    }

                    final unreadCount = room.unreadCount[currentUserId] ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        child: room.type == 'group'
                            ? const Icon(Icons.groups, color: Colors.grey)
                            : const Icon(Icons.person, color: Colors.grey),
                      ),
                      title: Text(
                        roomTitle,
                        style: TextStyle(
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        room.lastMessage ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadCount > 0 ? Colors.black87 : Colors.grey,
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
                            room.lastMessageTime != null
                                ? _formatDate(room.lastMessageTime!, localeCode)
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
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
                              otherUserName: roomTitle,
                              otherUserId: otherUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

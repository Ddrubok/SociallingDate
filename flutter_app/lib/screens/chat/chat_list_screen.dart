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

  // 전체 매칭된 친구 목록 (DB에서 가져온 원본)
  List<UserModel> _allMatchedFriends = [];
  bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _loadAllMatchedFriends();
  }

  // 1. 내 모든 친구(매칭) 정보 가져오기
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

  // 친구 아이콘 클릭 -> 채팅방 입장
  Future<void> _onFriendTap(UserModel friend) async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    // 방을 생성하거나 가져옴
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

    // [핵심 변경] 전체 화면을 StreamBuilder로 감쌉니다.
    // 이유: 채팅방 목록(하단)의 데이터가 변하면, 상단 목록(새로운 매칭)도 실시간으로 갱신되어야 하기 때문입니다.
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabChat)),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _chatService.getChatRoomsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. 현재 대화 중인 채팅방 목록 (하단용)
          // (메시지가 하나라도 있는 방만 보여주거나, 생성된 모든 방 보여주기)
          final chatRooms = snapshot.data ?? [];

          // 2. 대화 중인 친구들의 ID 목록 추출 (1:1 채팅인 경우)
          final Set<String> talkingUserIds = {};
          for (var room in chatRooms) {
            if (room.type == 'individual') {
              // 나를 제외한 상대방 ID 찾기
              final otherId = room.participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              // [조건] 메시지가 하나라도 오고 갔을 때만 '대화 중'으로 칠 것인지 결정
              // 여기서는 "방이 만들어져 있고 lastMessage가 비어있지 않으면" 대화 중으로 간주
              if (otherId.isNotEmpty &&
                  (room.lastMessage != null && room.lastMessage!.isNotEmpty)) {
                talkingUserIds.add(otherId);
              }
            }
          }

          // 3. 새로운 매칭 목록 (상단용)
          // 전체 친구 중 "아직 대화 안 한 사람(talkingUserIds에 없는 사람)"만 필터링
          final newMatches = _allMatchedFriends.where((friend) {
            return !talkingUserIds.contains(friend.uid);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------
              // 상단: 새로운 매칭 (대화 안 한 친구들)
              // ---------------------------------------------
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
                                      color: Colors.redAccent, // 새 매칭 강조 (빨간 점)
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

              // ---------------------------------------------
              // 하단: 채팅방 목록 (대화 중인 방)
              // ---------------------------------------------
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

                          // [중요] 메시지가 없는 빈 방은 목록에서 숨길 것인가?
                          // -> "상단에 새 매칭으로 표시 중"이라면 하단에선 숨기는 게 깔끔함.
                          // -> 여기서는 lastMessage가 있는 방만 보여주도록 필터링 가능하지만,
                          //    ListTile에서 처리.
                          if ((room.lastMessage == null ||
                                  room.lastMessage!.isEmpty) &&
                              room.type == 'individual') {
                            return const SizedBox(); // 빈 방은 안 보여줌 (상단에 있을 테니까)
                          }

                          // 상대방 정보 찾기
                          String otherUserId = '';
                          String roomTitle = room.title ?? 'Chat';

                          if (room.type == 'individual') {
                            otherUserId = room.participants.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => '',
                            );
                            // 1:1 채팅방 이름은 상대방 이름이 와야 함 (여기선 간단히 기존 title 사용하거나 로직 추가)
                            // 실무에선 여기서 getUser를 또 하거나 캐싱된 정보를 씀.
                            // 일단 room.title 사용 (createOrGetChatRoom에서 저장해둠)
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

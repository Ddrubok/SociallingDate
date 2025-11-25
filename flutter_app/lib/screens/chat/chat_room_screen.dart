import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/chat_room_model.dart';
import '../../models/user_model.dart'; // [추가] UserModel 사용을 위해 필요
import '../profile/user_profile_screen.dart';
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
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // [추가] 상대방의 전체 정보를 저장할 변수 (사진 포함)
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    _markAsRead();
    _loadOtherUserProfile(); // [추가] 입장 시 상대방 정보 로드
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // [추가] 상대방 프로필 정보(사진 등) 불러오기
  Future<void> _loadOtherUserProfile() async {
    try {
      final user = await _userService.getUser(widget.otherUserId);
      if (mounted && user != null) {
        setState(() {
          _otherUser = user;
        });
      }
    } catch (e) {
      // 로드 실패 시 조용히 넘어감 (기본 아이콘 표시)
    }
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

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        roomId: widget.roomId,
        senderId: currentUserId,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        _messageController.text = text;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('메시지 전송 실패')));
      }
    }
  }

  // [수정] 이미 불러온 _otherUser 정보를 활용하여 즉시 이동
  void _navigateToUserProfile() {
    if (_otherUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(user: _otherUser!),
        ),
      );
    } else {
      // 만약 아직 로드되지 않았다면 다시 시도 (기존 로직)
      _userService.getUser(widget.otherUserId).then((user) {
        if (user != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(user: user),
            ),
          );
        }
      });
    }
  }

  Future<void> _showMannerRatingDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매너 평가'),
        content: Text(
          '${widget.otherUserName}님과의 대화는 어떠셨나요?\n솔직한 평가는 안전한 커뮤니티를 만듭니다.',
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              _rateUser(0.5);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.thumb_up, color: Colors.blue),
            label: const Text('좋아요'),
          ),
          TextButton.icon(
            onPressed: () {
              _rateUser(-0.5);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.thumb_down, color: Colors.red),
            label: const Text('아쉬워요'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateUser(double scoreChange) async {
    try {
      await _userService.updateMannerScore(widget.otherUserId, scoreChange);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scoreChange > 0 ? '따뜻한 평가를 남겼습니다! 온도가 올라갑니다.' : '평가가 반영되었습니다.',
            ),
            backgroundColor: scoreChange > 0 ? Colors.blue : Colors.grey,
          ),
        );
      }
    } catch (e) {
      // 에러 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _navigateToUserProfile,
          child: Row(
            children: [
              // [수정] 상단 프로필 사진 표시
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    _otherUser?.profileImageUrl != null &&
                        _otherUser!.profileImageUrl.isNotEmpty
                    ? NetworkImage(_otherUser!.profileImageUrl)
                    : null,
                child:
                    _otherUser?.profileImageUrl == null ||
                        _otherUser!.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 20, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rate') {
                _showMannerRatingDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rate',
                child: Row(
                  children: [
                    Icon(Icons.how_to_vote, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('매너 평가하기'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // [수정] 프로필 사진 높이 정렬
                        children: [
                          // [수정] 상대방 메시지 옆 프로필 사진 (클릭 가능)
                          if (!isMe)
                            GestureDetector(
                              onTap: _navigateToUserProfile,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _otherUser?.profileImageUrl != null &&
                                        _otherUser!.profileImageUrl.isNotEmpty
                                    ? NetworkImage(_otherUser!.profileImageUrl)
                                    : null,
                                child:
                                    _otherUser?.profileImageUrl == null ||
                                        _otherUser!.profileImageUrl.isEmpty
                                    ? Text(
                                        widget.otherUserName.isNotEmpty
                                            ? widget.otherUserName[0]
                                            : '?',
                                      )
                                    : null,
                              ),
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
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.timestamp != null
                                        ? timeago.format(
                                            message.timestamp!,
                                            locale: 'ko',
                                          )
                                        : '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // (내 프로필 사진 표시는 선택사항이라 제외하거나 유지)
                          if (isMe) const SizedBox(width: 8),
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
                  color: Colors.black.withOpacity(0.05),
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

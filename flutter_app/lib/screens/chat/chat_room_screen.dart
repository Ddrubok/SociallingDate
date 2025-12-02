import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../models/chat_room_model.dart';
import '../../models/user_model.dart';
import '../profile/user_profile_screen.dart';
// [필수] LocationProvider 임포트 추가
import '../../providers/location_provider.dart';

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
  final LocationService _locationService = LocationService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _otherUser;
  final Map<String, UserModel> _participantsCache = {};
  bool _isSharing = false;

  bool get _isGroupChat => widget.otherUserId.isEmpty;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _checkMyLocationStatus();

    if (!_isGroupChat) {
      _loadOtherUserProfile();
    } else {
      _loadGroupParticipants();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUserProfile() async {
    try {
      final user = await _userService.getUser(widget.otherUserId);
      if (mounted && user != null) {
        setState(() {
          _otherUser = user;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadGroupParticipants() async {
    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .get();
      if (!roomDoc.exists) return;

      final participants = List<String>.from(
        roomDoc.data()?['participants'] ?? [],
      );
      for (var userId in participants) {
        _getUserProfile(userId);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<UserModel?> _getUserProfile(String userId) async {
    if (_participantsCache.containsKey(userId)) {
      return _participantsCache[userId];
    }
    try {
      final user = await _userService.getUser(userId);
      if (user != null) {
        if (mounted) {
          setState(() {
            _participantsCache[userId] = user;
          });
        }
        return user;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<void> _checkMyLocationStatus() async {
    final user = context.read<AuthProvider>().currentUserProfile;
    if (user != null) {
      setState(() {
        _isSharing = user.isSharingLocation;
      });
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: 메시지 전송 실패'),
          ),
        );
      }
    }
  }

  Future<void> _leaveChatRoom() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().currentUserId;
    if (currentUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveChat),
        content: Text(l10n.leaveChatConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.leave, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.leaveChatRoom(widget.roomId, currentUserId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _onTitleTap() {
    if (_isGroupChat) {
      _showGroupParticipantsList();
    } else {
      _navigateToUserProfile(_otherUser);
    }
  }

  void _showGroupParticipantsList() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(widget.roomId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '대화 상대',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final userId = participants[index];
                      final user = _participantsCache[userId];

                      if (user == null) {
                        _getUserProfile(userId);
                        return const ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text('...'),
                        );
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.profileImageUrl),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(
                          user.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToUserProfile(user);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToUserProfile(UserModel? user) {
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfileScreen(user: user)),
      );
    }
  }

  Future<void> _showMannerRatingDialog() async {
    if (_isGroupChat) return;

    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mannerRating),
        content: Text(l10n.ratingContent),
        actions: [
          TextButton(
            onPressed: () {
              _rateUser(0.5);
              Navigator.pop(context);
            },
            child: Text(l10n.ratingGood),
          ),
          TextButton(
            onPressed: () {
              _rateUser(-0.5);
              Navigator.pop(context);
            },
            child: Text(l10n.ratingBad),
          ),
        ],
      ),
    );
  }

  Future<void> _rateUser(double scoreChange) async {
    final l10n = AppLocalizations.of(context)!;
    // [수정] 매너 점수 업데이트 로직 복구
    try {
      await _userService.updateMannerScore(widget.otherUserId, scoreChange);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.ratingSubmitted)));
      }
    } catch (e) {
      // ignore
    }
  }

  // [수정] 위치 공유 토글 (LocationProvider 적용)
  Future<void> _toggleLocationSharing() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    if (_isSharing) {
      await _userService.stopSharingLocation(userId);
      setState(() => _isSharing = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationSharingStop)));
    } else {
      // [핵심] Provider에 저장된 위치 즉시 사용 (0초 딜레이)
      Position? pos = context.read<LocationProvider>().currentPosition;

      // 만약 아직 위치를 못 잡았다면(앱 켜자마자 등) 한 번 시도
      pos ??= await _locationService.getCurrentLocation();

      if (pos != null) {
        await _userService.updateUserLocation(
          userId,
          pos.latitude,
          pos.longitude,
        );
        setState(() => _isSharing = true);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.locationSharingStart)));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionNeeded)),
          );
      }
    }
  }

  String _formatTime(DateTime? timestamp, String localeCode) {
    if (timestamp == null) return '';
    return DateFormat.jm(localeCode).format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().currentUserId;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _onTitleTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    !_isGroupChat &&
                        _otherUser?.profileImageUrl != null &&
                        _otherUser!.profileImageUrl.isNotEmpty
                    ? NetworkImage(_otherUser!.profileImageUrl)
                    : null,
                child: _isGroupChat
                    ? const Icon(Icons.groups, size: 20, color: Colors.grey)
                    : (_otherUser?.profileImageUrl == null ||
                              _otherUser!.profileImageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.grey,
                            )
                          : null),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSharing ? Icons.location_on : Icons.location_off),
            color: _isSharing ? Colors.green : Colors.grey,
            onPressed: _toggleLocationSharing,
            tooltip: l10n.discoverTitle,
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rate') _showMannerRatingDialog();
              if (value == 'leave') _leaveChatRoom();
            },
            itemBuilder: (context) => [
              if (!_isGroupChat)
                PopupMenuItem(value: 'rate', child: Text(l10n.rateManner)),

              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.leaveChat,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // [위치 정보 헤더] (LocationProvider 적용)
          if (!_isGroupChat)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.otherUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null || data['isSharingLocation'] != true)
                  return const SizedBox();

                // [수정] Consumer로 LocationProvider 값 실시간 사용
                return Consumer<LocationProvider>(
                  builder: (context, locProv, child) {
                    final myPos = locProv.currentPosition;

                    if (myPos == null) {
                      return Container(
                        color: Colors.blue[50],
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        child: const Center(
                          child: Text("...", style: TextStyle(fontSize: 12)),
                        ),
                      );
                    }

                    final otherLat = data['latitude'] as double?;
                    final otherLng = data['longitude'] as double?;
                    if (otherLat == null || otherLng == null)
                      return const SizedBox();

                    final distance = _locationService.getDistanceInMeters(
                      myPos.latitude,
                      myPos.longitude,
                      otherLat,
                      otherLng,
                    );

                    String distanceText = distance <= 3000
                        ? l10n.nearbyLabel
                        : (distance > 1000
                              ? '${(distance / 1000).toStringAsFixed(1)}km'
                              : '${distance.toStringAsFixed(0)}m');

                    return Container(
                      color: Colors.blue[50],
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            l10n.distanceLabel(distanceText),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                if (messages.isEmpty)
                  return Center(
                    child: Text(
                      l10n.emptyChat,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    UserModel? senderProfile;
                    if (!isMe) {
                      if (_isGroupChat) {
                        if (!_participantsCache.containsKey(message.senderId)) {
                          _getUserProfile(message.senderId);
                        }
                        senderProfile = _participantsCache[message.senderId];
                      } else {
                        senderProfile = _otherUser;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            GestureDetector(
                              onTap: () =>
                                  _navigateToUserProfile(senderProfile),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    senderProfile?.profileImageUrl != null &&
                                        senderProfile!
                                            .profileImageUrl
                                            .isNotEmpty
                                    ? NetworkImage(
                                        senderProfile.profileImageUrl,
                                      )
                                    : null,
                                child:
                                    senderProfile?.profileImageUrl == null ||
                                        senderProfile!.profileImageUrl.isEmpty
                                    ? Text(
                                        senderProfile?.displayName.isNotEmpty ==
                                                true
                                            ? senderProfile!.displayName[0]
                                            : '?',
                                      )
                                    : null,
                              ),
                            ),
                          if (!isMe) const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (_isGroupChat &&
                                    !isMe &&
                                    senderProfile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 2,
                                    ),
                                    child: Text(
                                      senderProfile.displayName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16)
                                        .copyWith(
                                          topLeft: isMe
                                              ? const Radius.circular(16)
                                              : const Radius.circular(0),
                                          topRight: isMe
                                              ? const Radius.circular(0)
                                              : const Radius.circular(16),
                                        ),
                                  ),
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.timestamp, localeCode),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
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
                        hintText: l10n.messageInputHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
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

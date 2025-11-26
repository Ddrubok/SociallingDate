import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _loadOtherUserProfile();
    _checkMyLocationStatus();
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

  void _navigateToUserProfile() {
    if (_otherUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(user: _otherUser!),
        ),
      );
    } else {
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
    await _userService.updateMannerScore(widget.otherUserId, scoreChange);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ratingSubmitted)));
    }
  }

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
      final pos = await _locationService.getCurrentLocation();
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
          onTap: _navigateToUserProfile,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
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
              const SizedBox(width: 10),
              Text(
                widget.otherUserName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'rate', child: Text(l10n.rateManner)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
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

              return FutureBuilder(
                future: _locationService.getCurrentLocation(),
                builder: (context, myPosSnapshot) {
                  if (!myPosSnapshot.hasData) {
                    return Container(
                      color: Colors.blue[50],
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      child: const Center(
                        child: Text("...", style: TextStyle(fontSize: 12)),
                      ),
                    );
                  }
                  final myPos = myPosSnapshot.data!;
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
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
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
                  // [수정] 최신 코드로 변경: withValues(alpha: 0.05)
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

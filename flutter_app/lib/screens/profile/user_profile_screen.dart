import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
// [중요] 상대 경로 확인 (chat 폴더가 상위에 있으므로 ../chat/...)
import '../chat/chat_room_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
  }

  void _checkIfBlocked() {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser != null &&
        currentUser.blockedUsers.contains(widget.user.uid)) {
      setState(() {
        _isBlocked = true;
      });
    }
  }

  // 신고하기
  Future<void> _showReportDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final reasons = ['부적절한 사진/프로필', '욕설 및 비방', '성희롱', '광고/스팸', '사기 의심', '기타'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportReasonTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reasons.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(reasons[index]),
                onTap: () async {
                  Navigator.pop(context);
                  await _userService.reportUser(
                    reporterId: context.read<AuthProvider>().currentUserId!,
                    reportedUserId: widget.user.uid,
                    reason: reasons[index],
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.ratingSubmitted)),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  // 차단 토글
  Future<void> _toggleBlock() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().currentUserId;
    if (currentUserId == null) return;

    if (_isBlocked) {
      await _userService.unblockUser(currentUserId, widget.user.uid);
      setState(() => _isBlocked = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("차단이 해제되었습니다.")));
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.block),
          content: Text(l10n.blockConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.block,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _userService.blockUser(currentUserId, widget.user.uid);
        setState(() => _isBlocked = true);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("차단되었습니다.")));
        }
      }
    }
  }

  // 채팅 시작
  Future<void> _startChat() async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    try {
      final roomId = await _chatService.createOrGetChatRoom(
        currentUserId: currentUser.uid,
        otherUserId: widget.user.uid,
        currentUserName: currentUser.displayName,
        otherUserName: widget.user.displayName,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            roomId: roomId,
            otherUserName: widget.user.displayName,
            otherUserId: widget.user.uid,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userProfileTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') _showReportDialog();
              if (value == 'block') _toggleBlock();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'report', child: Text(l10n.report)),
              PopupMenuItem(
                value: 'block',
                child: Text(
                  _isBlocked ? l10n.unblock : l10n.block,
                  style: TextStyle(
                    color: _isBlocked ? Colors.black : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(widget.user.profileImageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.displayName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.user.authStatus == 'verified')
                  Icon(Icons.verified, size: 20, color: Colors.blue[600]),
                if (widget.user.authStatus == 'verified')
                  const SizedBox(width: 4),
                Text(
                  '${widget.user.age} · ${widget.user.location}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, color: Colors.pink[300]),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.mannerTemperature} ${widget.user.mannerScore.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: Colors.pink[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bioLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.bio,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.interestsLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.user.interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // [수정] Deprecation 해결
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isBlocked ? null : _startChat,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            l10n.startChat,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

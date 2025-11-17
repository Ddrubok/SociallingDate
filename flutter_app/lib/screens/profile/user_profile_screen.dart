import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../chat/chat_room_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  Future<void> _startChat(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final chatService = ChatService();

    try {
      final roomId = await chatService.createOrGetChatRoom(
        currentUserId: authProvider.currentUserId!,
        otherUserId: user.uid,
        currentUserName: authProvider.currentUserProfile!.displayName,
        otherUserName: user.displayName,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              roomId: roomId,
              otherUserName: user.displayName,
              otherUserId: user.uid,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _reportUser(BuildContext context) async {
    final reasons = ['부적절한 행동', '욕설/비방', '스팸', '허위 정보', '기타'];
    String? selectedReason;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('신고하기'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedReason),
              child: const Text('신고'),
            ),
          ],
        );
      },
    );

    if (result != null && context.mounted) {
      final userService = UserService();
      final authProvider = context.read<AuthProvider>();

      try {
        await userService.reportUser(
          reporterId: authProvider.currentUserId!,
          reportedUserId: user.uid,
          reason: result,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('신고가 접수되었습니다')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                _reportUser(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red),
                    SizedBox(width: 8),
                    Text('신고하기'),
                  ],
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
              backgroundImage: NetworkImage(user.profileImageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.authStatus == 'verified')
                  Icon(Icons.verified, size: 20, color: Colors.blue[600]),
                if (user.authStatus == 'verified') const SizedBox(width: 4),
                Text(
                  '${user.age}세 · ${user.location}',
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
                    '매너온도 ${user.mannerScore.toStringAsFixed(1)}°',
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
                    '자기소개',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '관심사',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _startChat(context),
            icon: const Icon(Icons.chat_bubble),
            label: const Text('채팅하기', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

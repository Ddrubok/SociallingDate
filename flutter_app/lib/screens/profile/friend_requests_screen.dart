import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import 'user_profile_screen.dart'; // 신청자 프로필 확인용

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  // 수락 처리
  Future<void> _accept(String senderId) async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _userService.acceptFriendRequest(currentUser.uid, senderId);
      await context
          .read<AuthProvider>()
          .loadUserProfile(); // 내 정보 갱신 (목록에서 사라짐)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requestAccepted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 거절 처리
  Future<void> _reject(String senderId) async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _userService.rejectFriendRequest(currentUser.uid, senderId);
      await context.read<AuthProvider>().loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requestRejected)));
      }
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.watch<AuthProvider>().currentUserProfile;

    if (currentUser == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 'pending'(대기중) 상태인 요청만 필터링
    final requests = currentUser.friendRequestsReceived
        .where((req) => req['status'] == 'pending')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friendRequestReceived),
      ), // "친구가 되고 싶어 해요!"
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? Center(child: Text(l10n.noFriendRequests)) // "받은 요청이 없습니다"
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final req = requests[index];
                final senderId = req['senderId'];

                // 보낸 사람 정보 가져오기 (FutureBuilder)
                return FutureBuilder<UserModel?>(
                  future: _userService.getUser(senderId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const SizedBox(); // 로딩 중엔 빈 공간
                    final sender = snapshot.data!;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      // 프로필 사진 누르면 상세 정보 확인
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserProfileScreen(user: sender),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(sender.profileImageUrl),
                        ),
                      ),
                      title: Text(
                        sender.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${sender.age}세 · ${sender.location}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 거절 버튼
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _reject(sender.uid),
                            tooltip: l10n.rejectFriendRequest,
                          ),
                          // 수락 버튼
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _accept(sender.uid),
                            tooltip: l10n.acceptFriendRequest,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

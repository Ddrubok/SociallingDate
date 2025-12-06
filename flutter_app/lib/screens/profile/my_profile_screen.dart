import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import '../../providers/auth_provider.dart';
import 'friend_requests_screen.dart'; // [추가] 요청 목록 화면

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 내 정보를 watch로 구독 (요청이 오면 실시간 업데이트)
    final currentUser = context.watch<AuthProvider>().currentUserProfile;

    // 대기 중인 받은 요청 개수 확인
    final pendingRequestsCount =
        currentUser?.friendRequestsReceived
            .where((req) => req['status'] == 'pending')
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfileTitle),
        actions: [
          // [추가] 친구 요청 알림 버튼
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendRequestsScreen(),
                ),
              );
            },
            icon: Badge(
              isLabelVisible: pendingRequestsCount > 0, // 요청이 있을 때만 빨간 점 표시
              label: Text('$pendingRequestsCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),

          // 기존 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(currentUser.profileImageUrl),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentUser.authStatus == 'verified')
                        Icon(Icons.verified, size: 20, color: Colors.blue[600]),
                      if (currentUser.authStatus == 'verified')
                        const SizedBox(width: 4),
                      Text(
                        '${currentUser.age} · ${currentUser.location}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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
                          '${l10n.mannerTemperature} ${currentUser.mannerScore.toStringAsFixed(1)}°',
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentUser.bio,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.interestsLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentUser.interests.map((interest) {
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

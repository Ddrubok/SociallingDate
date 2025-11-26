import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// [중요] 번역 파일 및 설정 화면 임포트
import 'package:flutter_app/l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import '../../providers/auth_provider.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [번역] 변수 선언
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfileTitle), // "내 프로필"
        actions: [
          // [변경] 로그아웃 버튼 대신 '설정' 버튼으로 변경
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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUserProfile;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
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
                      '${user.age} · ${user.location}', // 나이/지역은 데이터 그대로 표시
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
                        // "매너온도 36.5°"
                        '${l10n.mannerTemperature} ${user.mannerScore.toStringAsFixed(1)}°',
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
                        l10n.bioLabel, // "자기소개"
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(user.bio, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 24),
                      Text(
                        l10n.interestsLabel, // "관심사"
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.interests.map((interest) {
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
          );
        },
      ),
    );
  }
}

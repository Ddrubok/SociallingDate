import 'package:flutter/material.dart';
// [중요] 번역 파일 임포트
import 'package:flutter_app/l10n/app_localizations.dart';
import '../home/discover_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/my_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DiscoverScreen(),
    ChatListScreen(),
    MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // [번역] 변수 선언
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        // [주의] l10n 변수를 쓰기 때문에 여기서는 'const'를 빼야 합니다.
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.tabDiscover, // "탐색"
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.tabChat, // "채팅"
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabProfile, // "프로필"
          ),
        ],
      ),
    );
  }
}

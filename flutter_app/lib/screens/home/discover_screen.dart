import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../profile/user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late TabController _tabController;

  // 데이터 캐싱
  List<UserModel> _dailyUsers = [];
  bool _isLoadingDaily = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 탭 4개
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDailyRecommendations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 1. 오늘의 추천 로드
  Future<void> _loadDailyRecommendations() async {
    try {
      final user = context.read<AuthProvider>().currentUserProfile;
      if (user != null) {
        final users = await _userService.getDailyRecommendations(
          user.uid,
          user.gender,
        );
        if (mounted) {
          setState(() {
            _dailyUsers = users;
            _isLoadingDaily = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDaily = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoverTitle)),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. 오늘의 추천 섹션 ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.dailyRecommend, // "오늘의 추천"
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: _isLoadingDaily
                        ? const Center(child: CircularProgressIndicator())
                        : _dailyUsers.isEmpty
                        ? Center(child: Text(l10n.noUsersFound))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _dailyUsers.length,
                            itemBuilder: (context, index) {
                              return _DailyUserCard(user: _dailyUsers[index]);
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // --- 2. 맞춤 추천 탭바 ---
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: l10n.tabNearby), // 주변
                    Tab(text: l10n.tabInterest), // 취미
                    Tab(text: l10n.tabReligion), // 종교
                    Tab(text: l10n.tabLifestyle), // 라이프
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        // --- 3. 탭 내용 (리스트) ---
        body: TabBarView(
          controller: _tabController,
          children: [
            _UserListTab(filterType: 'nearby'),
            _UserListTab(filterType: 'interest'),
            _UserListTab(filterType: 'religion'),
            _UserListTab(filterType: 'lifestyle'),
          ],
        ),
      ),
    );
  }
}

// 탭별 리스트 위젯
class _UserListTab extends StatefulWidget {
  final String filterType;
  const _UserListTab({required this.filterType});

  @override
  State<_UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<_UserListTab> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return const SizedBox();

    final locProv = context.read<LocationProvider>();
    final myPos = locProv.currentPosition;

    return FutureBuilder<List<UserModel>>(
      future: _userService.getAllUsers(
        currentUserId: currentUser.uid,
        currentLat: myPos?.latitude,
        currentLng: myPos?.longitude,
        // 필터별 조건 설정
        maxDistanceKm: widget.filterType == 'nearby'
            ? 10.0
            : 100.0, // 주변: 10km, 그외: 100km
        interestFilter: widget.filterType == 'interest'
            ? currentUser.interests
            : null,
        religion: widget.filterType == 'religion' ? currentUser.religion : null,
        lifestyle: widget.filterType == 'lifestyle'
            ? currentUser.lifestyle
            : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) return const Center(child: Text("조건에 맞는 친구가 없습니다"));

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (context, index) => _ListUserCard(user: users[index]),
        );
      },
    );
  }
}

// 가로 카드 (오늘의 추천용)
class _DailyUserCard extends StatelessWidget {
  final UserModel user;
  const _DailyUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.all(4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.network(user.profileImageUrl, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                    Text(
                      "${user.age}세",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 세로 리스트 카드 (탭용) - 기존 _UserCard 재활용 가능
class _ListUserCard extends StatelessWidget {
  final UserModel user;
  const _ListUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(user.profileImageUrl),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${user.age}세 · ${user.location}"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
        ),
      ),
    );
  }
}

// Sliver 헤더용 델리게이트 (탭바 고정용)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

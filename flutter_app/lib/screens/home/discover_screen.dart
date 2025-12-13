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

class _DiscoverScreenState extends State<DiscoverScreen> {
  final UserService _userService = UserService();

  List<UserModel> _dailyUsers = [];
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  // 필터 (추후 구현 시 사용)
  final List<String> _selectedInterests = [];
  final double _maxDistance = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final authProv = context.read<AuthProvider>();
    final locProv = context.read<LocationProvider>();
    final currentUser = authProv.currentUserProfile;

    if (currentUser == null) return;

    try {
      final daily = await _userService.getDailyRecommendations(
        currentUserId: currentUser.uid,
        myGender: currentUser.gender,
      );

      final all = await _userService.getAllUsers(
        currentUserId: currentUser.uid,
        interestFilter: _selectedInterests.isNotEmpty
            ? _selectedInterests
            : null,
        currentLat: locProv.currentPosition?.latitude,
        currentLng: locProv.currentPosition?.longitude,
        maxDistanceKm: _maxDistance,
      );

      if (mounted) {
        setState(() {
          _dailyUsers = daily;
          _allUsers = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      // [수정] Scaffold의 appBar를 제거하고 body의 CustomScrollView 안으로 넣습니다.
      body: CustomScrollView(
        slivers: [
          // ------------------------------------------------
          // 1. [핵심] 확장형 앱바 (오늘의 추천 섹션)
          // ------------------------------------------------
          SliverAppBar(
            pinned: true, // 스크롤 올려도 타이틀은 상단에 고정됨
            floating: false,
            expandedHeight: 380.0, // 펼쳐졌을 때의 높이 (카드 크기 고려)
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,

            // [상단 타이틀]
            title: Text(
              l10n.discoverTitle, // "탐색"
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false, // 왼쪽 정렬
            // [필터 버튼]
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  // 필터 로직
                },
              ),
            ],

            // [배경 컨텐츠] 스크롤 시 서서히 사라짐(최소화)
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end, // 아래쪽 배치
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 텍스트
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            l10n.dailyRecommend, // "오늘의 추천"
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 가로 스크롤 카드 리스트
                    SizedBox(
                      height: 260, // 카드 영역 높이
                      child: _dailyUsers.isEmpty
                          ? Center(child: Text(l10n.noUsersFound))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: _dailyUsers.length,
                              itemBuilder: (context, index) {
                                return _DailyUserCard(user: _dailyUsers[index]);
                              },
                            ),
                    ),
                    const SizedBox(height: 16), // 하단 여백
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // 2. 내 주변 친구들 (세로 리스트)
          // ------------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                "내 주변의 친구들", // (필요 시 l10n 추가: nearbyFriends)
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          _allUsers.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text(l10n.noUsersFound)),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _ListUserCard(user: _allUsers[index]);
                  }, childCount: _allUsers.length),
                ),

          // 하단 네비게이션 바에 가려지지 않게 여백 추가
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// [위젯 1] 오늘의 추천 전용 카드
class _DailyUserCard extends StatelessWidget {
  final UserModel user;

  const _DailyUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
        );
      },
      child: Container(
        width: 170, // 카드 너비
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경 이미지
              Image.network(
                user.profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
              ),
              // 그라데이션
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              // 정보
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${user.displayName}, ${user.age}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 뱃지
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "PICK",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// [위젯 2] 일반 리스트 카드
class _ListUserCard extends StatelessWidget {
  final UserModel user;

  const _ListUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(user.profileImageUrl),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${user.age}세 · ${user.location}"),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.favorite, size: 14, color: Colors.pink[300]),
                const SizedBox(width: 4),
                Text(
                  "${user.mannerScore.toStringAsFixed(1)}°",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
          );
        },
      ),
    );
  }
}

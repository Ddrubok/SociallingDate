import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
// [중요] 번역 및 Provider 임포트
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart'; // [필수]
import '../profile/user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  final List<String> _selectedInterests = [];
  double _maxDistance = 50.0; // [추가] 거리 필터 (기본 50km)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      // [추가] 내 위치 정보 가져오기
      final locProv = context.read<LocationProvider>();
      final myPos = locProv.currentPosition;

      final users = await _userService.getAllUsers(
        currentUserId: authProvider.currentUserId,
        interestFilter: _selectedInterests.isNotEmpty
            ? _selectedInterests
            : null,
        minMannerScore: 50.0,
        // [추가] 위치 정보 전달
        currentLat: myPos?.latitude,
        currentLng: myPos?.longitude,
        maxDistanceKm: _maxDistance,
      );

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 필터 바텀 시트 표시
  void _showInterestFilter() {
    final currentUserInterests =
        context.read<AuthProvider>().currentUserProfile?.interests ?? [];
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 화면 높이 유연하게
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.filterTitle, // "관심사 필터"
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            // 초기화
                            setModalState(() {
                              _selectedInterests.clear();
                              _maxDistance = 50.0;
                            });
                            // 메인 상태도 초기화 후 재로드
                            setState(() {
                              _selectedInterests.clear();
                              _maxDistance = 50.0;
                            });
                            Navigator.pop(context);
                            _loadUsers();
                          },
                          child: Text(l10n.reset), // "초기화"
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // [추가] 거리 슬라이더 UI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "최대 거리",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${_maxDistance.round()}km",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistance,
                      min: 1.0,
                      max: 100.0,
                      divisions: 99,
                      label: "${_maxDistance.round()}km",
                      onChanged: (value) {
                        setModalState(() {
                          _maxDistance = value;
                        });
                      },
                    ),
                    const Divider(height: 32),

                    const Text(
                      "관심사",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentUserInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(
                          interest,
                        );
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // 적용 버튼 누르면 상태 저장하고 닫기
                        setState(() {
                          // _selectedInterests와 _maxDistance는 이미 업데이트됨 (같은 참조 or setModalState로 변경됨)
                          // 명시적으로 다시 할당하지 않아도 되지만, 안전하게 로드 호출
                        });
                        Navigator.pop(context);
                        _loadUsers();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.apply), // "적용"
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 가짜 유저 생성 (테스트용)
  Future<void> _createDummyUser() async {
    final random = Random();
    final names = ['김철수', '이영희', '박지민', '최수현', '정우성', '강동원'];
    final interestsList = ['운동', '여행', '독서', '영화', '음악', '맛집'];
    // 랜덤 위치 (서울 기준 근처)
    final lat = 37.5665 + (random.nextDouble() - 0.5) * 0.1;
    final lng = 126.9780 + (random.nextDouble() - 0.5) * 0.1;

    final name =
        '${names[random.nextInt(names.length)]} ${random.nextInt(100)}';
    final tempId = 'dummy_${DateTime.now().millisecondsSinceEpoch}';

    final dummyUser = UserModel(
      uid: tempId,
      displayName: name,
      profileImageUrl: 'https://picsum.photos/seed/$tempId/200/200',
      authStatus: 'verified',
      mannerScore: 50.0 + random.nextInt(40),
      interests: {
        interestsList[random.nextInt(interestsList.length)],
        interestsList[random.nextInt(interestsList.length)],
      }.toList(),
      bio: '안녕하세요! $name입니다. 함께 취미를 즐겨요.',
      age: 20 + random.nextInt(15),
      gender: random.nextBool() ? 'male' : 'female',
      location: '서울 어딘가',
      createdAt: DateTime.now(),
      isBlocked: false,
      latitude: lat, // 위치 정보 추가
      longitude: lng,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(tempId)
        .set(dummyUser.toFirestore());

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('가짜 유저 생성 완료!')));
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().currentUserProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoverTitle), // "탐색"
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedInterests.isNotEmpty,
              label: Text('${_selectedInterests.length}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showInterestFilter,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDummyUser,
        backgroundColor: Colors.orange,
        tooltip: '테스트용 가짜 유저 생성',
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noUsersFound, // "매칭되는 사용자가 없습니다"
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  return _UserCard(user: _users[index]);
                },
              ),
            ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    // 나를 좋아하는지 확인
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    final bool likesMe = currentUser?.receivedLikes.contains(user.uid) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: likesMe
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(user: user),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user.profileImageUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user.authStatus == 'verified')
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: Colors.blue[600],
                          ),

                        if (likesMe) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: const Text(
                              "Like!",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.age}세 · ${user.location}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 16, color: Colors.pink[300]),
                        const SizedBox(width: 4),
                        Text(
                          '${user.mannerScore.toStringAsFixed(1)}°',
                          style: TextStyle(
                            color: Colors.pink[300],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            user.interests.take(3).join(' · '),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

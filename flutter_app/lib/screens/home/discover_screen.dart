import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
// [중요] 번역 파일 임포트
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final users = await _userService.getAllUsers(
        currentUserId: authProvider.currentUserId,
        interestFilter: _selectedInterests.isNotEmpty
            ? _selectedInterests
            : null,
        minMannerScore: 50.0,
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

  // [개발용] 가짜 유저 생성 함수
  Future<void> _createDummyUser() async {
    final random = Random();
    final names = ['김철수', '이영희', '박지민', '최수현', '정우성', '강동원'];
    final interestsList = [
      'camping',
      'coffee_brewing',
      'reading',
      'fitness',
      'travel',
    ];
    final locations = ['서울 강남구', '부산 해운대구', '경기 판교', '서울 마포구'];

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
      location: locations[random.nextInt(locations.length)],
      createdAt: DateTime.now(),
      isBlocked: false,
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

  void _showInterestFilter() {
    final currentUserInterests =
        context.read<AuthProvider>().currentUserProfile?.interests ?? [];
    // [번역] 다이얼로그 내부에서도 l10n 사용 가능
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                            setState(() {
                              _selectedInterests.clear();
                            });
                            Navigator.pop(context);
                            _loadUsers();
                          },
                          child: Text(l10n.reset), // "초기화"
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadUsers();
                      },
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

  @override
  Widget build(BuildContext context) {
    // [번역] 변수 선언
    final l10n = AppLocalizations.of(context)!;

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
    // [추가] 나를 좋아하는지 확인
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    final bool likesMe = currentUser?.receivedLikes.contains(user.uid) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      // [수정] 파란색 테두리 적용
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: likesMe
            ? const BorderSide(color: Colors.blue, width: 2) // 나를 좋아하면 파란 테두리
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

                        // [추가] '나를 좋아해요' 뱃지
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
                    // ... 기존 내용 (나이, 지역, 매너온도 등) ...
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
                        // ...
                      ],
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

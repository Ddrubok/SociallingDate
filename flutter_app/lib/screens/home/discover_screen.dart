import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // 랜덤 생성을 위해 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 접근을 위해 추가
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
    // 화면이 그려진 후 데이터 로드
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
        minMannerScore: 50.0, // 매너온도 50도 이상만 표시
      );
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('유저 로드 오류: $e'); // 디버깅용 로그
      setState(() => _isLoading = false);
    }
  }

  // --- [개발용] 가짜 유저 생성 함수 ---
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

    // 랜덤 데이터 생성
    final name =
        '${names[random.nextInt(names.length)]} ${random.nextInt(100)}';
    final tempId = 'dummy_${DateTime.now().millisecondsSinceEpoch}';

    final dummyUser = UserModel(
      uid: tempId,
      displayName: name,
      // picsum을 사용하여 매번 다른 이미지 생성
      profileImageUrl: 'https://picsum.photos/seed/$tempId/200/200',
      authStatus: 'verified',
      mannerScore: 50.0 + random.nextInt(40), // 50~90점 사이
      interests: {
        interestsList[random.nextInt(interestsList.length)],
        interestsList[random.nextInt(interestsList.length)],
      }.toList(), // 중복 제거
      bio: '안녕하세요! $name입니다. 함께 취미를 즐겨요.',
      age: 20 + random.nextInt(15),
      gender: random.nextBool() ? 'male' : 'female',
      location: locations[random.nextInt(locations.length)],
      createdAt: DateTime.now(),
      isBlocked: false,
    );

    // Firestore에 직접 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(tempId)
        .set(dummyUser.toFirestore());

    // 목록 새로고침
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('가짜 유저 생성 완료!')));
      _loadUsers();
    }
  }
  // ---------------------------------

  void _showInterestFilter() {
    // ... (기존 필터 로직 유지)
    // (아래 전체 코드에 포함되어 있습니다)
    final currentUserInterests =
        context.read<AuthProvider>().currentUserProfile?.interests ?? [];

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
                          '관심사 필터',
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
                          child: const Text('초기화'),
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
                      child: const Text('적용'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('탐색'),
        actions: [
          // 필터 버튼
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
      // --- [개발용] 플로팅 버튼 추가 ---
      floatingActionButton: FloatingActionButton(
        onPressed: _createDummyUser,
        backgroundColor: Colors.orange,
        tooltip: '테스트용 가짜 유저 생성',
        child: const Icon(Icons.person_add),
      ),
      // ---------------------------
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
                    '매칭되는 사용자가 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '오른쪽 아래 버튼을 눌러\n테스트 유저를 만들어보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.orange),
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

// _UserCard 클래스는 기존과 동일하게 유지
class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

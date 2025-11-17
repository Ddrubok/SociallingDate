import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedGender = 'male';
  final List<String> _selectedInterests = [];
  
  final List<String> _availableInterests = [
    'camping', 'indie_music', 'coffee_brewing', 'reading', 'writing',
    'running', 'fitness', 'healthy_food', 'hiking', 'yoga', 'meditation',
    'wellness', 'photography', 'travel', 'art', 'cooking', 'food_tour',
    'baking', 'movies', 'music', 'concerts', 'guitar', 'coding', 'remote_work'
  ];

  final Map<String, String> _interestLabels = {
    'camping': '캠핑', 'indie_music': '인디음악', 'coffee_brewing': '커피',
    'reading': '독서', 'writing': '글쓰기', 'running': '러닝', 'fitness': '헬스',
    'healthy_food': '건강식', 'hiking': '등산', 'yoga': '요가', 'meditation': '명상',
    'wellness': '웰니스', 'photography': '사진', 'travel': '여행', 'art': '미술',
    'cooking': '요리', 'food_tour': '맛집탐방', 'baking': '베이킹', 'movies': '영화',
    'music': '음악', 'concerts': '공연', 'guitar': '기타', 'coding': '코딩',
    'remote_work': '재택근무'
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 관심사를 선택해주세요')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    
    final userProfile = UserModel(
      uid: '',
      displayName: _nameController.text.trim(),
      profileImageUrl: 'https://picsum.photos/seed/${_nameController.text}/400',
      authStatus: 'verified',
      mannerScore: 75.0,
      interests: _selectedInterests,
      bio: _bioController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      location: _locationController.text.trim(),
    );

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      userProfile: userProfile,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? '회원가입에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return '올바른 이메일을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호 (6자 이상)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return '비밀번호는 최소 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '나이',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '나이를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: '성별',
                          prefixIcon: const Icon(Icons.wc_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('남성')),
                          DropdownMenuItem(value: 'female', child: Text('여성')),
                          DropdownMenuItem(value: 'other', child: Text('기타')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value ?? 'male';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: '지역 (예: 서울 강남구)',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '지역을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '자기소개',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '자기소개를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  '관심사 선택 (최소 1개)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(_interestLabels[interest] ?? interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
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
                const SizedBox(height: 32),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              '회원가입',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

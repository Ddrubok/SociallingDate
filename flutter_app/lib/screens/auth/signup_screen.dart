import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
// [중요] 번역 파일 임포트
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

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
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  final StorageService _storageService = StorageService();
  File? _profileImage;
  String _selectedGender = 'male';
  final List<String> _selectedInterests = [];

  // 관심사 목록 (예시 데이터 - 나중에는 서버나 상수 파일로 관리 추천)
  final List<String> _interestsList = [
    '운동',
    '여행',
    '독서',
    '영화',
    '음악',
    '맛집',
    '게임',
    '코딩',
    '등산',
    '사진',
    '반려동물',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 이미지 선택
  Future<void> _pickProfileImage() async {
    final image = await _storageService.pickImage(context);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  // 회원가입 처리
  Future<void> _handleSignUp() async {
    final l10n = AppLocalizations.of(context)!; // 번역 변수

    if (!_formKey.currentState!.validate()) return;

    // 1. 프로필 사진 필수 체크
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectProfileImage)), // "프로필 사진을 선택해주세요"
      );
      return;
    }

    // 2. 관심사 개수 체크
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.interestError)), // "관심사를 3개 이상 선택해주세요"
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // 3. 회원가입 시도 (일단 사진 URL은 비워두고 진행)
    final userProfile = UserModel(
      uid: '', // AuthProvider 내부에서 설정됨
      displayName: _nameController.text.trim(),
      profileImageUrl: '', // 나중에 업데이트
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

    // [중요] 비동기 작업 후 화면이 살아있는지 확인
    if (!mounted) return;

    if (success) {
      try {
        // 4. 회원가입 성공 시, 생성된 UID로 이미지 업로드
        final newUserId = authProvider.currentUserId;
        if (newUserId != null && _profileImage != null) {
          final imageUrl = await _storageService.uploadProfileImage(
            imageFile: _profileImage!,
            userId: newUserId,
          );

          // 5. 업로드된 이미지 URL로 프로필 업데이트
          await authProvider.updateProfile({'profileImageUrl': imageUrl});
        }

        if (!mounted) return;

        // 6. 성공 결과 반환 (로그인 화면으로 돌아감)
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? l10n.signUpError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signUpTitle), // "회원가입"
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 프로필 사진 선택 ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _pickProfileImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 이메일 ---
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  hintText: l10n.emailHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.emailEmpty;
                  if (!value.contains('@')) return l10n.emailInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- 비밀번호 ---
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                  hintText: l10n.passwordHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.passwordEmpty;
                  if (value.length < 6) return l10n.passwordLength;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- 이름 ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.nameLabel, // "이름"
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.nameLabel : null, // 간단 검증
              ),
              const SizedBox(height: 16),

              // --- 나이 ---
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.ageLabel, // "나이"
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.ageLabel : null,
              ),
              const SizedBox(height: 16),

              // --- 성별 (드롭다운) ---
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: l10n.genderLabel, // "성별"
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.wc),
                ),
                items: [
                  DropdownMenuItem(value: 'male', child: Text(l10n.male)),
                  DropdownMenuItem(value: 'female', child: Text(l10n.female)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedGender = value);
                },
              ),
              const SizedBox(height: 16),

              // --- 지역 ---
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: l10n.locationLabel, // "지역"
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.locationLabel : null,
              ),
              const SizedBox(height: 16),

              // --- 자기소개 ---
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.bioLabel, // "자기소개"
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.bioLabel : null,
              ),
              const SizedBox(height: 24),

              // --- 관심사 선택 (Chips) ---
              Text(
                '${l10n.interestsLabel} (${l10n.selectInterestsHint})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _interestsList.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
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

              // --- 가입 버튼 ---
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            l10n.signUpButton, // "가입하기"
                            style: const TextStyle(fontSize: 18),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

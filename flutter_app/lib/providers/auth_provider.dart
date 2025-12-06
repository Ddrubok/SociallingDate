import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUserProfile;
  bool _isLoading = false;
  String? _error;

  // 스트림 구독 관리 변수
  StreamSubscription<UserModel?>? _userProfileSubscription;

  UserModel? get currentUserProfile => _currentUserProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;
  String? get currentUserId => _authService.currentUserId;

  bool get isAuthenticated => _authService.currentUser != null;

  // [수정] 생성자에서 상태 변화 감지 시작
  AuthProvider() {
    _init();
  }

  void _init() {
    // Firebase Auth 상태 변화 감지
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // 로그인 됨 -> 프로필 실시간 구독 시작
        _subscribeToUserProfile(user.uid);
      } else {
        // 로그아웃 됨 -> 구독 취소 및 데이터 초기화
        _unsubscribeFromUserProfile();
        _currentUserProfile = null;
        notifyListeners();
      }
    });
  }

  // [신규] 실시간 프로필 구독
  void _subscribeToUserProfile(String uid) {
    _userProfileSubscription?.cancel(); // 기존 구독 취소
    _isLoading = true;
    notifyListeners();

    _userProfileSubscription = _authService
        .getUserProfileStream(uid)
        .listen(
          (userModel) {
            _currentUserProfile = userModel;
            _isLoading = false;
            notifyListeners(); // 화면 자동 갱신!
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _unsubscribeFromUserProfile() {
    _userProfileSubscription?.cancel();
    _userProfileSubscription = null;
  }

  @override
  void dispose() {
    _unsubscribeFromUserProfile();
    super.dispose();
  }

  // [수정] 수동 로드 (이제 필요 없지만 호환성을 위해 유지하거나 초기화용으로 사용)
  Future<void> loadUserProfile() async {
    if (_authService.currentUserId != null) {
      _subscribeToUserProfile(_authService.currentUserId!);
    }
  }

  // 회원가입
  Future<bool> signUp({
    required String email,
    required String password,
    required UserModel userProfile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      final newProfile = userProfile.copyWith(uid: credential.user!.uid);
      await _authService.createUserProfile(newProfile);

      // 스트림이 자동으로 감지하므로 여기서 별도로 설정할 필요 없음

      _error = null;
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그인
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      // 스트림이 자동으로 감지함
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      // 리스너에서 처리됨
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 프로필 업데이트
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_authService.currentUserId == null) return false;
    try {
      await _authService.updateUserProfile(_authService.currentUserId!, data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return '사용자를 찾을 수 없습니다.';
        case 'wrong-password':
          return '비밀번호가 잘못되었습니다.';
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'weak-password':
          return '비밀번호가 너무 약합니다.';
        case 'invalid-email':
          return '유효하지 않은 이메일 주소입니다.';
        default:
          return error.message ?? '인증 오류가 발생했습니다.';
      }
    }
    return error.toString();
  }
}

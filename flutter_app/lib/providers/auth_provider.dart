import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUserProfile;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUserProfile => _currentUserProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;
  String? get currentUserId => _authService.currentUserId;

  // 로그인 상태 확인
  bool get isAuthenticated => _authService.currentUser != null;

  // 사용자 프로필 로드
  Future<void> loadUserProfile() async {
    if (_authService.currentUserId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUserProfile = await _authService.getUserProfile(_authService.currentUserId!);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('프로필 로드 실패: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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

      // 사용자 프로필 생성
      final newProfile = userProfile.copyWith(uid: credential.user!.uid);
      await _authService.createUserProfile(newProfile);
      _currentUserProfile = newProfile;

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('회원가입 실패: $e');
      }
      return false;
    }
  }

  // 로그인
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      await loadUserProfile();

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('로그인 실패: $e');
      }
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUserProfile = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      if (kDebugMode) {
        debugPrint('로그아웃 실패: $e');
      }
    }
  }

  // 프로필 업데이트
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_authService.currentUserId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(_authService.currentUserId!, data);
      await loadUserProfile();
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('프로필 업데이트 실패: $e');
      }
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

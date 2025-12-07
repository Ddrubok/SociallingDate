import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// [추가] Firestore & Auth 접근용
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ko'); // 기본값

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  // 언어 변경 및 저장
  Future<void> setLocale(Locale locale) async {
    if (!['ko', 'en', 'ja'].contains(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();

    // 1. 기기에 저장 (기존 로직)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);

    // 2. [추가] 서버(Firestore)에도 저장 (알림용)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'languageCode': locale.languageCode});
      } catch (e) {
        // 에러 무시 (언어 변경이 우선이므로)
      }
    }
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }
}

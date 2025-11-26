import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ko'); // 기본값: 한국어

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale(); // 앱 켜질 때 저장된 언어 불러오기
  }

  // 언어 변경 및 저장
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners(); // 앱 전체에 "언어 바뀌었다!" 알림

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  // 저장된 언어 불러오기
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }
}

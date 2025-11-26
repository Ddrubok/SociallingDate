import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// [다국어 지원 패키지]
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_app/l10n/app_localizations.dart'; // 패키지명 확인 필요

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart'; // [필수] LocaleProvider 임포트
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
        ), // [1] Provider 등록
      ],
      // [2] Consumer로 감싸야 언어가 바뀌었을 때 앱이 새로고침 됩니다!
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: '소셜매칭',
            debugShowCheckedModeBanner: false,

            // [3] Provider에서 현재 선택된 언어를 가져옴
            locale: localeProvider.locale,

            // [4] 다국어 설정
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko'), // 한국어
              Locale('en'), // 영어
              Locale('ja'), // [추가] 일본어
            ],

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6B4EFF),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: const CardThemeData(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 인증 상태 확인
        if (authProvider.isAuthenticated) {
          // 프로필이 로드되지 않았다면 로드
          if (authProvider.currentUserProfile == null &&
              !authProvider.isLoading) {
            Future.microtask(() => authProvider.loadUserProfile());
          }

          // 프로필이 있으면 홈 화면으로
          if (authProvider.currentUserProfile != null) {
            return const HomeScreen();
          }

          // 로딩 중
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 로그인하지 않은 경우 로그인 화면으로
        return const LoginScreen();
      },
    );
  }
}

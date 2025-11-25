import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
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
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: '소셜매칭',
        debugShowCheckedModeBanner: false,
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

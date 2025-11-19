import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 이메일 문의 보내기
  Future<void> _sendEmail(BuildContext context) async {
    // 대표님의 이메일 주소로 설정하세요
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com', // 대표님 이메일
      queryParameters: {
        'subject': '[블룸 문의] 앱 사용 관련 문의',
        'body': '사용 중인 기기: \n회원 ID: \n\n문의 내용:\n',
      },
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기본 메일 앱을 열 수 없습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '지원',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('문의하기 / 피드백 보내기'),
            subtitle: const Text('버그 제보나 건의사항을 보내주세요'),
            onTap: () => _sendEmail(context),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('서비스 이용약관'),
            onTap: () {
              // 나중에 웹뷰나 노션 페이지 연결
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '계정',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // 기존 로그아웃 로직 이동
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
          // 앱 버전 표시
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                '현재 버전 1.0.0 (Beta)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

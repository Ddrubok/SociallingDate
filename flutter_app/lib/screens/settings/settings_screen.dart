import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.supportSection,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.contactUs),
            subtitle: Text(l10n.contactUsSubtitle),
            onTap: () => _sendEmail(context),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(l10n.termsOfService),
            onTap: () {},
          ),
          const Divider(),

          // [수정] 언어 설정 (다이얼로그 내부 로직 개선)
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: Text(
              context.watch<LocaleProvider>().locale.languageCode == 'ko'
                  ? l10n.korean
                  : l10n.english,
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.selectLanguage),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // [수정] RadioListTile 사용 (Deprecated 해결)
                      RadioListTile<String>(
                        title: Text(l10n.korean),
                        value: 'ko',
                        groupValue: context
                            .read<LocaleProvider>()
                            .locale
                            .languageCode,
                        onChanged: (value) {
                          context.read<LocaleProvider>().setLocale(
                            const Locale('ko'),
                          );
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.english),
                        value: 'en',
                        groupValue: context
                            .read<LocaleProvider>()
                            .locale
                            .languageCode,
                        onChanged: (value) {
                          context.read<LocaleProvider>().setLocale(
                            const Locale('en'),
                          );
                          Navigator.pop(context);
                        },
                      ),

                      RadioListTile<String>(
                        title: const Text('日本語'), // "일본어"라고 써도 되고 "日本語"라고 써도 됨
                        value: 'ja',
                        groupValue: context
                            .read<LocaleProvider>()
                            .locale
                            .languageCode,
                        onChanged: (value) {
                          context.read<LocaleProvider>().setLocale(
                            const Locale('ja'),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.accountSection,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.logout),
                  content: Text(l10n.logoutConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.logout),
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
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Version 1.0.0 (Beta)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

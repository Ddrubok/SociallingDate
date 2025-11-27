import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 날짜 포맷
import 'package:flutter_app/l10n/app_localizations.dart'; // 번역
import '../../services/socialing_service.dart';
import '../../models/socialing_model.dart';
import 'socialing_create_screen.dart';
import 'socialing_detail_screen.dart'; // (아래 4단계에서 만듭니다)

class SocialingScreen extends StatefulWidget {
  const SocialingScreen({super.key});

  @override
  State<SocialingScreen> createState() => _SocialingScreenState();
}

class _SocialingScreenState extends State<SocialingScreen> {
  final SocialingService _socialingService = SocialingService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 현재 언어 코드 가져오기 (날짜 포맷용)
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.socialingTitle), // "소셜링"
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.createSocialing, // "모임 개설"
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SocialingCreateScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SocialingModel>>(
        stream: _socialingService.getSocialingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final socialings = snapshot.data ?? [];

          if (socialings.isEmpty) {
            return Center(
              child: Text(l10n.noConversations),
            ); // "아직 대화(모임)가 없습니다" 재활용
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: socialings.length,
            itemBuilder: (context, index) {
              final item = socialings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.socialingDate}: ${DateFormat.yMMMd(localeCode).add_jm().format(item.dateTime)}',
                      ),
                      Text('${l10n.socialingLocation}: ${item.location}'),
                      Text(
                        '${l10n.socialingMembers}: ${item.members.length} / ${item.maxMembers}',
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SocialingDetailScreen(socialing: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

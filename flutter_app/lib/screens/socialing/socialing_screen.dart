import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/socialing_model.dart';
import '../../services/socialing_service.dart';
import 'socialing_create_screen.dart';
import 'socialing_detail_screen.dart';

class SocialingScreen extends StatefulWidget {
  const SocialingScreen({super.key});

  @override
  State<SocialingScreen> createState() => _SocialingScreenState();
}

class _SocialingScreenState extends State<SocialingScreen> {
  final SocialingService _socialingService = SocialingService();

  // [수정] final 제거 (필터 변경 시 값을 바꿔야 하므로)
  String _currentFilter = 'all';

  // [추가] 카테고리 코드 -> 번역 텍스트 변환 헬퍼 함수
  String _getCategoryText(String code, AppLocalizations l10n) {
    if (code == 'all') return l10n.catAll;
    switch (code) {
      case 'small':
        return l10n.catSmall;
      case 'large':
        return l10n.catLarge;
      case 'oneday':
        return l10n.catOneDay;
      case 'weekend':
        return l10n.catWeekend;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    // 필터 리스트 ('all' + 나머지 카테고리 코드들)
    final filterList = ['all', ...SocialingModel.categories];

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
      body: Column(
        children: [
          // [상단] 카테고리 필터 (가로 스크롤)
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: filterList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final categoryCode = filterList[index];
                final isSelected = _currentFilter == categoryCode;
                return ChoiceChip(
                  label: Text(
                    _getCategoryText(categoryCode, l10n), // 번역된 텍스트 표시
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentFilter = categoryCode;
                      });
                    }
                  },
                );
              },
            ),
          ),

          // [목록] 소셜링 리스트
          Expanded(
            child: StreamBuilder<List<SocialingModel>>(
              // _currentFilter에 따라 데이터 필터링 ('all'이면 전체 조회)
              stream: _socialingService.getSocialingsStream(
                category: _currentFilter == 'all' ? null : _currentFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final socialings = snapshot.data ?? [];

                if (socialings.isEmpty) {
                  return Center(child: Text(l10n.noConversations));
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
                            // 카테고리 표시 (파란색 강조)
                            Text(
                              _getCategoryText(item.category, l10n),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // [필수] 실시간 업데이트용
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/socialing_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/socialing_service.dart';
import '../chat/chat_room_screen.dart';
import 'socialing_manage_screen.dart'; // 관리 화면

class SocialingDetailScreen extends StatefulWidget {
  final SocialingModel socialing; // 초기 데이터 (목록에서 넘어온 것)

  const SocialingDetailScreen({super.key, required this.socialing});

  @override
  State<SocialingDetailScreen> createState() => _SocialingDetailScreenState();
}

class _SocialingDetailScreenState extends State<SocialingDetailScreen> {
  final SocialingService _socialingService = SocialingService();
  bool _isLoading = false;

  String _getCategoryText(String code, AppLocalizations l10n) {
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

  Future<void> _handleJoin() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await _socialingService.joinSocialing(widget.socialing.sid, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.socialing.isApprovalRequired
                  ? l10n.applySent
                  : l10n.joinSuccess,
            ),
          ),
        );
        // [수정] setState 불필요 (StreamBuilder가 알아서 갱신함)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelApply() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await _socialingService.cancelApplication(widget.socialing.sid, userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("신청이 취소되었습니다.")));
      }
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToManageScreen(SocialingModel currentData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // [중요] 최신 데이터를 넘겨줘야 관리 화면도 최신 상태로 열림
        builder: (context) => SocialingManageScreen(socialing: currentData),
      ),
    );
  }

  void _enterChat(SocialingModel currentData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          roomId: currentData.chatRoomId,
          otherUserName: currentData.title,
          otherUserId: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final userId = context.watch<AuthProvider>().currentUserId;

    // [핵심 수정] StreamBuilder로 감싸서 실시간 데이터 구독
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('socialings')
          .doc(widget.socialing.sid)
          .snapshots(),
      builder: (context, snapshot) {
        // 데이터가 로딩 중이거나 에러가 나면 기존 데이터(widget.socialing)를 보여줌 (깜빡임 방지)
        SocialingModel displayData = widget.socialing;

        if (snapshot.hasData && snapshot.data!.exists) {
          // 최신 데이터로 덮어쓰기
          displayData = SocialingModel.fromFirestore(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );
        }

        // 상태 판단 (최신 데이터 기준)
        final isHost = displayData.hostId == userId;
        final isMember = displayData.members.contains(userId);
        final isApplicant = displayData.applicants.contains(userId);
        final isFull = displayData.members.length >= displayData.maxMembers;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.socialingTitle),
            actions: [
              if (isHost)
                IconButton(
                  icon: const Icon(Icons.manage_accounts),
                  tooltip: l10n.manageMembers,
                  // 최신 데이터를 넘겨줌
                  onPressed: () => _goToManageScreen(displayData),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: displayData.imageUrl.isNotEmpty
                      ? Image.network(displayData.imageUrl, fit: BoxFit.cover)
                      : Icon(Icons.groups, size: 80, color: Colors.grey[400]),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              _getCategoryText(displayData.category, l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            side: BorderSide.none,
                          ),
                          ...displayData.tags.map(
                            (tag) => Chip(
                              label: Text('#$tag'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              side: BorderSide.none,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        displayData.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      _InfoRow(
                        icon: Icons.calendar_today,
                        text: DateFormat.yMMMd(
                          localeCode,
                        ).add_jm().format(displayData.dateTime),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.location_on,
                        text: displayData.location,
                      ),
                      const SizedBox(height: 12),
                      // 인원수도 실시간 반영됨
                      _InfoRow(
                        icon: Icons.people,
                        text:
                            '${l10n.socialingMembers} ${displayData.members.length} / ${displayData.maxMembers}',
                      ),

                      const Divider(height: 48),

                      Text(
                        displayData.content,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBottomButton(
                l10n,
                isHost,
                isMember,
                isApplicant,
                isFull,
                displayData,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(
    AppLocalizations l10n,
    bool isHost,
    bool isMember,
    bool isApplicant,
    bool isFull,
    SocialingModel currentData,
  ) {
    if (_isLoading) {
      return ElevatedButton(
        onPressed: null,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (isMember || isHost) {
      return ElevatedButton(
        onPressed: () => _enterChat(currentData),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          l10n.startChat,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (isApplicant) {
      return ElevatedButton(
        onPressed: _cancelApply,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "${l10n.waitingApproval} (${l10n.cancelApply})",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (isFull) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          l10n.socialingFull,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _handleJoin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        currentData
                .isApprovalRequired // 최신 데이터의 승인 여부 확인
            ? l10n.applyJoin
            : l10n.socialingJoin,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}

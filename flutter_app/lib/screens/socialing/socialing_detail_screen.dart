import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/socialing_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/socialing_service.dart';
import '../chat/chat_room_screen.dart';
// import 'socialing_manage_screen.dart'; // [예고] 다음 단계에서 만들 파일

class SocialingDetailScreen extends StatefulWidget {
  final SocialingModel socialing;

  const SocialingDetailScreen({super.key, required this.socialing});

  @override
  State<SocialingDetailScreen> createState() => _SocialingDetailScreenState();
}

class _SocialingDetailScreenState extends State<SocialingDetailScreen> {
  final SocialingService _socialingService = SocialingService();
  bool _isLoading = false;

  // 카테고리 코드 -> 번역 텍스트 변환
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

  // [1] 참여 신청 (승인제) or 참여 (선착순)
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
                  ? l10n
                        .applySent // "신청을 보냈습니다."
                  : l10n.joinSuccess,
            ), // "참여했습니다."
          ),
        );
        setState(() {}); // 화면 갱신
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

  // [2] 신청 취소
  Future<void> _cancelApply() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await _socialingService.cancelApplication(widget.socialing.sid, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("신청이 취소되었습니다.")),
        ); // 다국어 적용 필요 시 l10n 추가
        setState(() {});
      }
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [3] 관리 화면 이동 (호스트 전용)
  void _goToManageScreen() {
    // TODO: 다음 단계에서 SocialingManageScreen으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("다음 단계에서 '멤버 관리 화면'을 만듭니다! 🛠️")),
    );
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocialingManageScreen(socialing: widget.socialing),
      ),
    ).then((_) => setState(() {})); // 돌아왔을 때 새로고침
    */
  }

  // 채팅방 입장
  void _enterChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          roomId: widget.socialing.chatRoomId,
          otherUserName: widget.socialing.title,
          otherUserId: '', // 그룹 채팅
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final userId = context.watch<AuthProvider>().currentUserId;

    // --- [핵심] 상태 판단 로직 ---
    final isHost = widget.socialing.hostId == userId;
    final isMember = widget.socialing.members.contains(userId);
    final isApplicant = widget.socialing.applicants.contains(userId);
    final isFull =
        widget.socialing.members.length >= widget.socialing.maxMembers;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.socialingTitle),
        actions: [
          // [호스트 전용] 관리 버튼
          if (isHost)
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: l10n.manageMembers, // "참여자 관리"
              onPressed: _goToManageScreen,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지
            Container(
              height: 200,
              color: Colors.grey[200],
              child: widget.socialing.imageUrl.isNotEmpty
                  ? Image.network(widget.socialing.imageUrl, fit: BoxFit.cover)
                  : Icon(Icons.groups, size: 80, color: Colors.grey[400]),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 칩
                  Chip(
                    label: Text(
                      _getCategoryText(widget.socialing.category, l10n),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide.none,
                  ),
                  const SizedBox(height: 12),

                  // 제목
                  Text(
                    widget.socialing.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 정보
                  _InfoRow(
                    icon: Icons.calendar_today,
                    text: DateFormat.yMMMd(
                      localeCode,
                    ).add_jm().format(widget.socialing.dateTime),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on,
                    text: widget.socialing.location,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.people,
                    text:
                        '${l10n.socialingMembers} ${widget.socialing.members.length} / ${widget.socialing.maxMembers}',
                  ),

                  const Divider(height: 48),

                  // 내용
                  Text(
                    widget.socialing.content,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // [하단 버튼] 상태에 따라 다르게 표시
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBottomButton(
            l10n,
            isHost,
            isMember,
            isApplicant,
            isFull,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    AppLocalizations l10n,
    bool isHost,
    bool isMember,
    bool isApplicant,
    bool isFull,
  ) {
    // 1. 로딩 중
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

    // 2. 이미 멤버이거나 호스트 -> 채팅방 입장
    if (isMember || isHost) {
      return ElevatedButton(
        onPressed: _enterChat,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          l10n.startChat, // "채팅하기"
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    // 3. 신청 대기 중 -> 신청 취소
    if (isApplicant) {
      return ElevatedButton(
        onPressed: _cancelApply,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.orange, // 대기 상태 색상
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "${l10n.waitingApproval} (${l10n.cancelApply})", // "승인 대기 중 (취소)"
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    // 4. 모집 마감
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
          l10n.socialingFull, // "모집 마감"
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    // 5. 참여 신청 (기본)
    return ElevatedButton(
      onPressed: _handleJoin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        widget.socialing.isApprovalRequired
            ? l10n
                  .applyJoin // "참여 신청"
            : l10n.socialingJoin, // "참여하기"
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// 정보 표시용 위젯 (기존 유지)
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

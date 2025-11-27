import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/socialing_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/socialing_service.dart';
import '../chat/chat_room_screen.dart';

class SocialingDetailScreen extends StatefulWidget {
  final SocialingModel socialing;

  const SocialingDetailScreen({super.key, required this.socialing});

  @override
  State<SocialingDetailScreen> createState() => _SocialingDetailScreenState();
}

class _SocialingDetailScreenState extends State<SocialingDetailScreen> {
  final SocialingService _socialingService = SocialingService();
  bool _isLoading = false;

  // 모임 참여 처리
  Future<void> _handleJoin() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await _socialingService.joinSocialing(widget.socialing.sid, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.joinSuccess)), // "모임에 참여했습니다."
        );
        // 참여 후 바로 채팅방으로 이동? 아니면 새로고침?
        // 여기서는 일단 UI 갱신을 위해 화면을 닫았다가 다시 열거나,
        // setState로 상태만 바꿔줄 수 있습니다. (StreamBuilder로 감싸면 자동 갱신됨)
        // 간단히 뒤로 가기: Navigator.pop(context);
        // 또는 그대로 유지 (아래 build에서 상태 반영됨)
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

  // 그룹 채팅방 입장
  void _enterChat() {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          roomId: widget.socialing.chatRoomId,
          otherUserName: widget.socialing.title, // 그룹 채팅방 이름 = 모임 제목
          otherUserId: '', // 그룹 채팅이므로 특정 상대 ID 없음 (빈 문자열 처리)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final userId = context.watch<AuthProvider>().currentUserId;

    // 내가 참여 중인지 확인
    final isJoined = widget.socialing.members.contains(userId);
    // 만석인지 확인
    final isFull =
        widget.socialing.members.length >= widget.socialing.maxMembers;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialingTitle)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [1] 대표 이미지 (없으면 기본 아이콘)
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
                  // [2] 태그 & 제목
                  if (widget.socialing.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: widget.socialing.tags
                          .map(
                            (tag) => Chip(
                              label: Text('#$tag'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.socialing.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // [3] 정보 (일시, 장소, 인원)
                  _InfoRow(
                    icon: Icons.calendar_today,
                    text: DateFormat.yMMMd(
                      localeCode,
                    ).add_jm().format(widget.socialing.dateTime),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on,
                    text: widget.socialing.location,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.people,
                    text:
                        '${l10n.socialingMembers} ${widget.socialing.members.length} / ${widget.socialing.maxMembers}',
                  ),

                  const Divider(height: 32),

                  // [4] 내용
                  Text(
                    widget.socialing.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // [5] 하단 버튼 (참여하기 / 채팅방 입장 / 마감)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (isJoined
                      ? _enterChat // 이미 참여 -> 채팅방 입장
                      : (isFull ? null : _handleJoin)), // 미참여 -> 만석 아니면 참여
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isJoined
                  ? Colors.green
                  : (isFull
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isJoined
                        ? l10n
                              .startChat // "채팅하기" (또는 "입장하기")
                        : (isFull
                              ? l10n.socialingFull
                              : l10n.socialingJoin), // "마감" or "참여하기"
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// 정보 표시용 작은 위젯
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/socialing_model.dart';
import '../../models/user_model.dart';
import '../../services/socialing_service.dart';
import '../../services/user_service.dart';
import '../profile/user_profile_screen.dart';

class SocialingManageScreen extends StatefulWidget {
  final SocialingModel socialing;

  const SocialingManageScreen({super.key, required this.socialing});

  @override
  State<SocialingManageScreen> createState() => _SocialingManageScreenState();
}

class _SocialingManageScreenState extends State<SocialingManageScreen> {
  final SocialingService _socialingService = SocialingService();
  final UserService _userService = UserService();

  List<UserModel> _applicants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  // 신청자 목록(UID 리스트)을 가지고 실제 유저 정보 불러오기
  Future<void> _loadApplicants() async {
    setState(() => _isLoading = true);
    try {
      final List<UserModel> loadedUsers = [];
      for (String uid in widget.socialing.applicants) {
        final user = await _userService.getUser(uid);
        if (user != null) {
          loadedUsers.add(user);
        }
      }

      if (mounted) {
        setState(() {
          _applicants = loadedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 승인 처리
  Future<void> _approve(String applicantId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _socialingService.approveApplicant(
        widget.socialing.sid,
        applicantId,
      );

      // 리스트에서 제거 (UI 갱신)
      setState(() {
        _applicants.removeWhere((user) => user.uid == applicantId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.approveSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 에러 처리
    }
  }

  // 거절 처리
  Future<void> _reject(String applicantId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _socialingService.rejectApplicant(
        widget.socialing.sid,
        applicantId,
      );

      setState(() {
        _applicants.removeWhere((user) => user.uid == applicantId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rejectSuccess),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 에러 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageMembers), // "참여자 관리"
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applicants.isEmpty
          ? Center(
              child: Text(
                l10n.noApplicants, // "아직 신청자가 없습니다."
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _applicants.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = _applicants[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  // 프로필 사진 클릭 시 상세 프로필로 이동 (검증용)
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(user: user),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(user.profileImageUrl),
                    ),
                  ),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${user.age}세 · ${user.gender == 'male' ? l10n.male : l10n.female}\n매너온도 ${user.mannerScore}°',
                    style: const TextStyle(fontSize: 12),
                  ),
                  // 승인/거절 버튼
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _reject(user.uid),
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: l10n.reject,
                      ),
                      IconButton(
                        onPressed: () => _approve(user.uid),
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: l10n.approve,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

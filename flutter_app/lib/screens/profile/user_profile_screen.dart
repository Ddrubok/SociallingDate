import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../chat/chat_room_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  bool _isBlocked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
  }

  void _checkIfBlocked() {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser != null &&
        currentUser.blockedUsers.contains(widget.user.uid)) {
      setState(() {
        _isBlocked = true;
      });
    }
  }

  // [1] 친구 요청 보내기
  Future<void> _sendFriendRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _userService.sendFriendRequest(currentUser.uid, widget.user.uid);
      // 내 정보 갱신 (보낸 요청 목록 업데이트)
      if (mounted) await context.read<AuthProvider>().loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendRequestSent)));
      }
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [2] 요청 취소
  Future<void> _cancelRequest() async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _userService.cancelFriendRequest(currentUser.uid, widget.user.uid);
      if (mounted) await context.read<AuthProvider>().loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("요청이 취소되었습니다.")));
      }
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [3] 요청 수락
  Future<void> _acceptRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _userService.acceptFriendRequest(currentUser.uid, widget.user.uid);
      if (mounted) await context.read<AuthProvider>().loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requestAccepted)));
      }
    } catch (e) {
      // error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 채팅방 입장
  Future<void> _startChat() async {
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    try {
      final roomId = await _chatService.createOrGetChatRoom(
        currentUserId: currentUser.uid,
        otherUserId: widget.user.uid,
        currentUserName: currentUser.displayName,
        otherUserName: widget.user.displayName,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            roomId: roomId,
            otherUserName: widget.user.displayName,
            otherUserId: widget.user.uid,
          ),
        ),
      );
    } catch (e) {
      // error
    }
  }

  Future<void> _showReportDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportUser),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: l10n.reportReasonHint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await _userService.reportUser(
                  reporterId: currentUser.uid,
                  reportedUserId: widget.user.uid,
                  reason: reasonController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
                }
              } catch (e) {
                // error
              }
            },
            child: Text(l10n.report),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlock() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().currentUserProfile;
    if (currentUser == null) return;

    try {
      if (_isBlocked) {
        await _userService.unblockUser(currentUser.uid, widget.user.uid);
      } else {
        await _userService.blockUser(currentUser.uid, widget.user.uid);
      }
      if (mounted) {
        setState(() => _isBlocked = !_isBlocked);
        await context.read<AuthProvider>().loadUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBlocked ? l10n.userBlocked : l10n.userUnblocked),
          ),
        );
      }
    } catch (e) {
      // error
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 실시간 업데이트를 위해 watch 사용
    final currentUser = context.watch<AuthProvider>().currentUserProfile;

    final isFriend = currentUser?.matches.contains(widget.user.uid) ?? false;
    final hasSentRequest =
        currentUser?.friendRequestsSent.any(
          (req) => req['targetUserId'] == widget.user.uid,
        ) ??
        false;
    final hasReceivedRequest =
        currentUser?.friendRequestsReceived.any(
          (req) => req['senderId'] == widget.user.uid,
        ) ??
        false;

    return Scaffold(
      backgroundColor: Colors.grey[50], // 배경색 약간 어둡게
      appBar: AppBar(
        title: Text(l10n.userProfileTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') _showReportDialog();
              if (value == 'block') _toggleBlock();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'report', child: Text(l10n.report)),
              PopupMenuItem(
                value: 'block',
                child: Text(_isBlocked ? l10n.unblock : l10n.block),
              ),
            ],
          ),
        ],
      ),
      // body가 앱바 영역까지 올라가도록 설정
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        // 상단 여백 추가
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
          bottom: 100, // 하단 버튼 공간 확보
          left: 24,
          right: 24,
        ),
        child: Column(
          // [핵심] 수평 방향 중앙 정렬
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 상단 프로필 정보 ---
            Center(
              child: CircleAvatar(
                radius: 70, // 사진 크기 확대
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(widget.user.profileImageUrl),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.user.displayName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // 나이, 위치, 인증 뱃지 (Row도 중앙 정렬)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.user.authStatus == 'verified') ...[
                  Icon(Icons.verified, size: 22, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                ],
                Text(
                  '${widget.user.age}세 · ${widget.user.location}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 매너온도 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // 내용물만큼만 크기 차지
                children: [
                  Icon(Icons.favorite, color: Colors.pink[300], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.mannerTemperature} ${widget.user.mannerScore.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: Colors.pink[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- 상세 정보 카드 섹션 ---
            Card(
              elevation: 0, // 그림자 제거 (깔끔하게)
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 1. 자기소개
                    Text(
                      l10n.bioLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.user.bio.isNotEmpty ? widget.user.bio : l10n.noBio,
                      style: TextStyle(
                        color: widget.user.bio.isNotEmpty
                            ? Colors.black87
                            : Colors.grey[500],
                        fontSize: 16,
                        height: 1.5, // 줄 간격
                      ),
                      textAlign: TextAlign.center, // 텍스트 중앙 정렬
                    ),

                    const Divider(height: 48, thickness: 1), // 구분선
                    // 2. 관심사/취미
                    Text(
                      l10n.interestsLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    widget.user.interests.isEmpty
                        ? Text(
                            l10n.noInterests,
                            style: TextStyle(color: Colors.grey[500]),
                          )
                        : Wrap(
                            spacing: 10, // 가로 간격
                            runSpacing: 10, // 세로 간격
                            alignment: WrapAlignment.center, // 칩들 중앙 정렬
                            children: widget.user.interests.map((interest) {
                              return Chip(
                                label: Text(interest),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                                side: BorderSide.none, // 테두리 없음
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 하단 액션 버튼 (기존 로직 유지)
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), // 하단 여백 확보
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ), // 상단 둥글게
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: _buildActionButton(
          l10n,
          isFriend,
          hasSentRequest,
          hasReceivedRequest,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    AppLocalizations l10n,
    bool isFriend,
    bool hasSentRequest,
    bool hasReceivedRequest,
  ) {
    // (기존 버튼 빌드 로직과 동일하지만 스타일만 약간 수정)
    if (_isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(),
        ),
      );
    }

    ButtonStyle commonStyle(Color bgColor) => ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // 버튼 둥글게
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      elevation: 0,
    );

    if (isFriend) {
      return ElevatedButton.icon(
        onPressed: _startChat,
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(l10n.startChat),
        style: commonStyle(Colors.green),
      );
    }
    if (hasSentRequest) {
      return ElevatedButton(
        onPressed: _cancelRequest,
        style: commonStyle(Colors.grey[400]!),
        child: Text(l10n.cancelFriendRequest),
      );
    }
    if (hasReceivedRequest) {
      return ElevatedButton(
        onPressed: _acceptRequest,
        style: commonStyle(Colors.blue),
        child: Text(l10n.acceptFriendRequest),
      );
    }
    return ElevatedButton.icon(
      onPressed: _isBlocked ? null : _sendFriendRequest,
      icon: const Icon(Icons.person_add_alt_1),
      label: Text(l10n.sendFriendRequest),
      style: commonStyle(Theme.of(context).colorScheme.primary),
    );
  }
}

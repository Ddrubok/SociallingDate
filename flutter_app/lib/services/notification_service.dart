import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // [수정] Material만 있으면 충분
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // [삭제] 안 씀
import '../screens/chat/chat_list_screen.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('알림 권한 허용됨');

      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    } else {
      debugPrint('알림 권한 거부됨');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM 토큰 저장 완료: $token');
    } catch (e) {
      debugPrint('토큰 저장 실패: $e');
    }
  }

  Future<void> setupInteractedMessage(BuildContext context) async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();

    // [수정] async 작업 후 mounted 체크
    if (!context.mounted) return;

    if (initialMessage != null) {
      _handleMessage(context, initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // 여기서도 context가 유효한지 체크하면 좋지만,
      // 리스너 콜백이라 mounted 확인이 애매하므로 try-catch 등으로 안전장치 마련 가능.
      // 일반적으론 앱이 켜져 있을 때라 괜찮습니다.
      if (context.mounted) {
        _handleMessage(context, message);
      }
    });
  }

  void _handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['roomId'] != null) {
      debugPrint('알림 클릭: 채팅방 ID ${message.data['roomId']}');

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatListScreen()),
      );
    }
  }
}

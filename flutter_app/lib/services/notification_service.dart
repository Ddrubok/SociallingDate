import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../screens/chat/chat_list_screen.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 초기화
  Future<void> initialize() async {
    // 1. 권한 요청
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('알림 권한 허용됨');

      // 2. 토큰 발급 및 저장
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // 3. 토큰 리프레시 감지 (앱 삭제 후 재설치 등)
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    } else {
      debugPrint('알림 권한 거부됨');
    }
  }

  // Firestore에 토큰 저장
  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token, // 사용자 문서에 토큰 저장
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM 토큰 저장 완료: $token');
    } catch (e) {
      debugPrint('토큰 저장 실패: $e');
    }
  }

  Future<void> setupInteractedMessage(BuildContext context) async {
    // 1. 앱이 완전히 꺼진 상태에서 알림을 클릭해 열었을 때
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(context, initialMessage);
    }

    // 2. 앱이 백그라운드(홈화면)에 있을 때 알림을 클릭했을 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(context, message);
    });
  }

  void _handleMessage(BuildContext context, RemoteMessage message) {
    // 알림 데이터에 roomId가 있다면 채팅 목록으로 이동
    if (message.data['roomId'] != null) {
      debugPrint('알림 클릭: 채팅방 ID ${message.data['roomId']}');

      // 바로 채팅방으로 가면 유저 정보가 없어서 에러가 날 수 있으므로,
      // 안전하게 '채팅 목록' 화면으로 이동시킵니다.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatListScreen()),
      );
    }
  }
}

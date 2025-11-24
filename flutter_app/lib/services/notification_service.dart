import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
}

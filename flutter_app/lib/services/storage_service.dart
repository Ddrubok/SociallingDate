import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// 사용자에게 갤러리 또는 카메라 선택을 요청하는 다이얼로그를 표시합니다.
  Future<File?> pickImage(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// 선택된 이미지 파일을 Firebase Storage에 업로드하고 다운로드 URL을 반환합니다.
  /// [userId]는 이미지 경로를 고유하게 식별하는 데 사용됩니다.
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // 업로드 경로: /profile_images/{userId}/profile.jpg
      // 이렇게 하면 사용자가 프로필 사진을 변경할 때마다 덮어쓰게 됩니다.
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('profile.jpg');

      // 이미지 메타데이터 설정 (필수)
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // 파일 업로드
      final uploadTask = await ref.putFile(imageFile, metadata);

      // 업로드 완료 후 다운로드 URL 반환
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Firebase 관련 오류 처리
      debugPrint('Firebase Storage 오류: $e');
      rethrow;
    } catch (e) {
      // 기타 오류 처리
      debugPrint('이미지 업로드 오류: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';
import '../models/socialing_model.dart';

class SocialingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  Future<void> createSocialing({
    required String hostId,
    required String title,
    required String content,
    required String location,
    required DateTime dateTime,
    required int maxMembers,
    required List<String> tags,
    required String category,
    String? imageUrl,
  }) async {
    try {
      final chatRoomId = await _chatService.createGroupChat(
        hostId: hostId,
        groupTitle: title,
        initialMessage: '모임이 개설되었습니다! 👋',
      );

      await _firestore.collection('socialings').add({
        'hostId': hostId,
        'title': title,
        'content': content,
        'imageUrl': imageUrl ?? '',
        'location': location,
        'dateTime': Timestamp.fromDate(dateTime),
        'maxMembers': maxMembers,
        'members': [hostId],
        'tags': tags,
        'chatRoomId': chatRoomId,
        'createdAt': FieldValue.serverTimestamp(),
        'category': category,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinSocialing(String socialingId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('socialings').doc(socialingId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception("모임이 존재하지 않습니다.");

        final data = snapshot.data()!;
        final currentMembers = List<String>.from(data['members'] ?? []);
        final maxMembers = data['maxMembers'] as int;
        final chatRoomId = data['chatRoomId'] as String;

        if (currentMembers.contains(userId)) {
          return;
        }

        if (currentMembers.length >= maxMembers) {
          throw Exception("모집 인원이 마감되었습니다.");
        }

        transaction.update(docRef, {
          'members': FieldValue.arrayUnion([userId]),
        });

        final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
        transaction.update(chatRoomRef, {
          'participants': FieldValue.arrayUnion([userId]),
          'unreadCount.$userId': 0,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<SocialingModel>> getSocialingsStream({String? category}) {
    Query query = _firestore.collection('socialings');

    if (category != null && category != '전체') {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => SocialingModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    });
  }
}

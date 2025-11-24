const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// 채팅 메시지가 생성되면(onCreate) 자동으로 실행되는 함수
exports.sendChatNotification = functions.firestore
    .document("chat_rooms/{roomId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        const roomId = context.params.roomId;
        const senderId = messageData.senderId;
        const text = messageData.text;

        try {
            // 1. 채팅방 정보 가져오기 (참여자 목록 확인)
            const roomDoc = await admin.firestore().collection("chat_rooms").doc(roomId).get();

            if (!roomDoc.exists) {
                console.log("Chat room not found");
                return null;
            }

            const participants = roomDoc.data().participants; // [userId1, userId2]
            const names = roomDoc.data().participantNames;

            // 2. 수신자(나 말고 다른 사람) 찾기
            const receiverId = participants.find((uid) => uid !== senderId);
            if (!receiverId) return null;

            // 3. 수신자의 FCM 토큰(핸드폰 주소) 가져오기
            const userDoc = await admin.firestore().collection("users").doc(receiverId).get();

            if (!userDoc.exists) return null;

            const fcmToken = userDoc.data().fcmToken;

            if (!fcmToken) {
                console.log("No FCM token for user:", receiverId);
                return null;
            }

            // 4. 알림 메시지 내용 구성
            const senderName = (names && names[senderId]) ? names[senderId] : "알 수 없음";

            const payload = {
                notification: {
                    title: senderName,
                    body: text,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    roomId: roomId, // 알림 클릭 시 이동할 방 ID
                },
            };

            // 5. 진짜로 알림 발송!
            console.log(`Sending notification to: ${receiverId}`);
            return admin.messaging().sendToDevice(fcmToken, payload);

        } catch (error) {
            console.error("Error sending notification:", error);
            return null;
        }
    });
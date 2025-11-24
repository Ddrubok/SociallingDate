// [수정] v1 문법 사용 명시
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
            // 1. 채팅방 정보 가져오기
            const roomDoc = await admin.firestore().collection("chat_rooms").doc(roomId).get();

            if (!roomDoc.exists) {
                console.log("Chat room not found");
                return null;
            }

            const participants = roomDoc.data().participants;
            const names = roomDoc.data().participantNames;

            // 2. 수신자 찾기
            const receiverId = participants.find((uid) => uid !== senderId);
            if (!receiverId) return null;

            // 3. 수신자의 FCM 토큰 가져오기
            const userDoc = await admin.firestore().collection("users").doc(receiverId).get();

            if (!userDoc.exists) return null;

            const fcmToken = userDoc.data().fcmToken;

            if (!fcmToken) {
                console.log("No FCM token for user:", receiverId);
                return null;
            }

            // 4. [수정] 알림 메시지 구성 (최신 send 메서드 양식)
            const senderName = (names && names[senderId]) ? names[senderId] : "알 수 없음";

            const message = {
                token: fcmToken, // 토큰을 메시지 객체 안에 넣습니다.
                notification: {
                    title: senderName,
                    body: text,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    roomId: roomId,
                },
                // 안드로이드 추가 설정 (중요)
                android: {
                    priority: 'high',
                    notification: {
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    }
                },
                // iOS 추가 설정 (선택 사항)
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                        },
                    },
                },
            };

            // 5. [수정] 알림 발송 (sendToDevice -> send)
            console.log(`Sending notification to: ${receiverId}`);
            return admin.messaging().send(message);

        } catch (error) {
            console.error("Error sending notification:", error);
            return null;
        }
    });
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// 1. [기존] 채팅 알림
exports.sendChatNotification = functions.firestore
    .document("chat_rooms/{roomId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        const roomId = context.params.roomId;
        const senderId = messageData.senderId;
        const text = messageData.text;

        try {
            const roomDoc = await admin.firestore().collection("chat_rooms").doc(roomId).get();
            if (!roomDoc.exists) return null;

            const participants = roomDoc.data().participants;
            const receiverId = participants.find((uid) => uid !== senderId);
            if (!receiverId) return null;

            const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
            if (!userDoc.exists) return null;

            const fcmToken = userDoc.data().fcmToken;
            if (!fcmToken) return null;

            // 이름 가져오기 (채팅방에 이름 정보가 없다면 senderId로 조회)
            let senderName = "알 수 없음";
            const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
            if (senderDoc.exists) {
                senderName = senderDoc.data().displayName;
            }

            const message = {
                token: fcmToken,
                notification: {
                    title: senderName,
                    body: text,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    roomId: roomId,
                },
                android: { priority: 'high' },
                apns: { payload: { aps: { sound: 'default' } } },
            };

            return admin.messaging().send(message);
        } catch (error) {
            console.error("Error sending chat notification:", error);
            return null;
        }
    });

// 2. [신규] 좋아요 & 매칭 알림
exports.sendUserUpdateNotification = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const userId = context.params.userId; // 알림 받을 사람 (나)

        const fcmToken = afterData.fcmToken;
        if (!fcmToken) return null;

        try {
            // (A) '받은 좋아요(receivedLikes)'가 늘어났는지 확인
            const beforeLikes = beforeData.receivedLikes || [];
            const afterLikes = afterData.receivedLikes || [];

            if (afterLikes.length > beforeLikes.length) {
                // 새로 추가된 좋아요 찾기
                const newLikerId = afterLikes.find(id => !beforeLikes.includes(id));

                if (newLikerId) {
                    // 좋아요 보낸 사람 이름 가져오기
                    const likerDoc = await admin.firestore().collection("users").doc(newLikerId).get();
                    const likerName = likerDoc.exists ? likerDoc.data().displayName : "누군가";

                    const message = {
                        token: fcmToken,
                        notification: {
                            title: "설레는 소식! 💘",
                            body: `${likerName}님이 회원님을 좋아합니다!`,
                        },
                        data: {
                            click_action: "FLUTTER_NOTIFICATION_CLICK",
                            type: "like", // 앱에서 구분 가능
                        },
                        android: { priority: 'high' },
                    };
                    console.log(`Sending LIKE notification to ${userId}`);
                    return admin.messaging().send(message);
                }
            }

            // (B) '매칭(matches)'이 늘어났는지 확인
            const beforeMatches = beforeData.matches || [];
            const afterMatches = afterData.matches || [];

            if (afterMatches.length > beforeMatches.length) {
                // 새로 매칭된 상대 찾기
                const newMatchId = afterMatches.find(id => !beforeMatches.includes(id));

                if (newMatchId) {
                    const matchDoc = await admin.firestore().collection("users").doc(newMatchId).get();
                    const matchName = matchDoc.exists ? matchDoc.data().displayName : "상대방";

                    const message = {
                        token: fcmToken,
                        notification: {
                            title: "매칭 성공! 🎉",
                            body: `${matchName}님과 연결되었습니다. 대화를 시작해보세요!`,
                        },
                        data: {
                            click_action: "FLUTTER_NOTIFICATION_CLICK",
                            type: "match",
                        },
                        android: { priority: 'high' },
                    };
                    console.log(`Sending MATCH notification to ${userId}`);
                    return admin.messaging().send(message);
                }
            }

            return null;
        } catch (error) {
            console.error("Error sending user notification:", error);
            return null;
        }
    });
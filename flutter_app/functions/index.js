const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// 🌍 1. 서버용 번역 사전 (Server-side Localization)
const MESSAGES = {
    ko: {
        friendReqTitle: "친구 요청 도착! 💌",
        friendReqBody: (name) => `${name}님이 친구가 되고 싶어 해요.`,
        matchTitle: "매칭 성공! 🎉",
        matchBody: (name) => `${name}님과 친구가 되었습니다.`,
        likeTitle: "설레는 소식! 💘",
        likeBody: "누군가 회원님을 좋아합니다!",
        applyTitle: "새로운 참여 신청! 🙋‍♂️",
        applyBody: (title, name) => `'${title}' 모임에 ${name}님이 신청했습니다.`,
        approveTitle: "참여 승인 완료! 🎫",
        approveBody: (title) => `'${title}' 모임 참여가 승인되었습니다.`,
        groupChat: "그룹 채팅",
        unknown: "알 수 없음"
    },
    en: {
        friendReqTitle: "Friend Request! 💌",
        friendReqBody: (name) => `${name} wants to be friends.`,
        matchTitle: "It's a Match! 🎉",
        matchBody: (name) => `You are now friends with ${name}.`,
        likeTitle: "Exciting News! 💘",
        likeBody: "Someone likes you!",
        applyTitle: "New Application! 🙋‍♂️",
        applyBody: (title, name) => `${name} applied to '${title}'.`,
        approveTitle: "Approved! 🎫",
        approveBody: (title) => `You joined '${title}'.`,
        groupChat: "Group Chat",
        unknown: "Unknown"
    },
    ja: {
        friendReqTitle: "友達申請！💌",
        friendReqBody: (name) => `${name}さんが友達になりたがっています。`,
        matchTitle: "マッチング成功！🎉",
        matchBody: (name) => `${name}さんと友達になりました。`,
        likeTitle: "ドキドキ！💘",
        likeBody: "誰かがあなたにいいねしました！",
        applyTitle: "新しい参加申請！🙋‍♂️",
        applyBody: (title, name) => `'${title}'に${name}さんが申請しました。`,
        approveTitle: "承認完了！🎫",
        approveBody: (title) => `'${title}'への参加が承認されました。`,
        groupChat: "グループチャット",
        unknown: "不明"
    }
};

// 헬퍼 함수: 언어 코드에 맞는 텍스트 가져오기 (기본값: ko)
const getMsg = (lang, key) => {
    const code = (lang && MESSAGES[lang]) ? lang : 'ko';
    return MESSAGES[code][key] || MESSAGES['ko'][key];
};

// ---------------------------------------------------------
// 2. 채팅 알림
// ---------------------------------------------------------
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

            const roomData = roomDoc.data();
            const participants = roomData.participants || [];
            const isGroup = roomData.type === 'group';

            let senderName = "User";
            const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
            if (senderDoc.exists) senderName = senderDoc.data().displayName;

            const receivers = participants.filter(uid => uid !== senderId);

            const promises = receivers.map(async (receiverId) => {
                const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
                const userData = userDoc.data();
                if (!userData || !userData.fcmToken) return;

                // 받는 사람의 언어 확인
                const lang = userData.languageCode || 'ko';

                // 제목 설정 (그룹 채팅이면 번역된 '그룹 채팅', 아니면 보낸 사람 이름)
                const title = isGroup
                    ? (roomData.title || getMsg(lang, 'groupChat'))
                    : senderName;

                const message = {
                    token: userData.fcmToken,
                    notification: { title: title, body: isGroup ? `${senderName}: ${text}` : text },
                    data: { click_action: "FLUTTER_NOTIFICATION_CLICK", roomId: roomId },
                    android: { priority: 'high' },
                    apns: { payload: { aps: { sound: 'default' } } },
                };
                return admin.messaging().send(message);
            });

            return Promise.all(promises);
        } catch (error) {
            console.error("Error sending chat notification:", error);
            return null;
        }
    });

// ---------------------------------------------------------
// 3. 유저 관련 알림 (좋아요, 매칭, 친구 요청)
// ---------------------------------------------------------
exports.sendUserUpdateNotification = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
        const afterData = change.after.data();
        const beforeData = change.before.data();

        // 받는 사람 정보
        const fcmToken = afterData.fcmToken;
        const lang = afterData.languageCode || 'ko'; // 언어 확인

        if (!fcmToken) return null;

        try {
            // (A) 친구 요청 받음
            const beforeReqs = beforeData.friendRequestsReceived || [];
            const afterReqs = afterData.friendRequestsReceived || [];

            if (afterReqs.length > beforeReqs.length) {
                const newReq = afterReqs.find(req => !beforeReqs.some(old => old.senderId === req.senderId));
                if (newReq) {
                    const senderDoc = await admin.firestore().collection("users").doc(newReq.senderId).get();
                    const senderName = senderDoc.exists ? senderDoc.data().displayName : getMsg(lang, 'unknown');

                    // 번역된 메시지 사용
                    await admin.messaging().send({
                        token: fcmToken,
                        notification: {
                            title: getMsg(lang, 'friendReqTitle'),
                            body: getMsg(lang, 'friendReqBody')(senderName),
                        },
                        data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "friend_request" },
                        android: { priority: 'high' }
                    });
                }
            }

            // (B) 매칭 성사
            const beforeMatches = beforeData.matches || [];
            const afterMatches = afterData.matches || [];

            if (afterMatches.length > beforeMatches.length) {
                const newMatchId = afterMatches.find(id => !beforeMatches.includes(id));
                if (newMatchId) {
                    const matchDoc = await admin.firestore().collection("users").doc(newMatchId).get();
                    const matchName = matchDoc.exists ? matchDoc.data().displayName : getMsg(lang, 'unknown');

                    await admin.messaging().send({
                        token: fcmToken,
                        notification: {
                            title: getMsg(lang, 'matchTitle'),
                            body: getMsg(lang, 'matchBody')(matchName),
                        },
                        data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "match" },
                        android: { priority: 'high' }
                    });
                }
            }

            // (C) 좋아요 받음
            const beforeLikes = beforeData.receivedLikes || [];
            const afterLikes = afterData.receivedLikes || [];
            if (afterLikes.length > beforeLikes.length) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: {
                        title: getMsg(lang, 'likeTitle'),
                        body: getMsg(lang, 'likeBody'),
                    },
                    data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "like" },
                    android: { priority: 'high' }
                });
            }
            return null;
        } catch (error) {
            console.error("Error sending user notification:", error);
            return null;
        }
    });

// ---------------------------------------------------------
// 4. 소셜링 알림
// ---------------------------------------------------------
exports.sendSocialingNotification = functions.firestore
    .document("socialings/{socialingId}")
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const socialingTitle = afterData.title;

        try {
            // (A) 호스트에게 신청 알림
            const beforeApps = beforeData.applicants || [];
            const afterApps = afterData.applicants || [];

            if (afterApps.length > beforeApps.length) {
                const hostId = afterData.hostId;
                const newApplicantId = afterApps.find(id => !beforeApps.includes(id));

                const hostDoc = await admin.firestore().collection("users").doc(hostId).get();
                const hostData = hostDoc.data();

                if (hostData && hostData.fcmToken) {
                    const lang = hostData.languageCode || 'ko'; // 호스트 언어 확인

                    const applicantDoc = await admin.firestore().collection("users").doc(newApplicantId).get();
                    const applicantName = applicantDoc.data()?.displayName || getMsg(lang, 'unknown');

                    await admin.messaging().send({
                        token: hostData.fcmToken,
                        notification: {
                            title: getMsg(lang, 'applyTitle'),
                            body: getMsg(lang, 'applyBody')(socialingTitle, applicantName),
                        },
                        data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "socialing_apply" },
                        android: { priority: 'high' }
                    });
                }
            }

            // (B) 신청자에게 승인 알림
            const beforeMembers = beforeData.members || [];
            const afterMembers = afterData.members || [];

            if (afterMembers.length > beforeMembers.length) {
                const newMemberId = afterMembers.find(id => !beforeMembers.includes(id));

                if (newMemberId !== afterData.hostId) {
                    const memberDoc = await admin.firestore().collection("users").doc(newMemberId).get();
                    const memberData = memberDoc.data();

                    if (memberData && memberData.fcmToken) {
                        const lang = memberData.languageCode || 'ko'; // 멤버 언어 확인

                        await admin.messaging().send({
                            token: memberData.fcmToken,
                            notification: {
                                title: getMsg(lang, 'approveTitle'),
                                body: getMsg(lang, 'approveBody')(socialingTitle),
                            },
                            data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "socialing_approve" },
                            android: { priority: 'high' }
                        });
                    }
                }
            }
            return null;
        } catch (error) {
            console.error("Error sending socialing notification:", error);
            return null;
        }
    });
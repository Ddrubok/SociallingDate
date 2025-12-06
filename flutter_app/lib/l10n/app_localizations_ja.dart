// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ソーシャルマッチング';

  @override
  String get ok => '確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get error => 'エラー';

  @override
  String get confirm => '確認';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get loginSubtitle => '真剣な出会いを始めましょう';

  @override
  String get loginButton => 'ログイン';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get emailHint => 'メールアドレスを入力';

  @override
  String get emailEmpty => 'メールアドレスを入力してください';

  @override
  String get emailInvalid => '無効なメールアドレス形式です';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get passwordHint => 'パスワードを入力';

  @override
  String get passwordEmpty => 'パスワードを入力してください';

  @override
  String get passwordLength => 'パスワードは6文字以上必要です';

  @override
  String get noAccount => 'アカウントをお持ちでないですか？';

  @override
  String get signUpLink => '会員登録';

  @override
  String get loginFailed => 'ログイン失敗';

  @override
  String get signUpTitle => '会員登録';

  @override
  String get signUpButton => '登録する';

  @override
  String get nameLabel => '名前';

  @override
  String get ageLabel => '年齢';

  @override
  String get genderLabel => '性別';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get locationLabel => '地域';

  @override
  String get bioLabel => '自己紹介';

  @override
  String get interestsLabel => '興味';

  @override
  String get selectProfileImage => 'プロフィール写真を選択してください';

  @override
  String get selectInterestsHint => '興味 (3つ以上選択)';

  @override
  String get interestError => '興味を3つ以上選択してください';

  @override
  String get signUpComplete => '会員登録が完了しました！';

  @override
  String get signUpError => '会員登録に失敗しました';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabDiscover => '探す';

  @override
  String get tabChat => 'チャット';

  @override
  String get tabProfile => 'プロフィール';

  @override
  String get discoverTitle => '探す';

  @override
  String get filterTitle => '興味フィルター';

  @override
  String get reset => 'リセット';

  @override
  String get apply => '適用';

  @override
  String get noUsersFound => 'マッチするユーザーがいません';

  @override
  String get chatListTitle => 'チャット';

  @override
  String get noConversations => 'まだ会話がありません';

  @override
  String get messageInputHint => 'メッセージを入力...';

  @override
  String get send => '送信';

  @override
  String get emptyChat => 'メッセージを送ってみましょう！';

  @override
  String get mannerRating => 'マナー評価';

  @override
  String get rateManner => 'マナーを評価する';

  @override
  String get ratingGood => '良い';

  @override
  String get ratingBad => '残念';

  @override
  String get ratingContent => '会話はいかがでしたか？ 率直な評価はコミュニティの役に立ちます。';

  @override
  String get ratingSubmitted => '評価が反映されました。';

  @override
  String get locationSharingStart => '位置情報の共有を開始しました！相手に現在地が表示されます。';

  @override
  String get locationSharingStop => '位置情報の共有を停止しました。';

  @override
  String get locationPermissionNeeded => '位置情報の権限が必要です。';

  @override
  String distanceLabel(String distance) {
    return '相手との距離: $distance';
  }

  @override
  String get nearbyLabel => '近く (3km以内)';

  @override
  String get myProfileTitle => 'マイプロフィール';

  @override
  String get userProfileTitle => 'プロフィール';

  @override
  String get mannerTemperature => 'マナー温度';

  @override
  String get startChat => 'チャットする';

  @override
  String get report => '通報する';

  @override
  String get block => 'ブロックする';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get reportReasonTitle => '通報理由を選択';

  @override
  String get blockConfirm => '本当にブロックしますか？';

  @override
  String get settingsTitle => '設定';

  @override
  String get supportSection => 'サポート';

  @override
  String get contactUs => 'お問い合わせ / フィードバック';

  @override
  String get contactUsSubtitle => 'バグ報告や機能提案';

  @override
  String get termsOfService => '利用規約';

  @override
  String get accountSection => 'アカウント';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirm => '本当にログアウトしますか？';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語選択';

  @override
  String get korean => '韓国語';

  @override
  String get english => '英語';

  @override
  String get tabSocialing => 'ソーシャリング';

  @override
  String get createSocialing => '集まりを作成';

  @override
  String get socialingTitle => 'ソーシャリング';

  @override
  String get socialingDate => '日時';

  @override
  String get socialingLocation => '場所';

  @override
  String get socialingMembers => '参加メンバー';

  @override
  String get socialingJoin => '参加する';

  @override
  String get socialingJoined => '参加済み';

  @override
  String get socialingFull => '募集締切';

  @override
  String get titleHint => 'タイトルを入力';

  @override
  String get contentHint => 'どんな集まりですか？内容を入力してください';

  @override
  String get maxMembersHint => '最大人数 (人)';

  @override
  String get dateHint => '日付を選択';

  @override
  String get timeHint => '時間を選択';

  @override
  String get locationHint => '場所を入力';

  @override
  String get createSuccess => '集まりを作成しました。';

  @override
  String get joinSuccess => '集まりに参加しました。';

  @override
  String get leaveChat => 'チャットを退出';

  @override
  String get leaveChatConfirm => '本当に退出しますか？リストから削除されます。';

  @override
  String get leave => '退出';

  @override
  String get sendLike => 'いいねを送る';

  @override
  String get acceptLikeAndChat => 'いいねを受け入れてチャット';

  @override
  String get likeSentMessage => 'いいねを送りました！相手の反応を待ちましょう。';

  @override
  String get matchSuccessMessage => 'マッチングしました！チャットを始めましょう。🎉';

  @override
  String get categoryLabel => 'カテゴリー';

  @override
  String get maxDistanceLabel => '最大距離';

  @override
  String get catSmall => '少人数';

  @override
  String get catLarge => '大人数';

  @override
  String get catOneDay => '1日限定';

  @override
  String get catWeekend => '週末';

  @override
  String get catAll => 'すべて';

  @override
  String get dailyRecommend => '本日推奨';

  @override
  String get customRecommend => 'カスタム推奨事項';

  @override
  String get tabNearby => '周辺';

  @override
  String get tabInterest => '趣味';

  @override
  String get tabReligion => '宗教';

  @override
  String get tabLifestyle => '生活';

  @override
  String get applyJoin => '参加申請';

  @override
  String get cancelApply => '申請キャンセル';

  @override
  String get waitingApproval => '承認待ち';

  @override
  String get manageMembers => '参加者管理';

  @override
  String get applicantsList => '申請者リスト';

  @override
  String get approve => '承認';

  @override
  String get reject => '拒否';

  @override
  String get noApplicants => '申請者がまだいません。';

  @override
  String get applySent => '参加申請を送りました。';

  @override
  String get approveSuccess => 'メンバーを承認しました。';

  @override
  String get rejectSuccess => '申請を拒否しました。';

  @override
  String get friendRequestSent => '友達申請を送りました。';

  @override
  String get friendRequestReceived => '友達になりたいそうです！';

  @override
  String get sendFriendRequest => '友達申請を送る';

  @override
  String get cancelFriendRequest => '申請キャンセル';

  @override
  String get acceptFriendRequest => '承認';

  @override
  String get rejectFriendRequest => '拒否';

  @override
  String get requestPending => '申請中';

  @override
  String get requestAccepted => '申請が承認されました。チャットを始めましょう！';

  @override
  String get requestRejected => '申請が拒否されました。';

  @override
  String get noFriendRequests => '届いた申請はありません。';

  @override
  String get noBio => 'まだ自己紹介がありません。';

  @override
  String get noInterests => '登録された関心事がありません。';

  @override
  String get userBlocked => 'ユーザーをブロックしました。';

  @override
  String get userUnblocked => 'ブロックを解除しました。';

  @override
  String get reportUser => 'ユーザーを通報';

  @override
  String get reportReasonHint => '通報理由を入力してください。';

  @override
  String get reportSubmitted => '通報を受け付けました。';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '소셜매칭';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get error => '오류';

  @override
  String get confirm => '확인';

  @override
  String get loginTitle => '로그인';

  @override
  String get loginSubtitle => '진정성 있는 관계를 시작하세요';

  @override
  String get loginButton => '로그인';

  @override
  String get emailLabel => '이메일';

  @override
  String get emailHint => '이메일을 입력하세요';

  @override
  String get emailEmpty => '이메일을 입력해주세요';

  @override
  String get emailInvalid => '올바른 이메일 형식이 아닙니다';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get passwordHint => '비밀번호를 입력하세요';

  @override
  String get passwordEmpty => '비밀번호를 입력해주세요';

  @override
  String get passwordLength => '비밀번호는 최소 6자 이상이어야 합니다';

  @override
  String get noAccount => '계정이 없으신가요?';

  @override
  String get signUpLink => '회원가입';

  @override
  String get loginFailed => '로그인 실패';

  @override
  String get signUpTitle => '회원가입';

  @override
  String get signUpButton => '가입하기';

  @override
  String get nameLabel => '이름';

  @override
  String get ageLabel => '나이';

  @override
  String get genderLabel => '성별';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get locationLabel => '지역';

  @override
  String get bioLabel => '자기소개';

  @override
  String get interestsLabel => '관심사';

  @override
  String get selectProfileImage => '프로필 사진을 선택해주세요';

  @override
  String get selectInterestsHint => '관심사 (최소 3개 선택)';

  @override
  String get interestError => '관심사를 3개 이상 선택해주세요';

  @override
  String get signUpComplete => '회원가입이 완료되었습니다!';

  @override
  String get signUpError => '회원가입 실패';

  @override
  String get tabHome => '홈';

  @override
  String get tabDiscover => '탐색';

  @override
  String get tabChat => '채팅';

  @override
  String get tabProfile => '프로필';

  @override
  String get discoverTitle => '탐색';

  @override
  String get filterTitle => '관심사 필터';

  @override
  String get reset => '초기화';

  @override
  String get apply => '적용';

  @override
  String get noUsersFound => '매칭되는 사용자가 없습니다';

  @override
  String get chatListTitle => '채팅';

  @override
  String get noConversations => '아직 대화가 없습니다';

  @override
  String get messageInputHint => '메시지를 입력하세요...';

  @override
  String get send => '전송';

  @override
  String get emptyChat => '메시지를 보내보세요!';

  @override
  String get mannerRating => '매너 평가';

  @override
  String get rateManner => '매너 평가하기';

  @override
  String get ratingGood => '좋아요';

  @override
  String get ratingBad => '아쉬워요';

  @override
  String get ratingContent => '대화는 어떠셨나요? 솔직한 평가는 커뮤니티에 도움이 됩니다.';

  @override
  String get ratingSubmitted => '평가가 반영되었습니다.';

  @override
  String get locationSharingStart => '위치 공유 시작! 내 위치가 상대방에게 보입니다.';

  @override
  String get locationSharingStop => '위치 공유를 껐습니다.';

  @override
  String get locationPermissionNeeded => '위치 권한이 필요합니다.';

  @override
  String distanceLabel(String distance) {
    return '상대방과의 거리: $distance';
  }

  @override
  String get nearbyLabel => '근처 (3km 이내)';

  @override
  String get myProfileTitle => '내 프로필';

  @override
  String get userProfileTitle => '프로필';

  @override
  String get mannerTemperature => '매너온도';

  @override
  String get startChat => '채팅하기';

  @override
  String get report => '신고하기';

  @override
  String get block => '차단하기';

  @override
  String get unblock => '차단 해제';

  @override
  String get reportReasonTitle => '신고 사유 선택';

  @override
  String get blockConfirm => '정말 차단하시겠습니까?';

  @override
  String get settingsTitle => '설정';

  @override
  String get supportSection => '지원';

  @override
  String get contactUs => '문의하기 / 피드백 보내기';

  @override
  String get contactUsSubtitle => '버그 제보나 건의사항을 보내주세요';

  @override
  String get termsOfService => '서비스 이용약관';

  @override
  String get accountSection => '계정';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '정말 로그아웃 하시겠습니까?';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get korean => '한국어';

  @override
  String get english => 'English';

  @override
  String get tabSocialing => '소셜링';

  @override
  String get createSocialing => '모임 개설';

  @override
  String get socialingTitle => '소셜링';

  @override
  String get socialingDate => '일시';

  @override
  String get socialingLocation => '장소';

  @override
  String get socialingMembers => '참여 인원';

  @override
  String get socialingJoin => '참여하기';

  @override
  String get socialingJoined => '참여 중';

  @override
  String get socialingFull => '모집 마감';

  @override
  String get titleHint => '제목을 입력하세요';

  @override
  String get contentHint => '어떤 모임인가요? 내용을 입력하세요';

  @override
  String get maxMembersHint => '최대 인원 (명)';

  @override
  String get dateHint => '날짜 선택';

  @override
  String get timeHint => '시간 선택';

  @override
  String get locationHint => '장소 입력';

  @override
  String get createSuccess => '모임이 개설되었습니다.';

  @override
  String get joinSuccess => '모임에 참여했습니다.';

  @override
  String get leaveChat => '채팅방 나가기';

  @override
  String get leaveChatConfirm => '정말 나가시겠습니까? 대화 목록에서 사라집니다.';

  @override
  String get leave => '나가기';

  @override
  String get sendLike => '좋아요 보내기';

  @override
  String get acceptLikeAndChat => '좋아요 수락하고 채팅하기';

  @override
  String get likeSentMessage => '좋아요를 보냈습니다! 상대방의 응답을 기다려보세요.';

  @override
  String get matchSuccessMessage => '매칭되었습니다! 채팅을 시작해보세요. 🎉';
}

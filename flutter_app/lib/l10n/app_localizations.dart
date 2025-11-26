import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'소셜매칭'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @error.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get error;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @loginTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'진정성 있는 관계를 시작하세요'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginButton;

  /// No description provided for @emailLabel.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력하세요'**
  String get emailHint;

  /// No description provided for @emailEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요'**
  String get emailEmpty;

  /// No description provided for @emailInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 형식이 아닙니다'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력하세요'**
  String get passwordHint;

  /// No description provided for @passwordEmpty.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요'**
  String get passwordEmpty;

  /// No description provided for @passwordLength.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 최소 6자 이상이어야 합니다'**
  String get passwordLength;

  /// No description provided for @noAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요?'**
  String get noAccount;

  /// No description provided for @signUpLink.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUpLink;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 실패'**
  String get loginFailed;

  /// No description provided for @signUpTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUpTitle;

  /// No description provided for @signUpButton.
  ///
  /// In ko, this message translates to:
  /// **'가입하기'**
  String get signUpButton;

  /// No description provided for @nameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get nameLabel;

  /// No description provided for @ageLabel.
  ///
  /// In ko, this message translates to:
  /// **'나이'**
  String get ageLabel;

  /// No description provided for @genderLabel.
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get genderLabel;

  /// No description provided for @male.
  ///
  /// In ko, this message translates to:
  /// **'남성'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ko, this message translates to:
  /// **'여성'**
  String get female;

  /// No description provided for @locationLabel.
  ///
  /// In ko, this message translates to:
  /// **'지역'**
  String get locationLabel;

  /// No description provided for @bioLabel.
  ///
  /// In ko, this message translates to:
  /// **'자기소개'**
  String get bioLabel;

  /// No description provided for @interestsLabel.
  ///
  /// In ko, this message translates to:
  /// **'관심사'**
  String get interestsLabel;

  /// No description provided for @selectProfileImage.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 선택해주세요'**
  String get selectProfileImage;

  /// No description provided for @selectInterestsHint.
  ///
  /// In ko, this message translates to:
  /// **'관심사 (최소 3개 선택)'**
  String get selectInterestsHint;

  /// No description provided for @interestError.
  ///
  /// In ko, this message translates to:
  /// **'관심사를 3개 이상 선택해주세요'**
  String get interestError;

  /// No description provided for @signUpComplete.
  ///
  /// In ko, this message translates to:
  /// **'회원가입이 완료되었습니다!'**
  String get signUpComplete;

  /// No description provided for @signUpError.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 실패'**
  String get signUpError;

  /// No description provided for @tabHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get tabHome;

  /// No description provided for @tabDiscover.
  ///
  /// In ko, this message translates to:
  /// **'탐색'**
  String get tabDiscover;

  /// No description provided for @tabChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get tabChat;

  /// No description provided for @tabProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get tabProfile;

  /// No description provided for @discoverTitle.
  ///
  /// In ko, this message translates to:
  /// **'탐색'**
  String get discoverTitle;

  /// No description provided for @filterTitle.
  ///
  /// In ko, this message translates to:
  /// **'관심사 필터'**
  String get filterTitle;

  /// No description provided for @reset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get apply;

  /// No description provided for @noUsersFound.
  ///
  /// In ko, this message translates to:
  /// **'매칭되는 사용자가 없습니다'**
  String get noUsersFound;

  /// No description provided for @chatListTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get chatListTitle;

  /// No description provided for @noConversations.
  ///
  /// In ko, this message translates to:
  /// **'아직 대화가 없습니다'**
  String get noConversations;

  /// No description provided for @messageInputHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요...'**
  String get messageInputHint;

  /// No description provided for @send.
  ///
  /// In ko, this message translates to:
  /// **'전송'**
  String get send;

  /// No description provided for @emptyChat.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 보내보세요!'**
  String get emptyChat;

  /// No description provided for @mannerRating.
  ///
  /// In ko, this message translates to:
  /// **'매너 평가'**
  String get mannerRating;

  /// No description provided for @rateManner.
  ///
  /// In ko, this message translates to:
  /// **'매너 평가하기'**
  String get rateManner;

  /// No description provided for @ratingGood.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get ratingGood;

  /// No description provided for @ratingBad.
  ///
  /// In ko, this message translates to:
  /// **'아쉬워요'**
  String get ratingBad;

  /// No description provided for @ratingContent.
  ///
  /// In ko, this message translates to:
  /// **'대화는 어떠셨나요? 솔직한 평가는 커뮤니티에 도움이 됩니다.'**
  String get ratingContent;

  /// No description provided for @ratingSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'평가가 반영되었습니다.'**
  String get ratingSubmitted;

  /// No description provided for @locationSharingStart.
  ///
  /// In ko, this message translates to:
  /// **'위치 공유 시작! 내 위치가 상대방에게 보입니다.'**
  String get locationSharingStart;

  /// No description provided for @locationSharingStop.
  ///
  /// In ko, this message translates to:
  /// **'위치 공유를 껐습니다.'**
  String get locationSharingStop;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한이 필요합니다.'**
  String get locationPermissionNeeded;

  /// No description provided for @distanceLabel.
  ///
  /// In ko, this message translates to:
  /// **'상대방과의 거리: {distance}'**
  String distanceLabel(String distance);

  /// No description provided for @nearbyLabel.
  ///
  /// In ko, this message translates to:
  /// **'근처 (3km 이내)'**
  String get nearbyLabel;

  /// No description provided for @myProfileTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 프로필'**
  String get myProfileTitle;

  /// No description provided for @userProfileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get userProfileTitle;

  /// No description provided for @mannerTemperature.
  ///
  /// In ko, this message translates to:
  /// **'매너온도'**
  String get mannerTemperature;

  /// No description provided for @startChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅하기'**
  String get startChat;

  /// No description provided for @report.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get report;

  /// No description provided for @block.
  ///
  /// In ko, this message translates to:
  /// **'차단하기'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get unblock;

  /// No description provided for @reportReasonTitle.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유 선택'**
  String get reportReasonTitle;

  /// No description provided for @blockConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 차단하시겠습니까?'**
  String get blockConfirm;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @supportSection.
  ///
  /// In ko, this message translates to:
  /// **'지원'**
  String get supportSection;

  /// No description provided for @contactUs.
  ///
  /// In ko, this message translates to:
  /// **'문의하기 / 피드백 보내기'**
  String get contactUs;

  /// No description provided for @contactUsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'버그 제보나 건의사항을 보내주세요'**
  String get contactUsSubtitle;

  /// No description provided for @termsOfService.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용약관'**
  String get termsOfService;

  /// No description provided for @accountSection.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get accountSection;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃 하시겠습니까?'**
  String get logoutConfirm;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어 선택'**
  String get selectLanguage;

  /// No description provided for @korean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @english.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get english;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Social Matching';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get error => 'Error';

  @override
  String get confirm => 'Confirm';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Start an authentic relationship';

  @override
  String get loginButton => 'Login';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailEmpty => 'Please enter your email';

  @override
  String get emailInvalid => 'Invalid email format';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordEmpty => 'Please enter your password';

  @override
  String get passwordLength => 'Password must be at least 6 characters';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get nameLabel => 'Name';

  @override
  String get ageLabel => 'Age';

  @override
  String get genderLabel => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get locationLabel => 'Location';

  @override
  String get bioLabel => 'Bio';

  @override
  String get interestsLabel => 'Interests';

  @override
  String get selectProfileImage => 'Please select a profile image';

  @override
  String get selectInterestsHint => 'Interests (Select at least 3)';

  @override
  String get interestError => 'Please select at least 3 interests';

  @override
  String get signUpComplete => 'Sign up completed!';

  @override
  String get signUpError => 'Sign up failed';

  @override
  String get tabHome => 'Home';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabProfile => 'Profile';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get filterTitle => 'Interest Filter';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get noUsersFound => 'No matching users found';

  @override
  String get chatListTitle => 'Chats';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get messageInputHint => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get emptyChat => 'Start a conversation!';

  @override
  String get mannerRating => 'Manner Rating';

  @override
  String get rateManner => 'Rate Manner';

  @override
  String get ratingGood => 'Good';

  @override
  String get ratingBad => 'Needs Improvement';

  @override
  String get ratingContent =>
      'How was the conversation? Your feedback helps the community.';

  @override
  String get ratingSubmitted => 'Rating submitted.';

  @override
  String get locationSharingStart =>
      'Location sharing started! Your location is visible to the partner.';

  @override
  String get locationSharingStop => 'Location sharing stopped.';

  @override
  String get locationPermissionNeeded => 'Location permission is required.';

  @override
  String distanceLabel(String distance) {
    return 'Distance: $distance';
  }

  @override
  String get nearbyLabel => 'Nearby (within 3km)';

  @override
  String get myProfileTitle => 'My Profile';

  @override
  String get userProfileTitle => 'Profile';

  @override
  String get mannerTemperature => 'Manner Temp';

  @override
  String get startChat => 'Chat';

  @override
  String get report => 'Report';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get reportReasonTitle => 'Select Reason';

  @override
  String get blockConfirm => 'Are you sure you want to block?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get supportSection => 'Support';

  @override
  String get contactUs => 'Contact Us / Feedback';

  @override
  String get contactUsSubtitle => 'Report bugs or suggest features';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get accountSection => 'Account';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get korean => 'Korean';

  @override
  String get english => 'English';

  @override
  String get tabSocialing => 'Socialing';

  @override
  String get createSocialing => 'Create Meetup';

  @override
  String get socialingTitle => 'Socialing';

  @override
  String get socialingDate => 'Date';

  @override
  String get socialingLocation => 'Location';

  @override
  String get socialingMembers => 'Members';

  @override
  String get socialingJoin => 'Join';

  @override
  String get socialingJoined => 'Joined';

  @override
  String get socialingFull => 'Full';

  @override
  String get titleHint => 'Enter title';

  @override
  String get contentHint => 'What is this meetup about?';

  @override
  String get maxMembersHint => 'Max members';

  @override
  String get dateHint => 'Select Date';

  @override
  String get timeHint => 'Select Time';

  @override
  String get locationHint => 'Enter location';

  @override
  String get createSuccess => 'Meetup created.';

  @override
  String get joinSuccess => 'Joined meetup.';

  @override
  String get leaveChat => 'Leave Chat';

  @override
  String get leaveChatConfirm =>
      'Are you sure you want to leave? It will be removed from your list.';

  @override
  String get leave => 'Leave';

  @override
  String get sendLike => 'Send Like';

  @override
  String get acceptLikeAndChat => 'Accept Like & Chat';

  @override
  String get likeSentMessage => 'Like sent! Wait for their response.';

  @override
  String get matchSuccessMessage => 'It\'s a Match! Start chatting now. 🎉';

  @override
  String get categoryLabel => 'Category';

  @override
  String get maxDistanceLabel => 'Max Distance';

  @override
  String get catSmall => 'Small Group';

  @override
  String get catLarge => 'Large Group';

  @override
  String get catOneDay => 'One Day';

  @override
  String get catWeekend => 'Weekend';

  @override
  String get catAll => 'All';

  @override
  String get dailyRecommend => 'Today\'s Recommendation';

  @override
  String get customRecommend => 'Custom Recommendation';

  @override
  String get tabNearby => 'Around';

  @override
  String get tabInterest => 'Hobby';

  @override
  String get tabReligion => 'Religion';

  @override
  String get tabLifestyle => 'Life';

  @override
  String get applyJoin => 'Request to Join';

  @override
  String get cancelApply => 'Cancel Request';

  @override
  String get waitingApproval => 'Pending Approval';

  @override
  String get manageMembers => 'Manage Members';

  @override
  String get applicantsList => 'Applicants';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get noApplicants => 'No applicants yet.';

  @override
  String get applySent => 'Request sent.';

  @override
  String get approveSuccess => 'Member approved.';

  @override
  String get rejectSuccess => 'Request rejected.';

  @override
  String get friendRequestSent => 'Friend request sent.';

  @override
  String get friendRequestReceived => 'Wants to be friends!';

  @override
  String get sendFriendRequest => 'Send Friend Request';

  @override
  String get cancelFriendRequest => 'Cancel Request';

  @override
  String get acceptFriendRequest => 'Accept';

  @override
  String get rejectFriendRequest => 'Reject';

  @override
  String get requestPending => 'Request Pending';

  @override
  String get requestAccepted => 'Request accepted. Start chatting!';

  @override
  String get requestRejected => 'Request rejected.';

  @override
  String get noFriendRequests => 'No requests received.';

  @override
  String get noBio => 'No bio yet.';

  @override
  String get noInterests => 'No interests added.';

  @override
  String get userBlocked => 'User blocked.';

  @override
  String get userUnblocked => 'User unblocked.';

  @override
  String get reportUser => 'Report User';

  @override
  String get reportReasonHint => 'Please enter the reason.';

  @override
  String get reportSubmitted => 'Report submitted.';
}

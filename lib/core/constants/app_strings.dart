/// Centralized application strings and church branding configuration.
///
/// Churches can easily update church name, tagline, and labels here.
class AppStrings {
  AppStrings._();

  // Branding
  static const String appName = 'CSI Church Community';
  static const String churchName = 'CSI Church Community';
  static const String tagline = 'One Church · One Family · One Mission';
  static const String welcomeSubtitle =
      'Stay connected in fellowship, worship, and church ministry.';

  // Scripture Verse / Motto for Welcome & Dashboard
  static const String dailyVerse =
      '"For where two or three gather in my name, there am I with them."';
  static const String dailyVerseRef = '— Matthew 18:20';

  // Auth & Onboarding
  static const String signIn = 'Sign In';
  static const String requestAccess = 'Request Church Access';
  static const String welcomeBack = 'Welcome to Fellowship';
  static const String loginSubtitle =
      'Sign in with your registered church member credentials';
  static const String requestAccessTitle = 'Join Our Church Community';
  static const String requestAccessSubtitle =
      'Submit your official details for verification and approval by the church committee.';
  static const String pendingApprovalTitle = 'Access Request Under Review';
  static const String pendingApprovalMessage =
      'Thank you for registering with our church community. To protect our congregation\'s privacy, your membership request is awaiting review and approval by the church committee.';
  static const String pendingNotice =
      'You will receive access once your details are verified. You can check back anytime by signing in.';

  // Form Fields & Hints
  static const String officialFullName = 'Official Full Name';
  static const String fullNameHint = 'Must match church baptism/census record';
  static const String familyNumber = 'Church Family Number';
  static const String familyNumberHint = 'e.g. F-104 or FAM/2024/45';
  static const String familyNumberHelp =
      'Shared by all members of your family unit. Each member receives a unique account.';
  static const String profilePhoto = 'Profile Photo (Mandatory)';
  static const String profilePhotoHelp =
      'A clear, respectful photo is required for committee verification.';
  static const String changePhoto = 'Change Photo';
  static const String removePhoto = 'Remove Photo';
  static const String takePhoto = 'Take Photo';
  static const String chooseFromGallery = 'Choose from Gallery';
  static const String photoRequired = 'Profile photo is mandatory for church verification';

  static const String email = 'Email Address';
  static const String emailHint = 'e.g. member@csichurch.org';
  static const String phone = 'Phone Number (Optional)';
  static const String phoneHint = '+91 98765 43210';
  static const String familyInfo = 'Family / Parish Unit (Optional)';
  static const String familyInfoHint = 'e.g. St. Thomas Ward, House #12';
  static const String password = 'Password';
  static const String passwordHint = 'Minimum 6 characters';
  static const String confirmPassword = 'Confirm Password';
  static const String confirmPasswordHint = 'Re-enter your password';
  static const String forgotPassword = 'Forgot Password?';
  static const String refreshStatus = 'Refresh Approval Status';
  static const String logout = 'Log Out';
  static const String alreadyHaveAccount = 'Already an approved member? ';
  static const String needToRegister = 'New member to our church? ';
}

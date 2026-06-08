class ApiEndpoints {
  static const String apiBaseUrl = 'https://admin.syncly.com/api/';

  static const String register = 'auth/register';
  static const String login = 'auth/login';
  static const String forgotPassword = 'auth/forgot-password';
  static const String verifyOtp = 'auth/verify-otp';
  static const String resetPassword = 'auth/reset-password';

  static String getUserProfile() => 'profile';
  static String getUserCreatedPoll() => 'profile/posts';
  static const String updateProfile = 'profile/update';
  static const String changePassword = 'profile/change-password';
}

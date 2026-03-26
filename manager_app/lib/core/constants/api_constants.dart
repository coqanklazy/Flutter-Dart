class ApiConstants {
  // Base URL - dùng 10.0.2.2 cho Android emulator (trỏ tới localhost máy host)
  // Đổi thành IP thực nếu chạy trên thiết bị thật
  static const String baseUrl = 'http://10.0.2.2:3001/api';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String sendRegistrationOTP = '/auth/send-registration-otp';
  static const String verifyRegistrationOTP = '/auth/verify-registration-otp';
  static const String sendPasswordResetOTP = '/auth/send-password-reset-otp';
  static const String resetPasswordOTP = '/auth/reset-password-otp';
  static const String logout = '/auth/logout';
  static const String checkSession = '/auth/check-session';
}

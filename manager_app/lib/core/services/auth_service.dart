import 'dart:convert';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  /// Đăng nhập bằng email/username + password
  /// Trả về ApiResponse với data chứa user, tokens, session
  static Future<ApiResponse> login(
    String emailOrUsername,
    String password,
  ) async {
    final response = await ApiService.post(ApiConstants.login, {
      'emailOrUsername': emailOrUsername,
      'password': password,
    });

    // Nếu login thành công, lưu tokens và session
    if (response.success && response.data != null) {
      final tokens = response.data!['tokens'];
      final session = response.data!['session'];
      final user = response.data!['user'];

      if (tokens != null) {
        await StorageService.saveTokens(
          accessToken: tokens['accessToken'],
          refreshToken: tokens['refreshToken'],
        );
      }

      if (session != null && session['sessionId'] != null) {
        await StorageService.saveSessionId(session['sessionId']);
      }

      if (user != null) {
        await StorageService.saveUserData(jsonEncode(user));
      }
    }

    return response;
  }

  /// Gửi OTP cho đăng ký tài khoản
  static Future<ApiResponse> sendRegistrationOTP({
    required String email,
    required String username,
    String? fullName,
  }) async {
    return await ApiService.post(ApiConstants.sendRegistrationOTP, {
      'email': email,
      'username': username,
      if (fullName != null) 'fullName': fullName,
    });
  }

  /// Xác thực OTP và hoàn tất đăng ký
  static Future<ApiResponse> verifyRegistrationOTP({
    required String email,
    required String otpCode,
    required String username,
    required String password,
    required String fullName,
    String? phoneNumber,
    String role = 'ADMIN',
  }) async {
    final response = await ApiService.post(ApiConstants.verifyRegistrationOTP, {
      'email': email,
      'otpCode': otpCode,
      'username': username,
      'password': password,
      'fullName': fullName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'role': role,
    });

    // Nếu đăng ký thành công, lưu tokens
    if (response.success && response.data != null) {
      final tokens = response.data!['tokens'];
      final user = response.data!['user'];

      if (tokens != null) {
        await StorageService.saveTokens(
          accessToken: tokens['accessToken'],
          refreshToken: tokens['refreshToken'],
        );
      }

      if (user != null) {
        await StorageService.saveUserData(jsonEncode(user));
      }
    }

    return response;
  }

  /// Gửi OTP cho reset password
  static Future<ApiResponse> sendPasswordResetOTP(String email) async {
    return await ApiService.post(ApiConstants.sendPasswordResetOTP, {
      'email': email,
    });
  }

  /// Reset password bằng OTP
  static Future<ApiResponse> resetPasswordWithOTP({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    return await ApiService.post(ApiConstants.resetPasswordOTP, {
      'email': email,
      'otpCode': otpCode,
      'newPassword': newPassword,
    });
  }

  /// Đăng xuất
  static Future<ApiResponse> logout() async {
    final sessionId = await StorageService.getSessionId();
    final response = await ApiService.post(ApiConstants.logout, {
      if (sessionId != null) 'sessionId': sessionId,
    });

    // Xoá dữ liệu local dù server trả về gì
    await StorageService.clearAll();

    return response;
  }
}

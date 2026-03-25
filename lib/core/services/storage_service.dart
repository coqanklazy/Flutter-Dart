import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionIdKey = 'session_id';
  static const String _userDataKey = 'user_data';

  // Lưu tokens
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  // Lấy access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Lấy refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Lưu session ID
  static Future<void> saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
  }

  // Lấy session ID
  static Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionIdKey);
  }

  // Lưu user data (JSON string)
  static Future<void> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, userData);
  }

  // Lấy user data
  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userDataKey);
  }

  // Kiểm tra đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Xoá tất cả dữ liệu auth (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_sessionIdKey);
    await prefs.remove(_userDataKey);
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final List<dynamic>? errors;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
      errors: json['errors'],
      statusCode: statusCode,
    );
  }

  /// Lấy message lỗi đầu tiên từ errors array hoặc message chung
  String get errorMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors![0]['message'] ?? message ?? 'Có lỗi xảy ra';
    }
    return message ?? 'Có lỗi xảy ra';
  }
}

class ApiService {
  /// POST request
  static Future<ApiResponse> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(jsonData, response.statusCode);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
      );
    }
  }

  /// GET request
  static Future<ApiResponse> get(String endpoint) async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(jsonData, response.statusCode);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
      );
    }
  }
}

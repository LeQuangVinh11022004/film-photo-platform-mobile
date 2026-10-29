import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Lớp Generic API Client xử lý mọi request cho ứng dụng
class ApiClient {
  // Singleton pattern để dùng chung 1 instance trên toàn app
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Địa chỉ Base URL mặc định (Tự động đổi IP cho Android Emulator)
  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5038'; // Kết nối localhost từ Android Emulator
    }
    return 'http://localhost:5038'; // Kết nối localhost từ Web/iOS/Windows
  }

  String baseUrl = defaultBaseUrl;
  
  // Lưu trữ Token để tự động gắn vào Header của mọi Request cần xác thực
  String? _authToken;

  /// Lấy Token hiện tại
  String? get authToken => _authToken;

  /// Cập nhật Token (sau khi login hoặc refresh)
  void setToken(String? token) {
    _authToken = token;
  }

  /// Xóa Token (khi đăng xuất)
  void clearToken() {
    _authToken = null;
  }

  /// Khởi tạo headers mặc định (tự động thêm Token nếu có)
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Generic GET Request
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) print('GET: $url');
    return await http.get(url, headers: _headers).timeout(const Duration(seconds: 15));
  }

  /// Generic POST Request
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) print('POST: $url');
    return await http
        .post(
          url,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Generic PUT Request
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) print('PUT: $url');
    return await http
        .put(
          url,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Generic DELETE Request
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) print('DELETE: $url');
    return await http.delete(url, headers: _headers).timeout(const Duration(seconds: 15));
  }
}

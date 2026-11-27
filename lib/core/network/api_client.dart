import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Lớp Generic API Client xử lý mọi request cho ứng dụng
class ApiClient {
  // Singleton pattern để dùng chung 1 instance trên toàn app
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  http.Client? _client;

  ApiClient._internal() {
    _initClient();
  }

  void _initClient() {
    _client = http.Client();
  }

  /// Lấy instance http.Client (đảm bảo luôn được khởi tạo)
  http.Client get client {
    if (_client == null) {
      _initClient();
    }
    return _client!;
  }

  /// Địa chỉ Base URL (Đã Deploy lên Azure)
  static String get defaultBaseUrl {
    return 'https://filmbooking-api-h7bghwcydwb8eecn.japaneast-01.azurewebsites.net'; 
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
    return await client.get(url, headers: _headers).timeout(const Duration(seconds: 15));
  }

  /// Generic POST Request
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) print('POST: $url');
    return await client
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
    return await client
        .put(
          url,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Generic PATCH Request
  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) print('PATCH: $url');
    return await client
        .patch(
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
    return await client.delete(url, headers: _headers).timeout(const Duration(seconds: 15));
  }
}

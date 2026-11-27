import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_models.dart';

/// Service xử lý Authentication sử dụng Generic ApiClient
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  UserDTO? currentUser;

  /// Thử tự động đăng nhập khi mở ứng dụng từ Token lưu trong SharedPreferences
  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJsonStr = prefs.getString('current_user');

      if (token != null && token.startsWith('mock_jwt_token_')) {
        await logout();
        return false;
      }

      if (token != null && token.isNotEmpty && userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        currentUser = UserDTO.fromJson(userMap);
        final role = currentUser!.role.trim().toUpperCase();
        if (role != 'PHOTOGRAPHER' && role != 'EXPERT') {
          await logout();
          return false;
        }
        _apiClient.setToken(token);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Auto login error: $e');
    }
    return false;
  }

  /// Gọi API thực tế: POST /api/auth/login
  Future<LoginResponse> login(String username, String password) async {
    final requestDto = LoginRequest(username: username, password: password);

    try {
      final response = await _apiClient.post(
        '/api/auth/login',
        body: requestDto.toJson(),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(json);
        if (loginResponse.success) {
          if (loginResponse.user == null ||
              loginResponse.token == null ||
              loginResponse.token!.isEmpty) {
            return LoginResponse(
              success: false,
              message: 'Máy chủ không trả về thông tin đăng nhập hợp lệ.',
            );
          }
          final role = (loginResponse.user?.role ?? '').trim().toUpperCase();
          if (role != 'PHOTOGRAPHER' && role != 'EXPERT') {
            await logout();
            return LoginResponse(
              success: false,
              message:
                  'Ứng dụng di động chỉ hỗ trợ tài khoản Photographer và Expert.',
            );
          }
          // Lưu token vào ApiClient & SharedPreferences
          _apiClient.setToken(loginResponse.token);
          currentUser = loginResponse.user;

          final prefs = await SharedPreferences.getInstance();
          if (loginResponse.token != null) {
            await prefs.setString('auth_token', loginResponse.token!);
          }
          if (loginResponse.user != null) {
            await prefs.setString(
              'current_user',
              jsonEncode(loginResponse.user!.toJson()),
            );
          }
        }
        return loginResponse;
      } else {
        return LoginResponse(
          success: false,
          message: json['message'] ?? 'Tên đăng nhập hoặc mật khẩu không chính xác.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Login API Error: $e');

      return LoginResponse(
        success: false,
        message: 'Không thể kết nối tới máy chủ API. Vui lòng kiểm tra Server C#.',
      );
    }
  }

  /// Gọi API thực tế: POST /api/auth/register/photographer
  Future<RegisterResponse> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final requestDto = RegisterRequest(fullName: name, username: username, email: email, password: password);

    try {
      final response = await _apiClient.post(
        '/api/auth/register/photographer',
        body: requestDto.toJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final user = UserDTO.fromJson(json);
        return RegisterResponse(
          success: true,
          message: 'Đăng ký tài khoản Photographer thành công!',
          user: user,
        );
      } else if (response.statusCode == 409) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RegisterResponse(
          success: false,
          message: json['message'] ?? 'Email hoặc tên đăng nhập đã tồn tại.',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RegisterResponse(
          success: false,
          message: json['message'] ?? 'Đăng ký thất bại. Vui lòng kiểm tra lại thông tin.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Register API Error: $e');

      return RegisterResponse(
        success: false,
        message: 'Không thể kết nối tới máy chủ API. Vui lòng thử lại sau.',
      );
    }
  }

  /// Đăng xuất (Xóa token trong Generic API Client & SharedPreferences)
  Future<void> logout() async {
    _apiClient.clearToken();
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');
    } catch (_) {}
  }

}


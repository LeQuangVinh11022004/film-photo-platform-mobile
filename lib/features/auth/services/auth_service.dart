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

      if (token != null && token.isNotEmpty && userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        currentUser = UserDTO.fromJson(userMap);
        _apiClient.setToken(token);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Auto login error: $e');
    }
    return false;
  }

  /// Gọi API thực tế: POST /api/auth/login
  Future<LoginResponse> login(String email, String password) async {
    final requestDto = LoginRequest(email: email, password: password);

    try {
      final response = await _apiClient.post(
        '/api/auth/login',
        body: requestDto.toJson(),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(json);
        if (loginResponse.success) {
          final role = (loginResponse.user?.role ?? '').trim().toUpperCase();
          if (role == 'PROVIDER') {
            await logout();
            return LoginResponse(
              success: false,
              message:
                  'Ứng dụng di động chỉ dành cho Nhiếp ảnh gia (Photographer) và Chuyên gia (Expert). Tài khoản Provider không được hỗ trợ đăng nhập.',
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
          message: json['message'] ?? 'Email hoặc mật khẩu không chính xác.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Login API Error: $e');

      // Fallback thử nghiệm offline nếu chưa bật server API hoặc bị ngắt mạng
      if (email.isNotEmpty && password.length >= 6) {
        if (email.toLowerCase().contains('provider')) {
          await logout();
          return LoginResponse(
            success: false,
            message:
                'Ứng dụng di động chỉ dành cho Nhiếp ảnh gia (Photographer) và Chuyên gia (Expert).',
          );
        }
        final mockToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
        _apiClient.setToken(mockToken);
        
        String mockRole = 'Photographer';
        if (email.toLowerCase().contains('expert')) mockRole = 'Expert';

        currentUser = UserDTO(
          userId: 'mock-user-id',
          fullName: mockRole == 'Expert' ? 'Chuyên gia Film' : 'Lê Hoàng Anh',
          email: email,
          role: mockRole,
          status: 'Active',
          createdAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', mockToken);
        await prefs.setString('current_user', jsonEncode(currentUser!.toJson()));

        return LoginResponse(
          success: true,
          message: 'Đăng nhập thành công (Thử nghiệm offline)',
          token: _apiClient.authToken,
          user: currentUser,
        );
      }

      return LoginResponse(
        success: false,
        message: 'Không thể kết nối tới máy chủ API. Vui lòng kiểm tra Server C#.',
      );
    }
  }

  /// Gọi API thực tế: POST /api/auth/register/photographer
  Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final requestDto = RegisterRequest(fullName: name, email: email, password: password);

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
        return RegisterResponse(
          success: false,
          message: 'Tài khoản với email này đã tồn tại trong hệ thống.',
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

      // Fallback thử nghiệm offline nếu chưa bật server API
      if (name.isNotEmpty && email.contains('@') && password.length >= 6) {
        return RegisterResponse(
          success: true,
          message: 'Đăng ký thành công! Vui lòng đăng nhập.',
          user: UserDTO(
            userId: 'mock-new-id',
            fullName: name,
            email: email,
            role: 'Photographer',
            status: 'Active',
            createdAt: DateTime.now(),
          ),
        );
      }

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

  /// Giả lập gửi yêu cầu quên mật khẩu
  Future<bool> sendForgotPasswordEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return email.contains('@');
  }

  /// Giả lập đặt lại mật khẩu
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return code.isNotEmpty && newPassword.length >= 6;
  }

  /// Giả lập Đăng nhập bằng Google
  Future<Map<String, String>?> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'name': 'Google User',
      'email': 'user.google@gmail.com',
      'photoUrl': 'https://via.placeholder.com/150',
    };
  }
}


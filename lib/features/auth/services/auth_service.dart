
/// Service xử lý authentication (Đăng nhập, Đăng ký, Quên mật khẩu, Đặt lại mật khẩu, Google)
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Giả lập đăng nhập bằng Email & Mật khẩu
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Giả lập latency mạng
    if (email.isNotEmpty && password.length >= 6) {
      return true;
    }
    return false;
  }

  /// Giả lập đăng ký tài khoản
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (name.isNotEmpty && email.contains('@') && password.length >= 6) {
      return true;
    }
    return false;
  }

  /// Giả lập gửi yêu cầu quên mật khẩu (Mã xác minh / OTP)
  Future<bool> sendForgotPasswordEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.contains('@')) {
      return true;
    }
    return false;
  }

  /// Giả lập đặt lại mật khẩu với mã xác minh
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (code.isNotEmpty && newPassword.length >= 6) {
      return true;
    }
    return false;
  }

  /// Giả lập Đăng nhập bằng Google
  /// Lưu ý: Để tích hợp Google thực tế, bạn có thể thêm package `google_sign_in`
  /// và cấu hình Firebase / Google Cloud Credentials cho Android / iOS.
  Future<Map<String, String>?> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    // Trả về thông tin giả lập của user Google
    return {
      'name': 'Google User',
      'email': 'user.google@gmail.com',
      'photoUrl': 'https://via.placeholder.com/150',
    };
  }
}

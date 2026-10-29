class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class UserDTO {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final String? providerApprovalStatus;
  final DateTime? createdAt;

  UserDTO({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.providerApprovalStatus,
    this.createdAt,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      providerApprovalStatus: json['providerApprovalStatus'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final DateTime? expiresAtUtc;
  final UserDTO? user;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.expiresAtUtc,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Đăng nhập thành công',
      token: json['token'],
      expiresAtUtc: json['expiresAtUtc'] != null
          ? DateTime.tryParse(json['expiresAtUtc'].toString())
          : null,
      user: json['user'] != null ? UserDTO.fromJson(json['user']) : null,
    );
  }
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'password': password,
      };
}

class RegisterResponse {
  final bool success;
  final String message;
  final UserDTO? user;

  RegisterResponse({
    required this.success,
    required this.message,
    this.user,
  });
}

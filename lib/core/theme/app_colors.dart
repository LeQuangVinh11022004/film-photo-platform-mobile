import 'package:flutter/material.dart';

class AppColors {
  // Mau chu dao (Tone Cam Ấm / Film Vintage Premium)
  static const Color primary = Color(0xFFE04E1B);
  static const Color primaryDark = Color(0xFFB5380F);
  static const Color primaryLight = Color(0xFFFF7A4F);
  static const Color primarySoft = Color(0xFFFDEEE9);

  // Gradient cao cap
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6D3A), Color(0xFFD03E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Nen ung dung & the (Softer, cleaner)
  static const Color background = Color(0xFFFDFBF7); 
  static const Color cardBg = Colors.white;

  // Mau Text Field & Component
  static const Color inputFill = Color(0xFFF4EFEA);
  static const Color border = Color(0xFFEBE4DC); // Thêm màu viền nhẹ nhàng
  static const Color inputBorderFocus = Color(0xFFE04E1B);
  static const Color socialBg = Color(0xFFEFE8E1);

  // Mau Text
  static const Color textPrimary = Color(0xFF1E1611); // Đen ám nâu sâu
  static const Color textSecondary = Color(0xFF7A6E65);
  static const Color textHint = Color(0xFFA69A90);

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);
}

extension AppThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor => isDark ? const Color(0xFF121212) : AppColors.background;
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : AppColors.cardBg;
  Color get inputColor => isDark ? const Color(0xFF2C2C2C) : AppColors.inputFill;
  Color get borderColor => isDark ? const Color(0xFF333333) : AppColors.border;
  Color get textColor => isDark ? const Color(0xFFF5F5F5) : AppColors.textPrimary;
  Color get textSecColor => isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary;
  Color get dividerColor => isDark ? const Color(0xFF333333) : AppColors.inputFill;
}

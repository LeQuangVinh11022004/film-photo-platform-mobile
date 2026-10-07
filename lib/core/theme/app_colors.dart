import 'package:flutter/material.dart';

class AppColors {
  // Mau chu dao (Tone Cam Ấm / Film Vintage)
  static const Color primary = Color(0xFFF15A24);
  static const Color primaryDark = Color(0xFFD03E0B);
  static const Color primaryLight = Color(0xFFFF8252);

  // Gradient cho button va header
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6D3A), Color(0xFFE04E1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Nen ung dung & the
  static const Color background = Color(0xFFFAF6F0);
  static const Color cardBg = Colors.white;

  // Mau Text Field & Component
  static const Color inputFill = Color(0xFFF4ECE6);
  static const Color inputBorderFocus = Color(0xFFF15A24);
  static const Color socialBg = Color(0xFFEFE8E1);

  // Mau Text
  static const Color textPrimary = Color(0xFF2D1F18);
  static const Color textSecondary = Color(0xFF82736B);
  static const Color textHint = Color(0xFFA3958C);
}

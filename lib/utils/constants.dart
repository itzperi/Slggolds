// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFD4AF37);
  static const primaryLight = Color(0xFFE5C55A); // Muted gold, lighter than primary but not bright yellow
  static const background = Color(0xFF0F1C2E);
  static const backgroundDarker = Color(0xFF2D1B4E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textTertiary = Color(0xFF6B7280);
  static const inputBackground = Color.fromRGBO(255, 255, 255, 0.05);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B); // Amber/orange for warnings
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

class AppBorderRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const xlarge = 24.0;
}

class AppTextStyles {
  static const displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFFFFFFFF),
  );

  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF9CA3AF),
  );

  static const headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
  );

  static const bodyLarge = TextStyle(
    fontSize: 18,
    color: Color(0xFFFFFFFF),
  );

  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const caption = TextStyle(
    fontSize: 13,
    color: Color(0xFF9CA3AF),
  );
}

import 'package:flutter/material.dart';

class AppColors {
  // === PRIMARY BRAND ===
  static const Color primary = Color(0xFF2ECC71);
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFFA8E6CF);

  // === BACKGROUND & SURFACE ===
  static const Color background = Color(0xFFF0FAF4);
  static const Color backgroundGradientStart = Color(0xFFE8F8F0);
  static const Color backgroundGradientEnd = Color(0xFFE0F0FF);
  static const Color card = Color(0xFFFFFFFF);

  // === LIQUID GLASS ===
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);
  static const Color liquidBlue = Color(0xFF4FC3F7);
  static const Color liquidTeal = Color(0xFF26C6DA);
  static const Color liquidGreen = Color(0xFF69F0AE);

  // === AI BUTTON GRADIENT ===
  static const Color aiGradientStart = Color(0xFF667EEA);
  static const Color aiGradientMid = Color(0xFF764BA2);
  static const Color aiGradientEnd = Color(0xFF06B6D4);

  // === TEXT ===
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color textLight = Color(0xFF9AAEBB);

  // === STATUS ===
  static const Color statusGood = Color(0xFF2ECC71);
  static const Color statusWarning = Color(0xFFFFB300);
  static const Color statusDanger = Color(0xFFEF5350);
  static const Color statusInfo = Color(0xFF42A5F5);

  // === GRADIENT PRESETS ===
  static const LinearGradient homeBackground = LinearGradient(
    colors: [Color(0xFFECF9F1), Color(0xFFE1F5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlass = LinearGradient(
    colors: [Color(0x26FFFFFF), Color(0x10FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF5350), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

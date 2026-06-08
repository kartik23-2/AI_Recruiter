import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Mode Base Colors
  static const Color background = Color(0xFF0A0F1D);
  static const Color surface = Color(0xFF151C2C);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color border = Color(0xFF2E3B52);

  // Vibrant Accents
  static const Color primary = Color(0xFF6366F1); // Neon Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Violet Purple
  static const Color accent = Color(0xFF06B6D4); // Neon Cyan
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber Yellow
  static const Color error = Color(0xFFEF4444); // Rose Red

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

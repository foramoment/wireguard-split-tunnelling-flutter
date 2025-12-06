import 'package:flutter/material.dart';

/// App color palette for WireGuard Client
class AppColors {
  AppColors._();

  // Primary brand color - Indigo
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Status colors
  static const Color connected = Color(0xFF22C55E);
  static const Color connecting = Color(0xFFF59E0B);
  static const Color disconnected = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);

  // Background colors - Light theme
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Background colors - Dark theme
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  // Gradient for connected state
  static const LinearGradient connectedGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient for primary actions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';

/// Semantic colors used throughout the Vehicle Management System.
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color secondary = Color(0xFF0D9488); // Teal accent

  // Neutral Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFE2E8F0);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status Colors (Badges, Alerts)
  static const Color statusActive = Color(0xFF16A34A); // Emerald green
  static const Color statusActiveBg = Color(0xFFDCFCE7);

  static const Color statusMaintenance = Color(0xFFD97706); // Amber
  static const Color statusMaintenanceBg = Color(0xFFFEF3C7);

  static const Color statusInTransit = Color(0xFF2563EB); // Royal Blue
  static const Color statusInTransitBg = Color(0xFFDBEAFE);

  static const Color statusInactive = Color(0xFFDC2626); // Crimson
  static const Color statusRetiredBg = Color(0xFFFEE2E2);

  // Sidebar / Navigation Rail
  static const Color sidebarBackground = Color(0xFF0F172A); // Slate 900
  static const Color sidebarItemHover = Color(0xFF1E293B); // Slate 800
  static const Color sidebarItemActive = Color(0xFF1E3A8A); // Primary
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarTextActive = Colors.white;
}

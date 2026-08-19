import 'package:flutter/material.dart';

/// Centralized color tokens for Nebula IPTV.
///
/// All UI colors must reference these tokens — never use hardcoded
/// hex values directly in widgets.
abstract final class AppColors {
  // --- Backgrounds & Surfaces ---
  static const background = Color(0xFF0D0D0F);
  static const surface = Color(0xFF1A1A1E);
  static const surfaceElevated = Color(0xFF242428);
  static const card = Color(0xFF1E1E22);

  // --- Brand ---
  static const primary = Color(0xFF6C63FF);
  static const primaryVariant = Color(0xFF5A52E0);
  static const secondary = Color(0xFF03DAC6);

  // --- Text ---
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB0B0B8);

  // --- Utilities ---
  static const divider = Color(0xFF2A2A2E);
  static const error = Color(0xFFCF6679);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);

  // --- Focus (for D-pad / keyboard navigation) ---
  static const focusRing = Color(0xFF6C63FF);
}

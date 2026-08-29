import 'package:flutter/material.dart';

/// Centralized color tokens for Nebula IPTV.
///
/// All UI colors must reference these tokens — never use hardcoded
/// hex values directly in widgets.
///
/// Palette defined in DESIGN.md: trio violeta + teal + coral com papéis
/// semânticos próprios sobre a família "void" de fundos.
/// Regra de uso: violeta = ação, teal = ao vivo/positivo,
/// coral = preferência do usuário (favoritos/notas) — uso esparso.
abstract final class AppColors {
  // --- Brand (trio de accents) ---
  static const nebulaViolet = Color(0xFF6B4FE0);
  static const nebulaVioletDeep = Color(0xFF2A1D6B);
  static const auroraTeal = Color(0xFF1FCFAE);
  static const solarCoral = Color(0xFFFF6F91);

  // --- Void (fundos e superfícies) ---
  static const void950 = Color(0xFF07070F);
  static const void800 = Color(0xFF16162A);
  static const void600 = Color(0xFF2A2A45);

  // --- Text ---
  static const textPrimary = Color(0xFFF5F3FF);
  static const textSecondary = Color(0xFFA8A6C0);

  // --- Status semânticos ---
  static const statusSuccess = Color(0xFF3ECF8E);
  static const statusWarning = Color(0xFFF5B94D);
  static const statusDanger = Color(0xFFFF5468);

  // --- Aliases semânticos (nomes legados preservados) ---
  static const background = void950;
  static const surface = void800;
  static const card = void800;

  /// Superfície um passo acima de [void800] (inputs, placeholders) —
  /// não tem token próprio no DESIGN.md; intermediário void800↔void600.
  static const surfaceElevated = Color(0xFF1E1E38);

  static const divider = void600;
  static const primary = nebulaViolet;
  static const primaryVariant = nebulaVioletDeep;
  static const secondary = auroraTeal;
  static const success = statusSuccess;
  static const warning = statusWarning;
  static const error = statusDanger;

  /// Cor base do anel de foco (o anel em si é um gradiente violeta→teal —
  /// ver NebulaFocusRingPainter). Mantido para usos pontuais.
  static const focusRing = nebulaViolet;
}

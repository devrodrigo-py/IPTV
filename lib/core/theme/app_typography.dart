import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Typography scale for Nebula IPTV.
///
/// Defines consistent text styles across the application.
/// Components should use these styles — never arbitrary font sizes.
///
/// Par tipográfico da marca (DESIGN.md §2):
/// - **Space Grotesk** (700) para display/headline/logo — geométrica, cabe
///   na narrativa "espaço/nebulosa"; títulos de seção em 500–600.
/// - **Inter** (400/500) para body/label/caption — legibilidade em
///   densidade alta (EPG, grades de canal).
///
/// Estilos são `static final` (não `const`) porque o `google_fonts`
/// constrói os TextStyles em runtime.
abstract final class AppTypography {
  // --- Display / Headline / Logo — Space Grotesk 700 ---
  static final display = GoogleFonts.spaceGrotesk(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static final headline = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.25,
  );

  // --- Title / Section — Space Grotesk 600 ---
  static final title = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // --- Body / Label / Caption — Inter 400/500 ---
  static final body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static final label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static final caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Wordmark "NEBULA IPTV" (app bar, splash, sobre): Space Grotesk 700 com
  /// tracking negativo — assinatura de marca; não usar em headlines genéricas.
  static final wordmark = GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  /// Headline do hero de boas-vindas — segue o mockup de referência
  /// (Inter W800, tracking apertado), não a Space Grotesk dos headlines
  /// padrão.
  static final heroDisplay = GoogleFonts.inter(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.06,
    letterSpacing: -1.5,
  );
}

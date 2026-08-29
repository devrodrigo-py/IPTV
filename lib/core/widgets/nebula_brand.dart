import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';

/// Shared Nebula brand lockup used in navigation, onboarding and empty states.
class NebulaBrand extends StatelessWidget {
  final double height;
  final bool compact;

  const NebulaBrand({
    super.key,
    this.height = 34,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/branding/nebula_icon.png', height: height),
          SizedBox(width: height * .20),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wordmark: Space Grotesk 700 com tracking negativo (DESIGN.md §2).
              Text(
                'NEBULA',
                style: AppTypography.wordmark.copyWith(
                  fontSize: height * .38,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'IPTV',
                style: AppTypography.wordmark.copyWith(
                  color: AppColors.auroraTeal,
                  fontSize: height * .18,
                  letterSpacing: height * .14,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Image.asset(
      'assets/branding/nebula_icon.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_fill_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ],
      ),
    );
  }
}

/// Branded visual used while a source has not been imported yet.
class NebulaWelcomeBanner extends StatelessWidget {
  final VoidCallback? onAction;

  const NebulaWelcomeBanner({super.key, this.onAction});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final width = constraints.maxWidth;

        // Desktop/tablet: o mockup oficial da marca é o banner inteiro
        // (logo, headline, subtítulo e esfera já fazem parte da imagem) —
        // só o CTA é widget sobreposto, abaixo do subtítulo.
        if (!compact) {
          final innerWidth = width - 32; // margin 16 dos dois lados
          final bannerHeight = innerWidth / 1.7768; // ratio do asset
          return Container(
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .25),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1.7768,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/branding/nebula_hero.png',
                    fit: BoxFit.cover,
                  ),
                  if (onAction != null)
                    Positioned(
                      left: innerWidth * 0.042,
                      top: bannerHeight * 0.715,
                      child: _GlowCtaButton(onPressed: onAction!),
                    ),
                ],
              ),
            ),
          );
        }

        // Compacto: cena em widgets (texto dentro do PNG ficaria ilegível
        // em larguras pequenas). Geometria da esfera compartilhada com a
        // órbita no painter.
        const bannerHeight = 460.0;
        const sphereSize = 210.0;
        const sphereRight = -40.0;
        final sphereCenter = Offset(
          width - sphereRight - sphereSize / 2,
          bannerHeight / 2,
        );

        return Container(
          margin: const EdgeInsets.all(16),
          height: bannerHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF05060F),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .25),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Nebulosas de fundo (glows radiais que morrem no escuro).
              const Positioned(
                left: -120,
                top: -160,
                child: _GlowBlob(
                  size: 620,
                  color: AppColors.nebulaViolet,
                  opacity: .40,
                ),
              ),
              const Positioned(
                right: -140,
                bottom: -180,
                child: _GlowBlob(
                  size: 640,
                  color: AppColors.auroraTeal,
                  opacity: .26,
                ),
              ),

              // Estrelas + anel de órbita ao redor da esfera.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _WelcomeScenePainter(
                      sphereCenter: sphereCenter,
                      orbitRx: width * .52,
                      orbitRy: bannerHeight * .46,
                    ),
                  ),
                ),
              ),

              // Esfera de play com aro luminoso (nebulosa da marca dentro).
              Positioned(
                right: sphereRight,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: compact ? .55 : 1,
                    child: const _PlaySphere(size: sphereSize),
                  ),
                ),
              ),

              // Conteúdo.
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 30, 36, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logotipo oficial horizontal (asset da marca), com a
                    // calda transparente cortada (conteúdo termina em 63%
                    // da largura do PNG — crop em 2.5x a altura).
                    SizedBox(
                      height: 60,
                      width: 60 * 2.5,
                      child: Image.asset(
                        'assets/branding/nebula_logo_transparent.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const Spacer(),
                    // Headline com "universo inteiro." em degradê
                    // violeta→azul→teal (mockup de referência).
                    Text.rich(
                      TextSpan(
                        text: 'Sua TV merece\num ',
                        style: AppTypography.heroDisplay.copyWith(
                          fontSize: compact ? 34 : 52,
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF8B6BFF),
                                  Color(0xFF4D7CFE),
                                  AppColors.auroraTeal,
                                ],
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                'universo inteiro.',
                                style: AppTypography.heroDisplay.copyWith(
                                  fontSize: compact ? 34 : 52,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Conecte sua fonte e a Nebula organiza canais, filmes '
                      'e séries em uma experiência feita para você.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .95),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (onAction != null) _GlowCtaButton(onPressed: onAction!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Botão-pílula do hero: gradiente teal→mint com glow da marca.
class _GlowCtaButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GlowCtaButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF17BFA0), Color(0xFF43E5C0)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.auroraTeal.withValues(alpha: .40),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          // scaleDown: em telas muito estreitas (ou fonte de fallback mais
          // larga) o conteúdo encolhe em vez de estourar a pílula.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_link_rounded,
                    size: 22,
                    color: AppColors.void950,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Conectar minha fonte',
                    style: AppTypography.body.copyWith(
                      color: AppColors.void950,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Esfera de play da marca: nebulosa circular com aro em gradiente
/// violeta→teal e glow suave.
class _PlaySphere extends StatelessWidget {
  final double size;

  const _PlaySphere({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.nebulaViolet, AppColors.auroraTeal],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.nebulaViolet.withValues(alpha: .35),
            blurRadius: 70,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.auroraTeal.withValues(alpha: .22),
            blurRadius: 90,
            spreadRadius: 24,
          ),
        ],
      ),
      // 3px de aro + 6px de respiro escuro antes da nebulosa (mockup).
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF05060F),
        ),
        padding: const EdgeInsets.all(6),
        child: ClipOval(
          child: Image.asset(
            'assets/branding/nebula_icon.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Glow radial suave (nebulosa de fundo).
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estrelas fixas + anel de órbita elíptico com pontos brilhantes,
/// centrado na esfera de play.
class _WelcomeScenePainter extends CustomPainter {
  final Offset sphereCenter;
  final double orbitRx;
  final double orbitRy;

  const _WelcomeScenePainter({
    required this.sphereCenter,
    required this.orbitRx,
    required this.orbitRy,
  });

  // Frações (x, y, raio, alpha) — posições determinísticas, sem estado.
  static const _stars = [
    (0.06, 0.22, 1.4, 0.35),
    (0.13, 0.62, 1.1, 0.25),
    (0.18, 0.14, 1.8, 0.55),
    (0.27, 0.42, 1.0, 0.30),
    (0.34, 0.78, 1.3, 0.40),
    (0.42, 0.10, 1.2, 0.45),
    (0.49, 0.60, 1.0, 0.28),
    (0.57, 0.24, 1.7, 0.50),
    (0.63, 0.86, 1.2, 0.35),
    (0.71, 0.08, 1.1, 0.40),
    (0.78, 0.52, 1.5, 0.30),
    (0.86, 0.20, 1.2, 0.45),
    (0.92, 0.74, 1.6, 0.35),
    (0.96, 0.12, 1.0, 0.30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint();
    for (final (fx, fy, r, a) in _stars) {
      starPaint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        r,
        starPaint,
      );
    }

    // Órbita elíptica inclinada ao redor da esfera.
    canvas.save();
    canvas.translate(sphereCenter.dx, sphereCenter.dy);
    canvas.rotate(-0.14);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: orbitRx * 2,
      height: orbitRy * 2,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .04),
            AppColors.auroraTeal.withValues(alpha: .45),
            Colors.white.withValues(alpha: .04),
          ],
        ).createShader(rect),
    );

    // Pontos brilhantes na órbita (halo + núcleo).
    const dots = [(-0.62, 2.6, 0.30), (2.35, 3.2, 0.55), (1.15, 2.0, 0.45)];
    for (final (t, haloR, coreR) in dots) {
      final p = Offset(orbitRx * math.cos(t), orbitRy * math.sin(t));
      canvas.drawCircle(
        p,
        haloR,
        Paint()..color = AppColors.auroraTeal.withValues(alpha: .25),
      );
      canvas.drawCircle(
        p,
        coreR,
        Paint()..color = Colors.white.withValues(alpha: .95),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WelcomeScenePainter oldDelegate) =>
      oldDelegate.sphereCenter != sphereCenter ||
      oldDelegate.orbitRx != orbitRx ||
      oldDelegate.orbitRy != orbitRy;
}

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Focus ring da Nebula: stroke de 3px em gradiente `nebulaViolet` →
/// `auroraTeal` com halo sutil em violeta.
///
/// Padroniza a espessura (a crítica detectou 2px e 3px conviverem) e troca
/// a cor chapada pelo gradiente da marca em todos os componentes focáveis
/// (D-pad/TV e desktop).
class NebulaFocusRingPainter extends CustomPainter {
  /// Raio dos cantos — deve casar com o borderRadius do componente focado.
  final double radius;

  /// Espessura padrão de 3px (10-foot viewing).
  final double strokeWidth;

  final bool withGlow;

  const NebulaFocusRingPainter({
    this.radius = 8,
    this.strokeWidth = 3,
    this.withGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final ring = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    // Halo em duas passadas concêntricas de alpha decrescente — lê como
    // glow em fundo void950 sem o custo de ImageFilter.blur em TV.
    if (withGlow) {
      const spreads = [4.0, 10.0];
      const alphas = [0.12, 0.05];
      for (var i = 0; i < spreads.length; i++) {
        canvas.drawRRect(
          ring,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + spreads[i] * 2
            ..color = AppColors.nebulaViolet.withValues(alpha: alphas[i]),
        );
      }
    }

    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.nebulaViolet, AppColors.auroraTeal],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(NebulaFocusRingPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.withGlow != withGlow;
}

/// Widget utilitário que desenha [NebulaFocusRingPainter] sobre [child]
/// quando [focused].
class NebulaFocusRing extends StatelessWidget {
  final bool focused;
  final double radius;
  final double strokeWidth;
  final bool withGlow;
  final Widget child;

  const NebulaFocusRing({
    super.key,
    required this.focused,
    this.radius = 8,
    this.strokeWidth = 3,
    this.withGlow = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: focused
          ? NebulaFocusRingPainter(
              radius: radius,
              strokeWidth: strokeWidth,
              withGlow: withGlow,
            )
          : null,
      child: child,
    );
  }
}

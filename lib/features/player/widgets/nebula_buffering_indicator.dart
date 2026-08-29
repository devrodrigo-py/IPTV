import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Indicador de buffering da Nebula: contorno do triângulo de play da marca
/// (mesmo motivo do `nebula_icon.png`) com pulso de brilho em ciclo de
/// ~1.2s (ease-in-out).
///
/// Resolve o Issue #1 da crítica — nenhum feedback durante o buffer — e a
/// ausência de micro-interação própria, com uma peça só. Não é usado
/// `CircularProgressIndicator` sozinho (ver DESIGN.md §4).
///
/// Só fica visível após [gracePeriod] tentando conectar, para não piscar
/// em streams que respondem rápido.
class NebulaBufferingIndicator extends StatefulWidget {
  final double size;
  final Duration gracePeriod;

  const NebulaBufferingIndicator({
    super.key,
    this.size = 72,
    this.gracePeriod = const Duration(seconds: 2),
  });

  @override
  State<NebulaBufferingIndicator> createState() =>
      _NebulaBufferingIndicatorState();
}

class _NebulaBufferingIndicatorState extends State<NebulaBufferingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  Timer? _graceTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _graceTimer = Timer(widget.gracePeriod, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _visible ? 1 : 0,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => CustomPaint(
          painter: _PlayTrianglePainter(glow: _pulse.value),
          size: Size.square(widget.size),
        ),
      ),
    );
  }
}

/// Desenha o contorno do triângulo de play com cantos arredondados e glow
/// em `nebulaViolet` cuja intensidade acompanha o pulso.
class _PlayTrianglePainter extends CustomPainter {
  /// 0..1 — intensidade atual do pulso de brilho.
  final double glow;

  const _PlayTrianglePainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final triangleHeight = s * 0.56;
    final triangleWidth = s * 0.42;
    final left = (size.width - triangleWidth) / 2;
    final top = (size.height - triangleHeight) / 2;

    final apex = Offset(left + triangleWidth, top + triangleHeight / 2);
    final topLeft = Offset(left, top);
    final bottomLeft = Offset(left, top + triangleHeight);
    final path = _roundedTrianglePath(
      [topLeft, bottomLeft, apex],
      cornerRadius: s * 0.07,
    );

    final strokeWidth = s * 0.055;

    // Glow violeta por trás do contorno, pulsando junto.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.nebulaViolet.withValues(alpha: 0.35 * glow),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.55 + 0.45 * glow),
    );
  }

  /// Triângulo fechado com cantos arredondados via quadráticas em cada
  /// vértice.
  Path _roundedTrianglePath(
    List<Offset> corners, {
    required double cornerRadius,
  }) {
    final path = Path();
    for (var i = 0; i < corners.length; i++) {
      final prev = corners[(i + corners.length - 1) % corners.length];
      final curr = corners[i];
      final next = corners[(i + 1) % corners.length];

      final inDir = (prev - curr) / (prev - curr).distance;
      final outDir = (next - curr) / (next - curr).distance;

      final start = curr + inDir * cornerRadius;
      final end = curr + outDir * cornerRadius;

      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, end.dx, end.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_PlayTrianglePainter oldDelegate) =>
      oldDelegate.glow != glow;
}

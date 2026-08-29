import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';

/// Indicador "ao vivo" da Nebula: ponto pulsante em `auroraTeal` com halo
/// em expansão, substituindo o vermelho piscante padrão de players.
///
/// O teal tem papel semântico fixo na marca (status ao vivo/online), então
/// o mesmo widget serve para badge de canal, EPG ("Agora") e player.
class LiveIndicator extends StatefulWidget {
  /// Rótulo opcional exibido ao lado do ponto (ex.: "AO VIVO", "Agora").
  final String? label;

  /// Diâmetro do ponto.
  final double dotSize;

  final Color color;

  const LiveIndicator({
    super.key,
    this.label,
    this.dotSize = 8,
    this.color = AppColors.auroraTeal,
  });

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dotOpacity;
  late final Animation<double> _haloScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _dotOpacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _haloScale = Tween<double>(begin: 1.0, end: 2.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = widget.dotSize;
    final haloArea = dot * 2.6;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: haloArea,
          height: haloArea,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                // Halo em expansão — Transform.scale evita relayout por frame.
                Transform.scale(
                  scale: _haloScale.value,
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(
                          alpha: (1 - (_haloScale.value - 1) / 1.1) * 0.45,
                        ),
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _dotOpacity,
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(width: 6),
          Text(
            widget.label!.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: widget.color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

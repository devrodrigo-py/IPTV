import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Shared Nebula brand lockup used in navigation, onboarding and empty states.
class NebulaBrand extends StatelessWidget {
  final double height;
  final bool compact;
  final bool preserveArtwork;

  const NebulaBrand({
    super.key,
    this.height = 34,
    this.compact = false,
    this.preserveArtwork = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!compact && preserveArtwork) {
      // The supplied horizontal logo contains a generous transparent tail.
      // Crop it at layout time so the mark remains legible in compact UI.
      return SizedBox(
        height: height,
        width: height * 2.55,
        child: Image.asset(
          'assets/branding/nebula_logo_transparent.png',
          fit: BoxFit.cover,
          alignment: Alignment.centerLeft,
          errorBuilder: (_, __, ___) => const Text(
            'NEBULA',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
        ),
      );
    }
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
              Text(
                'NEBULA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height * .38,
                  height: .92,
                  letterSpacing: height * .025,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'IPTV',
                style: TextStyle(
                  color: const Color(0xFF5BE8D5),
                  fontSize: height * .18,
                  height: 1,
                  letterSpacing: height * .14,
                  fontWeight: FontWeight.w700,
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
      errorBuilder: (_, __, ___) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill_rounded,
              color: AppColors.primary, size: 28),
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
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      return Container(
        margin: const EdgeInsets.all(16),
        height: compact ? 390 : 276,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF11102B), Color(0xFF2B247E), Color(0xFF086B70)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .25),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(children: [
          Positioned(
            right: compact ? -52 : -28,
            top: compact ? 190 : -44,
            child: Opacity(
              opacity: .88,
              child: Image.asset(
                'assets/branding/nebula_icon.png',
                height: compact ? 240 : 330,
              ),
            ),
          ),
          Positioned(
            right: compact ? 20 : 270,
            top: 24,
            child: _StatusPill(label: 'PRONTO PARA COMEÇAR'),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(32, 30, compact ? 32 : 340, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NebulaBrand(height: 30, preserveArtwork: true),
                const Spacer(),
                Text(
                  'Sua TV merece\num universo inteiro.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 27 : 32,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Conecte sua fonte e a Nebula organiza canais, filmes e séries em uma experiência feita para você.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                if (onAction != null)
                  FilledButton.icon(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF211D62),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text('Conectar minha fonte'),
                  ),
              ],
            ),
          ),
          if (!compact)
            Positioned(
              right: 34,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _FeatureLine(Icons.live_tv_rounded, 'Canais ao vivo'),
                  SizedBox(height: 10),
                  _FeatureLine(Icons.movie_filter_rounded, 'Filmes e séries'),
                  SizedBox(height: 10),
                  _FeatureLine(Icons.auto_awesome_rounded, 'Biblioteca inteligente'),
                ],
              ),
            ),
        ]),
      );
    });
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
      );
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureLine(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]);
}

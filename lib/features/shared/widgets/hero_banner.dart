import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/nebula_cached_image.dart';

/// Data model for a hero banner item.
class HeroBannerItem {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onPlay;
  final VoidCallback? onDetails;

  const HeroBannerItem({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onPlay,
    this.onDetails,
  });
}

/// Netflix-style hero banner with auto-advancing pages.
///
/// Full-width banner (~300px) with backdrop image, gradient overlay,
/// title, subtitle, and action buttons.
/// Auto-advances every 8 seconds when multiple items are provided.
class HeroBanner extends StatefulWidget {
  final List<HeroBannerItem> items;
  final double height;

  const HeroBanner({
    super.key,
    required this.items,
    this.height = 320,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.items.length > 1) {
      _startAutoAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % widget.items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Page view with banner items
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, index) {
              return _HeroBannerPage(item: widget.items[index]);
            },
          ),

          // Dot indicators (bottom center)
          if (widget.items.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 20 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroBannerPage extends StatelessWidget {
  final HeroBannerItem item;

  const _HeroBannerPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image or gradient
        if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
          Stack(
            fit: StackFit.expand,
            children: [
              // Blurred fill (handles any aspect ratio gracefully)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: NebulaCachedImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  placeholder: _buildGradientBackground(),
                ),
              ),
              // Sharp image centered
              NebulaCachedImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.contain,
                cacheWidth: 800,
                placeholder: const SizedBox.shrink(),
              ),
            ],
          )
        else
          _buildGradientBackground(),

        // Dark gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.3),
                AppColors.background.withValues(alpha: 0.8),
                AppColors.background,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),

        // Left gradient for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.background.withValues(alpha: 0.7),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6],
            ),
          ),
        ),

        // Content (title + buttons)
        Positioned(
          left: 32,
          bottom: 48,
          right: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                item.title,
                style: AppTypography.display.copyWith(
                  fontSize: 28,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (item.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.subtitle!,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Play button
                  if (item.onPlay != null)
                    ElevatedButton.icon(
                      onPressed: item.onPlay,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Assistir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Details button
                  if (item.onDetails != null)
                    OutlinedButton.icon(
                      onPressed: item.onDetails,
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Detalhes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
    );
  }
}

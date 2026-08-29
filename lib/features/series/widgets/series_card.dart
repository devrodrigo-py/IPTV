import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';

/// A card displaying a series poster and title.
///
/// Similar to VodCard but with a "Series" badge indicator.
class SeriesCard extends StatelessWidget {
  final SeriesItem series;
  final VoidCallback onTap;

  const SeriesCard({
    super.key,
    required this.series,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWidget(
      onPressed: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      builder: (context, isFocused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: isFocused
              ? (Matrix4.identity()..scale(1.03))
              : Matrix4.identity(),
          // O anel de foco (3px, gradiente violeta→teal) é desenhado pelo
          // FocusableWidget que envolve este builder.
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image or placeholder
                      if (series.displayPosterUrl != null &&
                          series.displayPosterUrl!.isNotEmpty)
                        Image.network(
                          series.displayPosterUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          cacheHeight: 450,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(),
                        )
                      else
                        _buildPlaceholder(),

                      // Bottom gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black87,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // "Série" badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SÉRIE',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),

                      // Rating badge
                      if ((series.tmdbRating != null &&
                              series.tmdbRating! > 0) ||
                          (series.rating != null &&
                              series.rating!.isNotEmpty &&
                              series.rating != '0'))
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '★ ${series.tmdbRating != null
                                  ? series.tmdbRating!.toStringAsFixed(1)
                                  : series.rating}',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Focus play icon
                      if (isFocused)
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Title bar
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.name,
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((series.tmdbGenres ?? series.genre) != null &&
                          (series.tmdbGenres ?? series.genre)!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          (series.tmdbGenres ?? series.genre)!,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.tv_rounded,
          size: 40,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

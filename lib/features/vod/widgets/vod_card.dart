import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/vod/providers/vod_provider.dart';

/// A card displaying a movie poster and title.
///
/// Designed in Netflix/HBO style with rounded corners, gradient overlay,
/// and focus support for keyboard/D-pad navigation.
class VodCard extends StatelessWidget {
  final VodItem movie;
  final VoidCallback onTap;

  const VodCard({
    super.key,
    required this.movie,
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
                      if (movie.displayPosterUrl != null &&
                          movie.displayPosterUrl!.isNotEmpty)
                        Image.network(
                          movie.displayPosterUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          cacheHeight: 450,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(),
                        )
                      else
                        _buildPlaceholder(),

                      // Bottom gradient for text readability
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

                      // Rating badge
                      if ((movie.tmdbRating != null &&
                              movie.tmdbRating! > 0) ||
                          (movie.rating != null &&
                              movie.rating!.isNotEmpty &&
                              movie.rating != '0'))
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '★ ${movie.displayRating}',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Play icon on hover/focus
                      if (isFocused)
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
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
                  child: Text(
                    movie.name,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
          Icons.movie_rounded,
          size: 40,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

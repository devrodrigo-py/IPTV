import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';

/// Interactive 5-star rating widget with half-star support.
class StarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final bool compact;
  final bool showValue;

  const StarRating({
    super.key,
    this.rating = 0.0,
    this.onRatingChanged,
    this.compact = false,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final starSize = compact ? 18.0 : 28.0;
    final spacing = compact ? 2.0 : 4.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++) ...[
          GestureDetector(
            onTapDown: onRatingChanged != null
                ? (details) {
                    // Calculate if left half or right half was tapped
                    final localX = details.localPosition.dx;
                    final halfStar = localX < starSize / 2;
                    final value = halfStar ? i - 0.5 : i.toDouble();
                    // If tapping same rating, clear it
                    if (value == rating) {
                      onRatingChanged!(0.0);
                    } else {
                      onRatingChanged!(value);
                    }
                  }
                : null,
            child: SizedBox(
              width: starSize,
              height: starSize,
              child: _buildStar(i, starSize),
            ),
          ),
          if (i < 5) SizedBox(width: spacing),
        ],
        if (showValue && rating > 0) ...[
          SizedBox(width: compact ? 6 : 10),
          Text(
            rating.toStringAsFixed(1),
            style:
                (compact ? AppTypography.caption : AppTypography.body).copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int starIndex, double size) {
    if (rating >= starIndex) {
      // Full star
      return Icon(
        Icons.star_rounded,
        size: size,
        color: Colors.amber,
      );
    } else if (rating >= starIndex - 0.5) {
      // Half star
      return Icon(
        Icons.star_half_rounded,
        size: size,
        color: Colors.amber,
      );
    } else {
      // Empty star
      return Icon(
        Icons.star_outline_rounded,
        size: size,
        color: AppColors.textSecondary,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/domain/services/quality_service.dart';

/// Quality selector popup for the player.
/// Shows available quality variants with a checkmark on the selected one.
class QualitySelector extends StatelessWidget {
  final List<QualityVariant> variants;
  final String currentQuality;
  final ValueChanged<QualityVariant?> onQualitySelected;

  const QualitySelector({
    super.key,
    required this.variants,
    required this.currentQuality,
    required this.onQualitySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if there are quality options
    if (variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          currentQuality == 'Auto' ? 'AUTO' : currentQuality,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        if (value == 'auto') {
          onQualitySelected(null); // null means auto
        } else {
          final variant = variants.firstWhere(
            (v) => v.name == value,
            orElse: () => variants.first,
          );
          onQualitySelected(variant);
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        // Auto option
        items.add(PopupMenuItem<String>(
          value: 'auto',
          child: Row(
            children: [
              if (currentQuality == 'Auto')
                const Icon(Icons.check_rounded, size: 18, color: AppColors.primary)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text('Auto', style: AppTypography.body),
              const Spacer(),
              Text(
                'Adaptável',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ));

        items.add(const PopupMenuDivider());

        // Quality variants
        for (final variant in variants) {
          final label = _getQualityLabel(variant.name);
          items.add(PopupMenuItem<String>(
            value: variant.name,
            child: Row(
              children: [
                if (currentQuality == variant.name)
                  const Icon(Icons.check_rounded, size: 18, color: AppColors.primary)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(variant.name, style: AppTypography.body),
                const Spacer(),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ));
        }

        return items;
      },
    );
  }

  String _getQualityLabel(String quality) {
    switch (quality.toUpperCase()) {
      case 'FHD':
        return '1080p';
      case 'HD':
        return '720p';
      case 'SD':
        return '480p';
      default:
        return '';
    }
  }
}

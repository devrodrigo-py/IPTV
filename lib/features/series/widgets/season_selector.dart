import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';

/// Season selector tabs — displays season buttons (T1, T2, T3...)
/// in a horizontal scrollable row, Netflix-style.
class SeasonSelector extends StatelessWidget {
  final List<SeasonItem> seasons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SeasonSelector({
    super.key,
    required this.seasons,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final season = seasons[index];
          final isSelected = index == selectedIndex;
          final label = season.name ?? 'Temporada ${season.seasonNumber}';

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border:
                    isSelected ? null : Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/features/shared/widgets/content_card.dart';

/// Data model for items in a content row.
class ContentRowItem {
  final String title;
  final String? imageUrl;
  final String? subtitle;
  final double? progress;
  final String? badge;
  final IconData fallbackIcon;
  final int? channelId;

  const ContentRowItem({
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.progress,
    this.badge,
    this.fallbackIcon = Icons.movie_rounded,
    this.channelId,
  });
}

/// Netflix-style horizontal content row with header and scrollable cards.
///
/// Features:
/// - Category title header with "Ver todos >" button
/// - Horizontal scrolling list of ContentCards
/// - Consistent spacing and padding
/// - Right-click context menu for shortcuts
class ContentRow extends StatelessWidget {
  final String title;
  final List<ContentRowItem> items;
  final VoidCallback? onSeeAll;
  final void Function(int index)? onItemTap;
  final void Function(int index, Offset position)? onItemSecondaryTap;
  final double cardWidth;
  final double height;

  const ContentRow({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    this.onItemTap,
    this.onItemSecondaryTap,
    this.cardWidth = 140,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver todos', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Horizontal scroll list
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < items.length - 1 ? 12 : 0,
                ),
                child: ContentCard(
                  title: item.title,
                  imageUrl: item.imageUrl,
                  subtitle: item.subtitle,
                  progress: item.progress,
                  badge: item.badge,
                  fallbackIcon: item.fallbackIcon,
                  width: cardWidth,
                  onTap: onItemTap != null ? () => onItemTap!(index) : null,
                  onSecondaryTap: onItemSecondaryTap != null
                      ? (position) => onItemSecondaryTap!(index, position)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

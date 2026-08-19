import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// A single channel tile in the channel list.
///
/// Displays logo placeholder, name, group, and favorite toggle.
/// Supports focus for keyboard/D-pad navigation.
class ChannelListTile extends StatelessWidget {
  final Channel channel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChannelListTile({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FocusableWidget(
        onPressed: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        builder: (context, isFocused) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isFocused ? AppColors.surfaceElevated : AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Row(
              children: [
                // Logo placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: channel.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            channel.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.live_tv_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.live_tv_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                ),
                const SizedBox(width: 12),

                // Name and group
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: AppTypography.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (channel.groupName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          channel.groupName!,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Favorite button
                IconButton(
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: onFavoriteToggle,
                  splashRadius: 18,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/cached_logo.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';

/// A tile displaying a single search result.
class SearchResultTile extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 50,
          height: 50,
          child: item.logoUrl != null && item.logoUrl!.isNotEmpty
              ? CachedLogo(
                  imageUrl: item.logoUrl!,
                  size: 50,
                )
              : Container(
                  color: AppColors.surfaceElevated,
                  child: Icon(
                    item.isLive
                        ? Icons.live_tv_rounded
                        : item.isVod
                            ? Icons.movie_rounded
                            : Icons.tv_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
        ),
      ),
      title: Text(
        item.name,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.groupName != null
          ? Text(
              item.groupName!,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          item.isSeries
              ? Icons.arrow_forward_rounded
              : Icons.play_arrow_rounded,
          color: AppColors.primary,
          size: 18,
        ),
      ),
    );
  }
}

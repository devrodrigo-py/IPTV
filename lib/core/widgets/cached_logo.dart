import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/widgets/nebula_cached_image.dart';

/// Widget that displays a channel logo.
///
/// On native: resolves the image through ImageCacheService (disk cache,
/// spec §4.7) via [NebulaCachedImage].
/// On web: falls back to Image.network with the browser cache.
/// Cache errors never break the UI (spec §4.7).
class CachedLogo extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const CachedLogo({
    super.key,
    required this.imageUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return NebulaCachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      cacheWidth: 96,
      cacheHeight: 96,
      placeholder: _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.live_tv_rounded,
        size: size * 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}

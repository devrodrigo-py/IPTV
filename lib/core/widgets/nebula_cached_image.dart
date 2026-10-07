import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/cache/image_cache_provider.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Image widget backed by [ImageCacheService] (spec §4.7).
///
/// Behavior:
/// - Null/empty [imageUrl] → [placeholder].
/// - On web (`kIsWeb`) the disk cache (dart:io) is not used: renders plain
///   `Image.network` (browser HTTP cache) with `errorBuilder` → [placeholder],
///   same visual behavior as a raw `Image.network`.
/// - On native platforms the image is resolved to a local [File] through
///   `imageCacheServiceProvider` and rendered with `Image.file`, supporting
///   [cacheWidth]/[cacheHeight] decode downsampling. While the file is being
///   resolved → [placeholder]. Download/decode failures → [placeholder].
///
/// Cache failures never break the UI (spec §4.7).
class NebulaCachedImage extends ConsumerWidget {
  const NebulaCachedImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
  });

  /// Remote image URL. Null or empty renders [placeholder].
  final String? imageUrl;

  final BoxFit? fit;
  final double? width;
  final double? height;

  /// Decode downsampling (passed to `Image.file` on native platforms).
  final int? cacheWidth;
  final int? cacheHeight;

  /// Shown while loading, on failure, or when the URL is null/empty.
  ///
  /// Defaults to a neutral image icon over [AppColors.surfaceElevated].
  final Widget? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _buildPlaceholder();
    }

    // dart:io (ImageCacheService) cannot work on web — keep the browser
    // HTTP cache path with the same visual fallbacks as a raw Image.network.
    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return FutureBuilder<File?>(
      future: ref.read(imageCacheServiceProvider).getImage(url),
      builder: (context, snapshot) {
        final file = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        if (file == null) {
          // Waiting, download failed, or unexpected error → placeholder.
          return _buildPlaceholder();
        }
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    final custom = placeholder;
    if (custom != null) return custom;
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}

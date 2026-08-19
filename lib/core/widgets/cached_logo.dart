import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/cache/image_cache_service.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Widget that displays a channel logo with caching.
///
/// Shows a placeholder icon while loading or on failure.
/// Cache errors never break the UI (spec §4.7).
class CachedLogo extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final ImageCacheService cacheService;

  const CachedLogo({
    super.key,
    required this.imageUrl,
    required this.cacheService,
    this.size = 48,
  });

  @override
  State<CachedLogo> createState() => _CachedLogoState();
}

class _CachedLogoState extends State<CachedLogo> {
  File? _cachedFile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final file = await widget.cacheService.getImage(widget.imageUrl!);
    if (mounted) {
      setState(() {
        _cachedFile = file;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.live_tv_rounded,
        size: widget.size * 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}

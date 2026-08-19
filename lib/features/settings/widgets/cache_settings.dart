import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/cache/image_cache_service.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';

/// Settings widget for managing the image cache.
class CacheSettings extends StatefulWidget {
  final ImageCacheService cacheService;

  const CacheSettings({
    super.key,
    required this.cacheService,
  });

  @override
  State<CacheSettings> createState() => _CacheSettingsState();
}

class _CacheSettingsState extends State<CacheSettings> {
  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    return FocusableWidget(
      onPressed: _clearing ? null : _clearCache,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      builder: (context, isFocused) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.cached_rounded,
                size: 22,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Limpar cache de imagens',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _clearing ? 'Limpando...' : 'Logos e thumbnails em disco',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (_clearing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _clearCache() async {
    setState(() => _clearing = true);
    await widget.cacheService.clearAll();
    if (mounted) {
      setState(() => _clearing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache limpo com sucesso'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

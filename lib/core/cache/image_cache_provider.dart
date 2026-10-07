import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/cache/image_cache_service.dart';

/// Singleton [ImageCacheService] for the whole app (spec §4.7).
///
/// Used by `NebulaCachedImage` to resolve remote images to local files on
/// native platforms. On web the service is never invoked (the widget falls
/// back to `Image.network`), so no platform-specific wiring is needed here.
final imageCacheServiceProvider = Provider<ImageCacheService>((ref) {
  return ImageCacheService();
});

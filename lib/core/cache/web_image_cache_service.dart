/// Web-compatible image cache stub.
///
/// On web, we rely on the browser's HTTP cache for images.
/// This class exists to satisfy the type system when
/// ImageCacheService is referenced in platform-agnostic code.
/// The web UI should use Image.network directly.
class WebImageCacheService {
  final Duration expiration;

  WebImageCacheService({
    this.expiration = const Duration(days: 7),
  });

  Future<void> init() async {}
  Future<void> clearAll() async {}
  Future<int> clearExpired() async => 0;
}

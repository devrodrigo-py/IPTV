import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/cache/image_cache_service.dart';

void main() {
  group('ImageCacheService', () {
    test('should be instantiable with defaults', () {
      final service = ImageCacheService();
      expect(service, isNotNull);
      expect(service.expiration, const Duration(days: 7));
    });

    test('should accept custom expiration', () {
      final service = ImageCacheService(
        expiration: const Duration(hours: 1),
      );
      expect(service.expiration, const Duration(hours: 1));
    });

    // Note: Tests that call init()/getImage() require platform plugins
    // and are covered in integration tests, not unit tests.
  });
}

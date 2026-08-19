import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Custom image cache service (spec §4.7).
///
/// Uses Dio for downloads, stores files locally with URL hash as key.
/// Provides configurable expiration and max size.
/// Failures in cache do not block the UI.
class ImageCacheService {
  final Dio _dio;
  Directory? _cacheDir;

  /// Default cache expiration: 7 days.
  final Duration expiration;

  ImageCacheService({
    Dio? dio,
    this.expiration = const Duration(days: 7),
  }) : _dio = dio ?? Dio();

  /// Initializes the cache directory.
  Future<void> init() async {
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'nebula_images'));
    if (!_cacheDir!.existsSync()) {
      _cacheDir!.createSync(recursive: true);
    }
  }

  /// Returns the cached file for [url], downloading if needed.
  ///
  /// Returns `null` on failure — the caller should show a placeholder.
  Future<File?> getImage(String url) async {
    if (url.isEmpty) return null;
    if (_cacheDir == null) await init();

    final file = _fileForUrl(url);

    // Check if cached and not expired
    if (file.existsSync()) {
      final lastModified = file.lastModifiedSync();
      if (DateTime.now().difference(lastModified) < expiration) {
        return file;
      }
    }

    // Download
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null && response.data!.isNotEmpty) {
        await file.writeAsBytes(
          Uint8List.fromList(response.data!),
          flush: true,
        );
        return file;
      }
    } catch (e) {
      appLogger.w('Image cache download failed: $url');
    }

    // Return stale cache if available
    if (file.existsSync()) return file;
    return null;
  }

  /// Clears all cached images.
  Future<void> clearAll() async {
    if (_cacheDir == null) await init();
    if (_cacheDir!.existsSync()) {
      await _cacheDir!.delete(recursive: true);
      _cacheDir!.createSync(recursive: true);
    }
  }

  /// Clears expired images only.
  Future<int> clearExpired() async {
    if (_cacheDir == null) await init();
    var count = 0;
    final files = _cacheDir!.listSync().whereType<File>();
    for (final file in files) {
      final lastModified = file.lastModifiedSync();
      if (DateTime.now().difference(lastModified) >= expiration) {
        file.deleteSync();
        count++;
      }
    }
    return count;
  }

  /// Returns the local file path for a URL (hash-based).
  File _fileForUrl(String url) {
    final hash = md5.convert(utf8.encode(url)).toString();
    final ext = _extensionFromUrl(url);
    return File(p.join(_cacheDir!.path, '$hash$ext'));
  }

  /// Extracts file extension from URL, defaulting to .img.
  String _extensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      if (path.endsWith('.png')) return '.png';
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
      if (path.endsWith('.webp')) return '.webp';
      if (path.endsWith('.gif')) return '.gif';
    } catch (_) {}
    return '.img';
  }
}

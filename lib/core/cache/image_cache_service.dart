import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Asynchronous disk cache with a bounded memory index and download pool.
class ImageCacheService {
  final Dio _dio;
  Directory? _cacheDir;
  Future<void>? _initialization;
  final _resolved = <String, Future<File?>>{};
  final _waiters = Queue<Completer<void>>();
  int _active = 0, _writes = 0;
  final Duration expiration;
  final int maxBytes, maxEntries, maxConcurrentDownloads;
  ImageCacheService(
      {Dio? dio,
      Directory? directory,
      this.expiration = const Duration(days: 7),
      this.maxBytes = 128 * 1024 * 1024,
      this.maxEntries = 256,
      this.maxConcurrentDownloads = 4})
      : assert(maxEntries > 0),
        assert(maxConcurrentDownloads > 0),
        _cacheDir = directory,
        _dio = dio ??
            Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 15)));
  Future<void> init() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    _cacheDir ??= Directory(
        p.join((await getApplicationCacheDirectory()).path, 'nebula_images'));
    await _cacheDir!.create(recursive: true);
    await _prune();
  }

  Future<File?> getImage(String url) {
    if (url.isEmpty) return Future.value(null);
    final existing = _resolved.remove(url);
    if (existing != null) {
      _resolved[url] = existing;
      return existing;
    }
    final future = _load(url);
    _resolved[url] = future;
    while (_resolved.length > maxEntries) {
      _resolved.remove(_resolved.keys.first);
    }
    return future;
  }

  Future<void> _acquire() async {
    if (_active >= maxConcurrentDownloads) {
      final turn = Completer<void>();
      _waiters.add(turn);
      await turn.future;
    } else {
      _active++;
    }
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else {
      _active--;
    }
  }

  Future<File?> _load(String url) async {
    File? file;
    try {
      await init();
      file = File(
          p.join(_cacheDir!.path, '${sha256.convert(utf8.encode(url))}.img'));
      if (await file.exists() &&
          DateTime.now().difference(await file.lastModified()) < expiration) {
        return file;
      }
      await _acquire();
      try {
        final response = await _dio.get<List<int>>(url,
            options: Options(responseType: ResponseType.bytes));
        final bytes = response.data;
        if (bytes != null &&
            bytes.isNotEmpty &&
            bytes.length <= 12 * 1024 * 1024) {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
          if (++_writes % 32 == 0) await _prune();
          return file;
        }
      } finally {
        _release();
      }
    } catch (_) {
      appLogger.d('image_cache.load_failed');
    }
    _resolved.remove(url);
    if (file != null && await file.exists()) return file;
    return null;
  }

  Future<void> clearAll() async {
    _resolved.clear();
    await init();
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) await entity.delete();
    }
  }

  Future<int> clearExpired() async {
    _resolved.clear();
    await init();
    var count = 0;
    await for (final entity in _cacheDir!.list()) {
      if (entity is File &&
          DateTime.now().difference(await entity.lastModified()) >=
              expiration) {
        await entity.delete();
        count++;
      }
    }
    return count;
  }

  Future<void> _prune() async {
    final entries = <({File file, FileStat stat})>[];
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        entries.add((file: entity, stat: await entity.stat()));
      }
    }
    entries.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    var total = entries.fold<int>(0, (sum, entry) => sum + entry.stat.size);
    for (final entry in entries) {
      if (total <= maxBytes) break;
      await entry.file.delete();
      total -= entry.stat.size;
    }
    _resolved.clear();
  }
}

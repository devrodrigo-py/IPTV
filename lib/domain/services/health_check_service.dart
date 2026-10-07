import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/daos/health_check_dao.dart';

/// Configuration for channel health checks.
class HealthCheckConfig {
  /// Timeout for establishing a connection to the stream.
  final Duration connectionTimeout;

  /// Maximum number of concurrent health checks.
  final int maxConcurrency;

  /// Interval between checks for stable channels (0 failures).
  final Duration stableChannelInterval;

  /// Interval between checks for unstable channels (1-2 failures).
  final Duration unstableChannelInterval;

  /// Interval between checks for offline channels (3+ failures).
  final Duration offlineChannelInterval;

  /// How many channels to check per batch.
  final int batchSize;

  /// Delay between batches to avoid network saturation.
  final Duration batchDelay;

  const HealthCheckConfig({
    this.connectionTimeout = const Duration(seconds: 8),
    this.maxConcurrency = 5,
    this.stableChannelInterval = const Duration(hours: 24),
    this.unstableChannelInterval = const Duration(hours: 1),
    this.offlineChannelInterval = const Duration(hours: 4),
    this.batchSize = 20,
    this.batchDelay = const Duration(seconds: 2),
  });
}

/// Result of a single channel health check.
class SingleCheckResult {
  final int channelId;
  final bool isOnline;
  final int? latencyMs;
  final String? error;

  const SingleCheckResult({
    required this.channelId,
    required this.isOnline,
    this.latencyMs,
    this.error,
  });

  @override
  String toString() => 'SingleCheckResult(ch=$channelId, online=$isOnline, '
      'latency=${latencyMs}ms${error != null ? ', err=$error' : ''})';
}

/// Callback type for health check progress updates.
typedef HealthCheckProgressCallback = void Function(
  int checked,
  int total,
  int online,
  int offline,
);

/// Service that performs background health checks on IPTV channels.
///
/// Checks channel availability by attempting an HTTP connection and
/// waiting for the first bytes of response. Does NOT download the
/// actual stream content — only verifies connectivity.
///
/// Features:
/// - Concurrency-limited (default 5 simultaneous checks)
/// - Adaptive interval based on failure history
/// - Pauses automatically during active playback
/// - Never blocks UI or stream playback
class ChannelHealthCheckService {
  final HealthCheckDao _dao;
  final HealthCheckConfig config;

  bool _isRunning = false;
  bool _isPaused = false;
  HealthCheckProgressCallback? _progressCallback;

  ChannelHealthCheckService({
    required HealthCheckDao dao,
    this.config = const HealthCheckConfig(),
  }) : _dao = dao;

  /// Whether the service is currently running.
  bool get isRunning => _isRunning;

  /// Whether the service is paused (e.g., during playback).
  bool get isPaused => _isPaused;

  /// Sets a callback for progress updates.
  set onProgress(HealthCheckProgressCallback? callback) {
    _progressCallback = callback;
  }

  /// Starts the background health check loop.
  ///
  /// Continuously checks channels that are due, respecting the
  /// concurrency limit and pausing when playback is active.
  /// Does nothing on web platform.
  Future<void> startBackgroundCheck() async {
    if (kIsWeb) {
      appLogger.d('[HealthCheck] Skipping on web platform');
      return;
    }
    if (_isRunning) return;

    _isRunning = true;
    appLogger.i('[HealthCheck] Background check started');

    while (_isRunning) {
      if (_isPaused) {
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      final channelIds = await _dao.getChannelsDueForCheck(config.batchSize);
      if (channelIds.isEmpty) {
        // Nothing to check right now, sleep a bit
        await Future.delayed(const Duration(minutes: 1));
        continue;
      }

      appLogger
          .d('[HealthCheck] Checking batch of ${channelIds.length} channels');

      // Process in concurrent batches
      int checked = 0;
      int online = 0;
      int offline = 0;

      for (var i = 0; i < channelIds.length; i += config.maxConcurrency) {
        if (!_isRunning || _isPaused) break;

        final batch = channelIds.skip(i).take(config.maxConcurrency).toList();
        final futures = batch.map((id) => _checkAndPersist(id));
        final results = await Future.wait(futures);

        for (final result in results) {
          checked++;
          if (result.isOnline) {
            online++;
          } else {
            offline++;
          }
        }

        _progressCallback?.call(
          checked,
          channelIds.length,
          online,
          offline,
        );

        // Small delay between concurrent batches
        if (i + config.maxConcurrency < channelIds.length) {
          await Future.delayed(config.batchDelay);
        }
      }

      appLogger.i(
        '[HealthCheck] Batch complete: $checked checked, '
        '$online online, $offline offline',
      );

      // Wait before next batch
      await Future.delayed(config.batchDelay);
    }

    appLogger.i('[HealthCheck] Background check stopped');
  }

  /// Pauses health checks (called when user starts playing a stream).
  void pause() {
    _isPaused = true;
    appLogger.d('[HealthCheck] Paused (playback active)');
  }

  /// Resumes health checks.
  void resume() {
    _isPaused = false;
    appLogger.d('[HealthCheck] Resumed');
  }

  /// Stops all health checks.
  void stop() {
    _isRunning = false;
    appLogger.d('[HealthCheck] Stop requested');
  }

  /// Checks a single channel and returns the result immediately.
  ///
  /// This is the public API for on-demand checking (e.g., user
  /// clicks "check now" on a specific channel).
  Future<SingleCheckResult> checkSingleChannel(
    int channelId,
    String streamUrl,
  ) async {
    if (kIsWeb) {
      return SingleCheckResult(
        channelId: channelId,
        isOnline: true, // Assume online on web
        error: 'Health check not available on web',
      );
    }

    final result = await _performCheck(channelId, streamUrl);
    await _persistResult(channelId, result);
    return result;
  }

  /// Checks a batch of channels by their IDs.
  ///
  /// Requires a function to resolve channel ID → stream URL.
  Future<List<SingleCheckResult>> checkBatch(
    List<int> channelIds,
    Future<String?> Function(int channelId) urlResolver,
  ) async {
    final results = <SingleCheckResult>[];

    for (var i = 0; i < channelIds.length; i += config.maxConcurrency) {
      final batch = channelIds.skip(i).take(config.maxConcurrency).toList();
      final futures = batch.map((id) async {
        final url = await urlResolver(id);
        if (url == null) {
          return SingleCheckResult(
            channelId: id,
            isOnline: false,
            error: 'URL not found',
          );
        }
        return _performCheck(id, url);
      });

      final batchResults = await Future.wait(futures);
      for (final result in batchResults) {
        await _persistResult(result.channelId, result);
        results.add(result);
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  /// Checks a channel and persists the result.
  Future<SingleCheckResult> _checkAndPersist(int channelId) async {
    // We need the stream URL — get it from the channels table
    final urlResults = await _dao.customSelect(
      'SELECT stream_url FROM channels WHERE id = ? AND is_active = 1',
      variables: [Variable.withInt(channelId)],
    ).get();

    if (urlResults.isEmpty) {
      return SingleCheckResult(
        channelId: channelId,
        isOnline: false,
        error: 'Channel not found or inactive',
      );
    }

    final streamUrl = urlResults.first.read<String>('stream_url');
    final result = await _performCheck(channelId, streamUrl);
    await _persistResult(channelId, result);
    return result;
  }

  /// Performs the actual connectivity check for a stream URL.
  ///
  /// Uses HttpClient with a short timeout. Only checks if a
  /// response with status 200 is received — does NOT download
  /// the stream content.
  Future<SingleCheckResult> _performCheck(
    int channelId,
    String streamUrl,
  ) async {
    final stopwatch = Stopwatch()..start();
    final client = HttpClient();
    client.connectionTimeout = config.connectionTimeout;

    try {
      final uri = Uri.parse(streamUrl);
      final request = await client.getUrl(uri).timeout(
            config.connectionTimeout,
          );
      request.headers.set('Connection', 'close');

      final response = await request.close().timeout(
            config.connectionTimeout,
          );

      // Status 200 or 206 (partial content) means the stream is available
      final isOnline = response.statusCode == 200 || response.statusCode == 206;
      stopwatch.stop();

      // Drain response to free resources (don't download content)
      await response.drain<void>().timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );

      return SingleCheckResult(
        channelId: channelId,
        isOnline: isOnline,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: isOnline ? null : 'HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      stopwatch.stop();
      return SingleCheckResult(
        channelId: channelId,
        isOnline: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: 'Timeout (${config.connectionTimeout.inSeconds}s)',
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return SingleCheckResult(
        channelId: channelId,
        isOnline: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: 'Socket: ${e.message}',
      );
    } catch (e) {
      stopwatch.stop();
      return SingleCheckResult(
        channelId: channelId,
        isOnline: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Persists the check result in the database.
  Future<void> _persistResult(int channelId, SingleCheckResult result) async {
    final previousFailures = await _dao.getConsecutiveFailures(channelId);
    final newFailures = result.isOnline ? 0 : previousFailures + 1;
    final nextCheck = _calculateNextCheck(newFailures);

    await _dao.upsertCheck(
      channelId: channelId,
      status: result.isOnline ? 'online' : 'offline',
      latencyMs: result.latencyMs,
      consecutiveFailures: newFailures,
      nextCheckAt: nextCheck,
    );
  }

  /// Calculates the next check time based on consecutive failures.
  ///
  /// - 0 failures (stable): check again in 24h
  /// - 1-2 failures (unstable): check again in 1h
  /// - 3+ failures (offline): check again in 4h
  DateTime _calculateNextCheck(int consecutiveFailures) {
    final now = DateTime.now();
    if (consecutiveFailures == 0) {
      return now.add(config.stableChannelInterval);
    }
    if (consecutiveFailures >= 3) {
      return now.add(config.offlineChannelInterval);
    }
    return now.add(config.unstableChannelInterval);
  }
}

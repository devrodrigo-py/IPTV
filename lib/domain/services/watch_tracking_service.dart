import 'dart:async';

import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/daos/watch_stats_dao.dart';

/// Metadata for the content being tracked.
class WatchContentInfo {
  final int channelId;
  final String name;
  final String contentType; // 'live', 'vod', 'series'
  final String? thumbnailUrl;
  final int? seriesId;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? episodeTitle;

  const WatchContentInfo({
    required this.channelId,
    required this.name,
    required this.contentType,
    this.thumbnailUrl,
    this.seriesId,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
  });
}

/// Service that tracks viewing sessions and persists watch data.
///
/// Uses a periodic timer (every 30s) to save progress incrementally.
/// On stop, saves final progress to both watch_history and watch_stats_daily.
class WatchTrackingService {
  final WatchStatsDao _statsDao;

  Timer? _periodicTimer;
  WatchContentInfo? _currentContent;
  DateTime? _sessionStart;
  int _accumulatedMs = 0;
  double _lastProgress = 0.0;
  int _lastTotalDurationMs = 0;

  static const _saveInterval = Duration(seconds: 30);

  WatchTrackingService({required WatchStatsDao statsDao})
      : _statsDao = statsDao;

  /// Starts tracking a viewing session.
  void startTracking(WatchContentInfo content) {
    // Stop any existing session first
    stopTracking();

    _currentContent = content;
    _sessionStart = DateTime.now();
    _accumulatedMs = 0;
    _lastProgress = 0.0;
    _lastTotalDurationMs = 0;

    appLogger.d(
        '[WatchTrack] Started tracking: ${content.name} (${content.contentType})');

    // Start periodic save
    _periodicTimer = Timer.periodic(_saveInterval, (_) => _periodicSave());
  }

  /// Updates the current playback progress (called by player state listener).
  int _lastPositionMs = 0;

  void updateProgress({
    required Duration position,
    required Duration duration,
  }) {
    if (_currentContent == null) return;

    _lastPositionMs = position.inMilliseconds;
    _lastTotalDurationMs = duration.inMilliseconds;

    if (duration.inMilliseconds > 0) {
      _lastProgress =
          (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    } else if (position.inMilliseconds > 0) {
      // Duration unknown — store position as "progress" for resume purposes
      // We'll use total_duration_ms = 0 as signal that we only have position
      _lastProgress = 0.0;
    }

    // Accumulate watch time
    final now = DateTime.now();
    if (_sessionStart != null) {
      _accumulatedMs = now.difference(_sessionStart!).inMilliseconds;
    }
  }

  /// Stops tracking and saves final data.
  Future<void> stopTracking() async {
    if (_currentContent == null) return;

    _periodicTimer?.cancel();
    _periodicTimer = null;

    // Calculate final accumulated time
    if (_sessionStart != null) {
      _accumulatedMs = DateTime.now().difference(_sessionStart!).inMilliseconds;
    }

    // Final save
    await _saveProgress();

    appLogger.d(
      '[WatchTrack] Stopped tracking: ${_currentContent!.name} '
      '(${_accumulatedMs ~/ 1000}s, ${(_lastProgress * 100).toStringAsFixed(1)}%)',
    );

    _currentContent = null;
    _sessionStart = null;
    _accumulatedMs = 0;
    _lastProgress = 0.0;
    _lastTotalDurationMs = 0;
  }

  /// Periodic save (every 30s).
  Future<void> _periodicSave() async {
    if (_currentContent == null) return;
    // Always recalculate accumulated time from session start
    if (_sessionStart != null) {
      _accumulatedMs = DateTime.now().difference(_sessionStart!).inMilliseconds;
    }
    await _saveProgress();
  }

  /// Persists current progress to the database.
  Future<void> _saveProgress() async {
    final content = _currentContent;
    if (content == null || _accumulatedMs < 1000) return; // Skip if < 1s

    // Save to enhanced watch history
    try {
      // If duration is unknown but we have position, store position for resume
      final effectiveTotalDuration = _lastTotalDurationMs > 0
          ? _lastTotalDurationMs
          : _lastPositionMs * 2; // Estimate: assume we're halfway
      final effectiveProgress = _lastTotalDurationMs > 0
          ? _lastProgress
          : (_lastPositionMs > 0 ? 0.5 : 0.0); // Assume ~50% for resume

      await _statsDao.upsertWatchEntry(
        channelId: content.channelId,
        watchedDurationMs:
            _lastPositionMs > 0 ? _lastPositionMs : _accumulatedMs,
        progressPercent: effectiveProgress,
        totalDurationMs: effectiveTotalDuration,
        contentType: content.contentType,
        contentName: content.name,
        seriesId: content.seriesId,
        seasonNumber: content.seasonNumber,
        episodeNumber: content.episodeNumber,
        episodeTitle: content.episodeTitle,
        thumbnailUrl: content.thumbnailUrl,
      );

      // Save to daily stats
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _statsDao.upsertDailyStat(
        date: today,
        channelId: content.channelId,
        contentType: content.contentType,
        watchMs: _accumulatedMs,
      );

      appLogger.d(
          '[WatchTrack] Saved: ${content.name} (${_accumulatedMs ~/ 1000}s)');
    } catch (e) {
      appLogger.w('[WatchTrack] Save failed: $e');
    }
  }

  /// Disposes the service and stops any active tracking.
  void dispose() {
    stopTracking();
  }
}

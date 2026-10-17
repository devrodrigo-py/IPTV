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

/// Persists immutable snapshots, so an old save cannot erase a new session.
class WatchTrackingService {
  final WatchStatsDao _statsDao;
  final Stopwatch _elapsed = Stopwatch();
  Timer? _timer;
  WatchContentInfo? _content;
  int _position = 0, _duration = 0, _savedMs = 0;
  bool _sessionCounted = false;
  Future<void> _writes = Future.value();
  WatchTrackingService({required WatchStatsDao statsDao})
      : _statsDao = statsDao;
  void startTracking(WatchContentInfo content) {
    unawaited(stopTracking());
    _content = content;
    _position = _duration = _savedMs = 0;
    _sessionCounted = false;
    _elapsed.reset();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _save());
  }

  void setPlaying(bool playing) {
    if (_content == null) return;
    if (playing) {
      _elapsed.start();
    } else {
      _elapsed.stop();
    }
  }

  void updateProgress(
      {required Duration position, required Duration duration}) {
    if (_content == null) return;
    _position = position.inMilliseconds;
    _duration = duration.inMilliseconds;
  }

  Future<void> stopTracking() {
    _timer?.cancel();
    _timer = null;
    _elapsed.stop();
    final saved = _save();
    _content = null;
    _elapsed.reset();
    return saved;
  }

  Future<void> _save() {
    final content = _content;
    final elapsed = _elapsed.elapsedMilliseconds;
    if (content == null || elapsed < 1000) return _writes;
    final position = _position;
    final duration = _duration;
    final delta = (elapsed - _savedMs).clamp(0, elapsed);
    final countSession = !_sessionCounted;
    _savedMs = elapsed;
    _sessionCounted = true;
    _writes = _writes.then((_) async {
      try {
        await _statsDao.upsertWatchEntry(
            channelId: content.channelId,
            watchedDurationMs: position,
            progressPercent:
                duration > 0 ? (position / duration).clamp(0, 1) : 0,
            totalDurationMs: duration,
            contentType: content.contentType,
            contentName: content.name,
            seriesId: content.seriesId,
            seasonNumber: content.seasonNumber,
            episodeNumber: content.episodeNumber,
            episodeTitle: content.episodeTitle,
            thumbnailUrl: content.thumbnailUrl);
        if (delta > 0) {
          await _statsDao.upsertDailyStat(
              date: DateTime.now().toIso8601String().substring(0, 10),
              channelId: content.channelId,
              contentType: content.contentType,
              watchMs: delta,
              countSession: countSession);
        }
      } catch (_) {
        appLogger.w('watch.progress.save_failed');
      }
    });
    return _writes;
  }

  void dispose() {
    unawaited(stopTracking());
  }
}

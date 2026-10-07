import 'dart:async';

import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/repositories/epg_repository.dart';

/// Periodically downloads and parses the XMLTV guide of every playlist that
/// declares an `epgUrl` (spec §18 — automatic sync, default 6h, configurable
/// in Configurações → Manutenção).
///
/// Sync on import/refresh is handled by [PlaylistManagementNotifier]; this
/// scheduler covers the periodic cadence while the app is open.
class EpgSyncScheduler {
  EpgSyncScheduler({
    required AppDatabase db,
    required EpgRepository epgRepository,
    Duration Function()? intervalProvider,
  })  : _db = db,
        _epgRepository = epgRepository,
        _intervalProvider =
            intervalProvider ?? (() => const Duration(hours: 6));

  final AppDatabase _db;
  final EpgRepository _epgRepository;
  final Duration Function() _intervalProvider;

  Timer? _timer;
  bool _cycleRunning = false;

  /// Whether a sync cycle is currently in flight.
  bool get isSyncing => _cycleRunning;

  /// Runs one sync cycle now and keeps scheduling. Safe to call repeatedly
  /// (bootstrap and settings) — an already-running scheduler is a no-op.
  void start() {
    if (_timer != null) return;
    appLogger.i(
        '[EPG] Scheduler started (interval: ${_intervalProvider().inHours}h)');
    unawaited(_runCycle());
  }

  /// Applies a changed interval immediately: cancels the pending timer and
  /// starts a fresh cycle (a new schedule must not wait half a period).
  void restart() {
    stop();
    start();
  }

  /// Stops scheduling. A cycle already in flight finishes on its own.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _runCycle() async {
    // Fixed-rate scheduling: the next cycle is armed at cycle start, so a
    // slow sync does not drift the cadence.
    _timer = Timer(_intervalProvider(), _runCycle);
    await syncAll();
  }

  /// Syncs every playlist with an EPG URL. Individual failures are logged
  /// and never abort the remaining playlists.
  Future<void> syncAll() async {
    if (_cycleRunning) return;
    _cycleRunning = true;
    try {
      final playlists = await _db.playlistsDao.getAllPlaylists();
      for (final playlist in playlists) {
        final epgUrl = playlist.epgUrl;
        if (epgUrl == null || epgUrl.isEmpty) continue;

        final result = await _epgRepository.syncEpg(epgUrl);
        result.when(
          success: (r) => appLogger.i(
            '[EPG] Scheduled sync (playlist ${playlist.id}): '
            '${r.programsImported} programs, ${r.channelsMatched} channels matched',
          ),
          failure: (f) => appLogger.w(
            '[EPG] Scheduled sync failed (playlist ${playlist.id}): '
            '${f.message}',
          ),
        );
      }
    } catch (e) {
      appLogger.w('[EPG] Scheduled sync crashed: $e');
    } finally {
      _cycleRunning = false;
    }
  }
}

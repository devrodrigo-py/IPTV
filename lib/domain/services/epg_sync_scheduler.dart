import 'dart:async';

import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/daos/app_settings_dao.dart';
import 'package:nebula_iptv/data/repositories/epg_repository.dart';

/// Periodically downloads and parses the XMLTV guide of every playlist that
/// declares an `epgUrl` (spec §18 — automatic sync, default 6h, configurable
/// in Configurações → Manutenção).
///
/// The cadence survives restarts: the last cycle time is persisted, and a
/// sync only runs when the configured interval has ELAPSED — reopening the
/// app ten times an hour must not re-download a multi-megabyte guide each
/// time (that storm stalled and crashed weak devices). The first check is
/// also deferred [initialDelay] so launch never competes with a download.
///
/// Sync on import/refresh is handled by [PlaylistManagementNotifier]; this
/// scheduler covers the periodic cadence while the app is open.
class EpgSyncScheduler {
  EpgSyncScheduler({
    required AppDatabase db,
    required EpgRepository epgRepository,
    required AppSettingsDao settingsDao,
    Duration Function()? intervalProvider,
    this.initialDelay = const Duration(seconds: 20),
  })  : _db = db,
        _epgRepository = epgRepository,
        _settingsDao = settingsDao,
        _intervalProvider =
            intervalProvider ?? (() => const Duration(hours: 6));

  final AppDatabase _db;
  final EpgRepository _epgRepository;
  final AppSettingsDao _settingsDao;
  final Duration Function() _intervalProvider;

  /// Grace after bootstrap before the first due-check runs.
  final Duration initialDelay;

  Timer? _timer;
  bool _started = false;
  bool _cycleRunning = false;

  /// Whether a sync cycle is currently in flight.
  bool get isSyncing => _cycleRunning;

  /// Starts scheduling. Safe to call repeatedly (bootstrap and settings) —
  /// an already-running scheduler is a no-op.
  void start() {
    // Synchronous guard: _armFirstCycle awaits before arming the timer, so
    // _timer alone would let concurrent start() calls double-schedule.
    if (_started) return;
    _started = true;
    appLogger.i(
        '[EPG] Scheduler started (interval: ${_intervalProvider().inHours}h)');
    unawaited(_armFirstCycle());
  }

  /// Applies a changed interval: re-arms with the new cadence (the last-sync
  /// gate still applies — a recent sync is not repeated).
  void restart() {
    stop();
    start();
  }

  /// Stops scheduling. A cycle already in flight finishes on its own.
  void stop() {
    _started = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _armFirstCycle() async {
    if (_timer != null) return;

    var delay = initialDelay;
    final lastMs = int.tryParse(
        await _settingsDao.getString(kSettingEpgLastSyncAtMs) ?? '');
    if (lastMs != null) {
      final elapsed = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastMs));
      final interval = _intervalProvider();
      if (elapsed < interval) {
        delay = interval - elapsed;
      }
    }

    _timer = Timer(delay, _runCycle);
    appLogger.d('[EPG] Próxima sincronização em ${delay.inMinutes} min');
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
      // Persist even after a failed cycle: a server that is down must not
      // be re-downloaded on every app open.
      await _settingsDao.setString(
        kSettingEpgLastSyncAtMs,
        '${DateTime.now().millisecondsSinceEpoch}',
      );
      _cycleRunning = false;
    }
  }
}

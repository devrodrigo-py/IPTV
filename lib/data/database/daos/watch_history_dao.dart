import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/watch_history_table.dart';

part 'watch_history_dao.g.dart';

/// Data access object for watch history.
@DriftAccessor(tables: [WatchHistoryEntries, Channels])
class WatchHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$WatchHistoryDaoMixin {
  WatchHistoryDao(super.db);

  /// Returns recent watch history ordered by last watched (newest first).
  Future<List<WatchHistoryEntry>> getRecentHistory({int limit = 50}) {
    return (select(watchHistoryEntries)
          ..orderBy([
            (h) => OrderingTerm.desc(h.lastWatchedAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Returns the history entry for a specific channel (if exists).
  Future<WatchHistoryEntry?> getEntryForChannel(int channelId) {
    return (select(watchHistoryEntries)
          ..where((h) => h.channelId.equals(channelId)))
        .getSingleOrNull();
  }

  /// Creates or updates a history entry for a channel.
  Future<int> upsertEntry({
    required int channelId,
    required int watchedDurationMs,
  }) async {
    final existing = await getEntryForChannel(channelId);

    if (existing != null) {
      await (update(watchHistoryEntries)
            ..where((h) => h.id.equals(existing.id)))
          .write(
        WatchHistoryEntriesCompanion(
          lastWatchedAt: Value(DateTime.now()),
          watchedDurationMs: Value(
            existing.watchedDurationMs + watchedDurationMs,
          ),
        ),
      );
      return existing.id;
    } else {
      return into(watchHistoryEntries).insert(
        WatchHistoryEntriesCompanion(
          channelId: Value(channelId),
          watchedDurationMs: Value(watchedDurationMs),
        ),
      );
    }
  }

  /// Deletes a specific history entry.
  Future<int> deleteEntry(int id) {
    return (delete(watchHistoryEntries)..where((h) => h.id.equals(id))).go();
  }

  /// Clears all history.
  Future<int> clearAll() {
    return delete(watchHistoryEntries).go();
  }

  /// Trims history to keep only the most recent [maxEntries].
  Future<void> trimHistory(int maxEntries) async {
    final count = await (selectOnly(watchHistoryEntries)
          ..addColumns([watchHistoryEntries.id.count()]))
        .getSingle();

    final total = count.read(watchHistoryEntries.id.count()) ?? 0;
    if (total <= maxEntries) return;

    // Delete oldest entries beyond the limit
    await customStatement(
      'DELETE FROM watch_history_entries WHERE id NOT IN '
      '(SELECT id FROM watch_history_entries '
      'ORDER BY last_watched_at DESC LIMIT ?)',
      [maxEntries],
    );
  }

  /// Watches recent history (reactive stream).
  Stream<List<WatchHistoryEntry>> watchRecentHistory({int limit = 50}) {
    return (select(watchHistoryEntries)
          ..orderBy([(h) => OrderingTerm.desc(h.lastWatchedAt)])
          ..limit(limit))
        .watch();
  }
}

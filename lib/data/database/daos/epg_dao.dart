import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/epg_programs_table.dart';

part 'epg_dao.g.dart';

/// Data access object for EPG program data.
@DriftAccessor(tables: [EpgPrograms])
class EpgDao extends DatabaseAccessor<AppDatabase> with _$EpgDaoMixin {
  EpgDao(super.db);

  /// Returns current and upcoming programs for a channel.
  Future<List<EpgProgram>> getProgramsForChannel(
    int channelId, {
    DateTime? after,
    int limit = 20,
  }) {
    final now = after ?? DateTime.now().toUtc();
    return (select(epgPrograms)
          ..where(
            (e) =>
                e.channelId.equals(channelId) &
                e.endTimeUtc.isBiggerThanValue(now),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.startTimeUtc)])
          ..limit(limit))
        .get();
  }

  /// Returns the currently airing program for a channel.
  Future<EpgProgram?> getCurrentProgram(int channelId) {
    final now = DateTime.now().toUtc();
    return (select(epgPrograms)
          ..where(
            (e) =>
                e.channelId.equals(channelId) &
                e.startTimeUtc.isSmallerOrEqualValue(now) &
                e.endTimeUtc.isBiggerThanValue(now),
          ))
        .getSingleOrNull();
  }

  /// Inserts EPG programs in batch.
  Future<void> insertPrograms(List<EpgProgramsCompanion> entries) {
    return batch((b) => b.insertAll(epgPrograms, entries));
  }

  /// Deletes all EPG data for a specific channel.
  Future<int> deleteProgramsForChannel(int channelId) {
    return (delete(epgPrograms)..where((e) => e.channelId.equals(channelId)))
        .go();
  }

  /// Deletes expired EPG data (programs that ended before [before]).
  Future<int> deleteExpiredPrograms({DateTime? before}) {
    final cutoff = before ?? DateTime.now().toUtc();
    return (delete(epgPrograms)
          ..where((e) => e.endTimeUtc.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Replaces all EPG data for a channel (delete + insert).
  Future<void> replacePrograms(
    int channelId,
    List<EpgProgramsCompanion> entries,
  ) async {
    await transaction(() async {
      await deleteProgramsForChannel(channelId);
      await insertPrograms(entries);
    });
  }
}

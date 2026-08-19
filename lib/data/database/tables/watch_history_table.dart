import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';

/// SQLite table definition for watch history.
///
/// Tracks viewing sessions. `watchedDurationMs` represents
/// the effective time the user spent watching (not stream duration).
class WatchHistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channelId => integer().references(Channels, #id)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastWatchedAt =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get watchedDurationMs => integer().withDefault(const Constant(0))();
}

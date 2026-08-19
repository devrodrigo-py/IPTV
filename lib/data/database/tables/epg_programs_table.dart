import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';

/// SQLite table definition for EPG program entries.
///
/// All times are stored in UTC (normalized at parse time).
/// Conversion to local timezone happens only at the presentation layer.
class EpgPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channelId => integer().references(Channels, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTimeUtc => dateTime()();
  DateTimeColumn get endTimeUtc => dateTime()();
  TextColumn get category => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
}

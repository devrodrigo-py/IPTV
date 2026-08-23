import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/tables/series_table.dart';

/// SQLite table definition for seasons within a series.
class Seasons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seriesId => integer().references(SeriesItems, #id)();
  IntColumn get seasonNumber => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  IntColumn get episodeCount => integer().nullable()();
  TextColumn get airDate => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

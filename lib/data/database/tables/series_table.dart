import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';

/// SQLite table definition for TV series.
class SeriesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(Playlists, #id)();
  TextColumn get sourceId => text()();
  TextColumn get name => text().withLength(min: 1, max: 500)();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get plot => text().nullable()();
  TextColumn get cast => text().nullable()();
  TextColumn get director => text().nullable()();
  TextColumn get genre => text().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get year => text().nullable()();
  TextColumn get backdropUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/tables/seasons_table.dart';
import 'package:nebula_iptv/data/database/tables/series_table.dart';

/// SQLite table definition for episodes within a season.
class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seriesId => integer().references(SeriesItems, #id)();
  IntColumn get seasonId => integer().references(Seasons, #id)();
  TextColumn get sourceId => text()();
  IntColumn get episodeNumber => integer()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get streamUrl => text()();
  TextColumn get containerExtension => text().withDefault(const Constant('mp4'))();
  TextColumn get plot => text().nullable()();
  IntColumn get duration => integer().nullable()();
  TextColumn get coverUrl => text().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get releaseDate => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

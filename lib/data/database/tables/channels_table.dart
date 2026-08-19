import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';

/// Enum for channel source type (to differentiate refresh behavior).
enum ChannelSourceType {
  m3u,
  xtream,
}

/// SQLite table definition for channels.
class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(Playlists, #id)();
  TextColumn get sourceId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 500)();
  TextColumn get streamUrl => text()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get groupName => text().nullable()();
  TextColumn get tvgId => text().nullable()();
  TextColumn get tvgName => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get sourceType => textEnum<ChannelSourceType>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

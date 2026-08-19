import 'package:drift/drift.dart';

/// Enum for playlist source types.
enum PlaylistType {
  m3u,
  xtream,
  local,
}

/// Enum for playlist sync status.
enum PlaylistSyncStatus {
  idle,
  syncing,
  error,
}

/// SQLite table definition for playlists/sources.
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get type => textEnum<PlaylistType>()();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get epgUrl => text().nullable()();
  TextColumn get username => text().nullable()();
  TextColumn get credentialKey => text().nullable()();
  IntColumn get xtreamPortOverride => integer().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get syncStatus => textEnum<PlaylistSyncStatus>().withDefault(
        Constant(PlaylistSyncStatus.idle.name),
      )();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

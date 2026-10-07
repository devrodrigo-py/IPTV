// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_dao.dart';

// ignore_for_file: type=lint
mixin _$WatchHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $ChannelsTable get channels => attachedDatabase.channels;
  $WatchHistoryEntriesTable get watchHistoryEntries =>
      attachedDatabase.watchHistoryEntries;
  WatchHistoryDaoManager get managers => WatchHistoryDaoManager(this);
}

class WatchHistoryDaoManager {
  final _$WatchHistoryDaoMixin _db;
  WatchHistoryDaoManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db.attachedDatabase, _db.channels);
  $$WatchHistoryEntriesTableTableManager get watchHistoryEntries =>
      $$WatchHistoryEntriesTableTableManager(
          _db.attachedDatabase, _db.watchHistoryEntries);
}

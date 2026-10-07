// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists_dao.dart';

// ignore_for_file: type=lint
mixin _$PlaylistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  PlaylistsDaoManager get managers => PlaylistsDaoManager(this);
}

class PlaylistsDaoManager {
  final _$PlaylistsDaoMixin _db;
  PlaylistsDaoManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
}

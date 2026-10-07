// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_dao.dart';

// ignore_for_file: type=lint
mixin _$FavoritesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $ChannelsTable get channels => attachedDatabase.channels;
  $FavoritesTable get favorites => attachedDatabase.favorites;
  FavoritesDaoManager get managers => FavoritesDaoManager(this);
}

class FavoritesDaoManager {
  final _$FavoritesDaoMixin _db;
  FavoritesDaoManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db.attachedDatabase, _db.channels);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db.attachedDatabase, _db.favorites);
}

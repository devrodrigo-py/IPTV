// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channels_dao.dart';

// ignore_for_file: type=lint
mixin _$ChannelsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $ChannelsTable get channels => attachedDatabase.channels;
  ChannelsDaoManager get managers => ChannelsDaoManager(this);
}

class ChannelsDaoManager {
  final _$ChannelsDaoMixin _db;
  ChannelsDaoManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db.attachedDatabase, _db.channels);
}

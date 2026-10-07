// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epg_dao.dart';

// ignore_for_file: type=lint
mixin _$EpgDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $ChannelsTable get channels => attachedDatabase.channels;
  $EpgProgramsTable get epgPrograms => attachedDatabase.epgPrograms;
  EpgDaoManager get managers => EpgDaoManager(this);
}

class EpgDaoManager {
  final _$EpgDaoMixin _db;
  EpgDaoManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db.attachedDatabase, _db.channels);
  $$EpgProgramsTableTableManager get epgPrograms =>
      $$EpgProgramsTableTableManager(_db.attachedDatabase, _db.epgPrograms);
}

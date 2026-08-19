import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';

part 'playlists_dao.g.dart';

/// Data access object for playlists.
@DriftAccessor(tables: [Playlists])
class PlaylistsDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  /// Returns all playlists ordered by name.
  Future<List<Playlist>> getAllPlaylists() {
    return (select(playlists)..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Returns all active playlists.
  Future<List<Playlist>> getActivePlaylists() {
    return (select(playlists)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Returns a single playlist by ID.
  Future<Playlist?> getPlaylistById(int id) {
    return (select(playlists)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Inserts a new playlist and returns its ID.
  Future<int> insertPlaylist(PlaylistsCompanion entry) {
    return into(playlists).insert(entry);
  }

  /// Updates an existing playlist. Returns true if a row was affected.
  Future<bool> updatePlaylist(PlaylistsCompanion entry) {
    return update(playlists).replace(entry);
  }

  /// Updates only the sync status and lastSyncAt fields.
  Future<int> updateSyncStatus(
    int id, {
    required PlaylistSyncStatus status,
    DateTime? syncedAt,
  }) {
    return (update(playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(
        syncStatus: Value(status),
        lastSyncAt: Value(syncedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft-deletes a playlist by marking it inactive.
  Future<int> deactivatePlaylist(int id) {
    return (update(playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Hard-deletes a playlist. Use with caution.
  Future<int> deletePlaylist(int id) {
    return (delete(playlists)..where((p) => p.id.equals(id))).go();
  }

  /// Watches all active playlists (reactive stream).
  Stream<List<Playlist>> watchActivePlaylists() {
    return (select(playlists)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }
}

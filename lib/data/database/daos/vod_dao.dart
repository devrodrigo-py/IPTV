import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// Data access object for VOD (movies).
/// Does not use @DriftAccessor to avoid code generation issues.
class VodDao extends DatabaseAccessor<AppDatabase> {
  VodDao(super.db);

  /// Returns all active VOD items for a playlist.
  Future<List<VodItem>> getVodByPlaylist(int playlistId) {
    return (select(attachedDatabase.vodItems)
          ..where((v) => v.playlistId.equals(playlistId))
          ..where((v) => v.isActive.equals(true))
          ..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .get();
  }

  /// Returns all active VOD items across all playlists.
  Future<List<VodItem>> getAllActiveVod() {
    return (select(attachedDatabase.vodItems)
          ..where((v) => v.isActive.equals(true))
          ..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .get();
  }

  /// Returns VOD items by category name.
  Future<List<VodItem>> getVodByCategory(String categoryName) {
    return (select(attachedDatabase.vodItems)
          ..where((v) => v.categoryName.equals(categoryName))
          ..where((v) => v.isActive.equals(true))
          ..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .get();
  }

  /// Searches VOD items by name (partial match).
  Future<List<VodItem>> searchVod(String query) {
    return (select(attachedDatabase.vodItems)
          ..where(
            (v) => v.name.like('%$query%') & v.isActive.equals(true),
          )
          ..orderBy([(v) => OrderingTerm.asc(v.name)])
          ..limit(100))
        .get();
  }

  /// Returns a single VOD item by ID.
  Future<VodItem?> getVodById(int id) {
    return (select(attachedDatabase.vodItems)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns a VOD item by sourceId within a playlist.
  Future<VodItem?> getVodBySourceId(int playlistId, String sourceId) {
    return (select(attachedDatabase.vodItems)
          ..where(
            (v) =>
                v.playlistId.equals(playlistId) & v.sourceId.equals(sourceId),
          ))
        .getSingleOrNull();
  }

  /// Inserts a VOD item and returns its ID.
  Future<int> insertVod(VodItemsCompanion entry) {
    return into(attachedDatabase.vodItems).insert(entry);
  }

  /// Batch-inserts multiple VOD items.
  Future<void> insertVodBatch(List<VodItemsCompanion> entries) {
    return batch((b) => b.insertAll(attachedDatabase.vodItems, entries));
  }

  /// Deactivates all VOD items for a playlist (soft delete during refresh).
  Future<int> deactivateVodForPlaylist(int playlistId) {
    return (update(attachedDatabase.vodItems)
          ..where((v) => v.playlistId.equals(playlistId)))
        .write(
      VodItemsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Returns distinct category names for active VOD items.
  Future<List<String>> getDistinctCategories() async {
    final query = selectOnly(attachedDatabase.vodItems, distinct: true)
      ..addColumns([attachedDatabase.vodItems.categoryName])
      ..where(attachedDatabase.vodItems.isActive.equals(true))
      ..where(attachedDatabase.vodItems.categoryName.isNotNull())
      ..orderBy([OrderingTerm.asc(attachedDatabase.vodItems.categoryName)]);

    final rows = await query.get();
    return rows
        .map((row) => row.read(attachedDatabase.vodItems.categoryName))
        .whereType<String>()
        .toList();
  }

  /// Watches active VOD items (reactive stream).
  Stream<List<VodItem>> watchAllActiveVod() {
    return (select(attachedDatabase.vodItems)
          ..where((v) => v.isActive.equals(true))
          ..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .watch();
  }

  /// Deletes all VOD items for a playlist.
  Future<int> deleteVodForPlaylist(int playlistId) {
    return (delete(attachedDatabase.vodItems)
          ..where((v) => v.playlistId.equals(playlistId)))
        .go();
  }
}

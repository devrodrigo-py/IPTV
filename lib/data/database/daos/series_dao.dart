import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// Data access object for series, seasons, and episodes.
/// Does not use @DriftAccessor to avoid code generation issues.
class SeriesDao extends DatabaseAccessor<AppDatabase> {
  SeriesDao(super.db);

  // ─────────────────────────────────────────────────────────────────────────────
  // Series
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns all active series for a playlist.
  Future<List<SeriesItem>> getSeriesByPlaylist(int playlistId) {
    return (select(attachedDatabase.seriesItems)
          ..where((s) => s.playlistId.equals(playlistId))
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .get();
  }

  /// Returns every series of a playlist, including deactivated rows.
  ///
  /// Reconciliation must diff against the full set — a series that left the
  /// source in an earlier refresh and came back must be reactivated, not
  /// duplicated.
  Future<List<SeriesItem>> getAllSeriesByPlaylist(int playlistId) {
    return (select(attachedDatabase.seriesItems)
          ..where((s) => s.playlistId.equals(playlistId))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .get();
  }

  /// Returns all active series across all playlists.
  Future<List<SeriesItem>> getAllActiveSeries() {
    return (select(attachedDatabase.seriesItems)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .get();
  }

  /// Returns series by category name.
  Future<List<SeriesItem>> getSeriesByCategory(String categoryName) {
    return (select(attachedDatabase.seriesItems)
          ..where((s) => s.categoryName.equals(categoryName))
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .get();
  }

  /// Searches series by name (partial match).
  Future<List<SeriesItem>> searchSeries(String query) {
    return (select(attachedDatabase.seriesItems)
          ..where(
            (s) => s.name.like('%$query%') & s.isActive.equals(true),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.name)])
          ..limit(100))
        .get();
  }

  /// Returns a single series by ID.
  Future<SeriesItem?> getSeriesById(int id) {
    return (select(attachedDatabase.seriesItems)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns a series by sourceId within a playlist.
  Future<SeriesItem?> getSeriesBySourceId(int playlistId, String sourceId) {
    return (select(attachedDatabase.seriesItems)
          ..where(
            (s) =>
                s.playlistId.equals(playlistId) & s.sourceId.equals(sourceId),
          ))
        .getSingleOrNull();
  }

  /// Batch-inserts multiple series.
  Future<void> insertSeriesBatch(List<SeriesItemsCompanion> entries) {
    return batch((b) => b.insertAll(attachedDatabase.seriesItems, entries));
  }

  /// Deactivates all series for a playlist.
  Future<int> deactivateSeriesForPlaylist(int playlistId) {
    return (update(attachedDatabase.seriesItems)
          ..where((s) => s.playlistId.equals(playlistId)))
        .write(
      SeriesItemsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Returns distinct category names for active series.
  Future<List<String>> getDistinctCategories() async {
    final query = selectOnly(attachedDatabase.seriesItems, distinct: true)
      ..addColumns([attachedDatabase.seriesItems.categoryName])
      ..where(attachedDatabase.seriesItems.isActive.equals(true))
      ..where(attachedDatabase.seriesItems.categoryName.isNotNull())
      ..orderBy([OrderingTerm.asc(attachedDatabase.seriesItems.categoryName)]);

    final rows = await query.get();
    return rows
        .map((row) => row.read(attachedDatabase.seriesItems.categoryName))
        .whereType<String>()
        .toList();
  }

  /// Watches active series (reactive stream).
  Stream<List<SeriesItem>> watchAllActiveSeries() {
    return (select(attachedDatabase.seriesItems)
          ..where((s) => s.isActive.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .watch();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Seasons
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns all seasons for a series, ordered by season number.
  Future<List<Season>> getSeasonsBySeriesId(int seriesId) {
    return (select(attachedDatabase.seasons)
          ..where((s) => s.seriesId.equals(seriesId))
          ..orderBy([(s) => OrderingTerm.asc(s.seasonNumber)]))
        .get();
  }

  /// Inserts a season and returns its ID.
  Future<int> insertSeason(SeasonsCompanion entry) {
    return into(attachedDatabase.seasons).insert(entry);
  }

  /// Batch-inserts seasons.
  Future<void> insertSeasonsBatch(List<SeasonsCompanion> entries) {
    return batch((b) => b.insertAll(attachedDatabase.seasons, entries));
  }

  /// Deletes all seasons for a series.
  Future<int> deleteSeasonsForSeries(int seriesId) {
    return (delete(attachedDatabase.seasons)
          ..where((s) => s.seriesId.equals(seriesId)))
        .go();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Episodes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns all episodes for a season, ordered by episode number.
  Future<List<Episode>> getEpisodesBySeasonId(int seasonId) {
    return (select(attachedDatabase.episodes)
          ..where((e) => e.seasonId.equals(seasonId))
          ..orderBy([(e) => OrderingTerm.asc(e.episodeNumber)]))
        .get();
  }

  /// Returns all episodes for a series.
  Future<List<Episode>> getEpisodesBySeriesId(int seriesId) {
    return (select(attachedDatabase.episodes)
          ..where((e) => e.seriesId.equals(seriesId))
          ..orderBy([(e) => OrderingTerm.asc(e.episodeNumber)]))
        .get();
  }

  /// Returns a single episode by ID.
  Future<Episode?> getEpisodeById(int id) {
    return (select(attachedDatabase.episodes)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts an episode and returns its ID.
  Future<int> insertEpisode(EpisodesCompanion entry) {
    return into(attachedDatabase.episodes).insert(entry);
  }

  /// Batch-inserts episodes.
  Future<void> insertEpisodesBatch(List<EpisodesCompanion> entries) {
    return batch((b) => b.insertAll(attachedDatabase.episodes, entries));
  }

  /// Deletes all episodes for a series.
  Future<int> deleteEpisodesForSeries(int seriesId) {
    return (delete(attachedDatabase.episodes)
          ..where((e) => e.seriesId.equals(seriesId)))
        .go();
  }

  /// Deletes all episodes for a season.
  Future<int> deleteEpisodesForSeason(int seasonId) {
    return (delete(attachedDatabase.episodes)
          ..where((e) => e.seasonId.equals(seasonId)))
        .go();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cascade Deletes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Deletes a series and all its seasons and episodes.
  Future<void> deleteSeriesCascade(int seriesId) async {
    await deleteEpisodesForSeries(seriesId);
    await deleteSeasonsForSeries(seriesId);
    await (delete(attachedDatabase.seriesItems)
          ..where((s) => s.id.equals(seriesId)))
        .go();
  }

  /// Deletes all series, seasons, and episodes for a playlist.
  Future<void> deleteAllForPlaylist(int playlistId) async {
    final allSeries = await getSeriesByPlaylist(playlistId);
    for (final series in allSeries) {
      await deleteEpisodesForSeries(series.id);
      await deleteSeasonsForSeries(series.id);
    }
    await (delete(attachedDatabase.seriesItems)
          ..where((s) => s.playlistId.equals(playlistId)))
        .go();
  }
}

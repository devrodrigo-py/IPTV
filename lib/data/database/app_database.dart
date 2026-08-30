import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/daos/category_cache_dao.dart';
import 'package:nebula_iptv/data/database/daos/channel_group_dao.dart';
import 'package:nebula_iptv/data/database/daos/channels_dao.dart';
import 'package:nebula_iptv/data/database/daos/epg_dao.dart';
import 'package:nebula_iptv/data/database/daos/favorites_dao.dart';
import 'package:nebula_iptv/data/database/daos/health_check_dao.dart';
import 'package:nebula_iptv/data/database/daos/media_work_dao.dart';
import 'package:nebula_iptv/data/database/daos/playlists_dao.dart';
import 'package:nebula_iptv/data/database/daos/profile_dao.dart';
import 'package:nebula_iptv/data/database/daos/ratings_dao.dart';
import 'package:nebula_iptv/data/database/daos/search_aliases_dao.dart';
import 'package:nebula_iptv/data/database/daos/series_dao.dart';
import 'package:nebula_iptv/data/database/daos/shortcut_dao.dart';
import 'package:nebula_iptv/data/database/daos/tmdb_cache_dao.dart';
import 'package:nebula_iptv/data/database/daos/vod_dao.dart';
import 'package:nebula_iptv/data/database/daos/watch_history_dao.dart';
import 'package:nebula_iptv/data/database/daos/watch_stats_dao.dart';
import 'package:nebula_iptv/data/database/tables/channel_group_tables.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/epg_programs_table.dart';
import 'package:nebula_iptv/data/database/tables/episodes_table.dart';
import 'package:nebula_iptv/data/database/tables/favorites_table.dart';
import 'package:nebula_iptv/data/database/tables/health_check_tables.dart';
import 'package:nebula_iptv/data/database/tables/media_work_tables.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/database/tables/profile_tables.dart';
import 'package:nebula_iptv/data/database/tables/ratings_table.dart';
import 'package:nebula_iptv/data/database/tables/search_aliases_table.dart';
import 'package:nebula_iptv/data/database/tables/seasons_table.dart';
import 'package:nebula_iptv/data/database/tables/series_table.dart';
import 'package:nebula_iptv/data/database/tables/vod_table.dart';
import 'package:nebula_iptv/data/database/tables/watch_history_table.dart';
import 'package:nebula_iptv/data/database/tables/watch_stats_table.dart';

part 'app_database.g.dart';

/// Main application database.
///
/// Uses Drift with schemaVersion incremental migrations (spec 4.9).
@DriftDatabase(
  tables: [
    Playlists,
    Channels,
    Favorites,
    WatchHistoryEntries,
    EpgPrograms,
    VodItems,
    SeriesItems,
    Seasons,
    Episodes,
  ],
  daos: [
    PlaylistsDao,
    ChannelsDao,
    FavoritesDao,
    WatchHistoryDao,
    EpgDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  int get schemaVersion => 11;

  // Manual DAO gette
  CategoryCacheDao get categoryCacheDao => CategoryCacheDao(this);
  VodDao get vodDao => VodDao(this);
  SeriesDao get seriesDao => SeriesDao(this);
  TmdbCacheDao get tmdbCacheDao => TmdbCacheDao(this);
  MediaWorkDao get mediaWorkDao => MediaWorkDao(this);
  HealthCheckDao get healthCheckDao => HealthCheckDao(this);
  ChannelGroupDao get channelGroupDao => ChannelGroupDao(this);
  WatchStatsDao get watchStatsDao => WatchStatsDao(this);
  SearchAliasesDao get searchAliasesDao => SearchAliasesDao(this);
  ProfileDao get profileDao => ProfileDao(this);
  ShortcutDao get shortcutDao => ShortcutDao(this);
  RatingsDao get ratingsDao => RatingsDao(this);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create indexes for frequently queried fields (spec 31.1)
        await _createIndexes(m);
        // Create TMDB cache table (not managed by Drift)
        await _createTmdbCacheTable();
        // Create MediaWork content foundation tables (Etapa 1)
        await _createMediaWorkTables();
        // Create category cache table (Etapa 2)
        await _createCategoryCacheTable();
        // Create health check tables (Etapa 2)
        await _createHealthCheckTables();
        // Create channel group tables (Etapa 2)
        await _createChannelGroupTables();
        // Create watch stats tables (Etapa 3)
        await _createWatchStatsTables();
        await _createSearchAliasesTables();
        // Create profile & shortcuts tables (Etapa 6)
        await _createProfileTables();
        // Create ratings tables (Etapa 7)
        await _createRatingsTables();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Migration from v1 → v2: add VOD, Series, Seasons, Episodes tables
          await m.createTable(vodItems);
          await m.createTable(seriesItems);
          await m.createTable(seasons);
          await m.createTable(episodes);
          await _createVodSeriesIndexes();
        }
        if (from < 3) {
          // Migration from v2 → v3: add TMDB cache table
          await _createTmdbCacheTable();
        }
        if (from < 4) {
          // Migration from v3 → v4: MediaWork content foundation (Etapa 1)
          await _createMediaWorkTables();
        }
        if (from < 5) {
          // Migration from v4 → v5: Category cache table
          await _createCategoryCacheTable();
        }
        if (from < 6) {
          // Migration from v5 → v6: Health check tables (Etapa 2)
          await _createHealthCheckTables();
          await _createChannelGroupTables();
        }
        if (from < 7) {
          // Migration from v6 → v7: Watch history enhancements + stats (Etapa 3)
          await _createWatchStatsTables();
        }
        if (from < 8) {
          await _createSearchAliasesTables();
        }
        if (from < 9) {
          await _createProfileTables();
        }
        if (from < 10) {
          await _createRatingsTables();
        }
        if (from < 11) {
          // v10 → v11: per-source TLS opt-in column (ADR-005)
          await m.addColumn(playlists, playlists.allowInsecureTls);
        }
      },
    );
  }

  /// Creates all MediaWork-related tables, indexes, and ALTER TABLE statements.
  Future<void> _createMediaWorkTables() async {
    // Core tables
    await customStatement(MediaWorkSql.createMediaWork);
    await customStatement(MediaWorkSql.createContentAlias);
    await customStatement(MediaWorkSql.createMergeLog);
    await customStatement(MediaWorkSql.createPendingMatch);

    // Indexes
    for (final indexSql in MediaWorkSql.createIndexes) {
      await customStatement(indexSql);
    }

    // Link existing VOD/Series tables to MediaWork
    await customStatement(MediaWorkSql.addMediaWorkIdToVod);
    await customStatement(MediaWorkSql.addMediaWorkIdToSeries);
  }

  /// Creates the category_cache table for resolving category IDs to names.
  Future<void> _createCategoryCacheTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS category_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'live',
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(playlist_id, category_id, source_type)
      )
    ''');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_cache_lookup ON category_cache(playlist_id, source_type)',
    );
  }

  /// Creates the health check tables for channel availability monitoring.
  Future<void> _createHealthCheckTables() async {
    await customStatement(HealthCheckSql.createHealthChecks);
    for (final indexSql in HealthCheckSql.createIndexes) {
      await customStatement(indexSql);
    }
  }

  /// Creates ChannelGroup tables for Etapa 2.
  Future<void> _createChannelGroupTables() async {
    await customStatement(ChannelGroupSql.createChannelGroups);
    await customStatement(ChannelGroupSql.createChannelGroupMembers);
    for (final indexSql in ChannelGroupSql.createIndexes) {
      await customStatement(indexSql);
    }
  }

  /// Creates watch stats tables and enhances watch history (Etapa 3).
  Future<void> _createWatchStatsTables() async {
    // Add new columns to watch_history_entries
    for (final alterSql in WatchStatsSql.alterWatchHistoryColumns) {
      try {
        await customStatement(alterSql);
      } catch (_) {
        // Column may already exist — ignore
      }
    }
    // Create watch_stats_daily table
    await customStatement(WatchStatsSql.createWatchStatsDaily);
    // Create indexes
    for (final indexSql in WatchStatsSql.createIndexes) {
      await customStatement(indexSql);
    }
  }

  /// Creates the search_aliases table and indexes (v8).
  Future<void> _createSearchAliasesTables() async {
    await customStatement(SearchAliasesTable.createTable);
    await customStatement(SearchAliasesTable.createIndex);
    await customStatement(SearchAliasesTable.createChannelIndex);
  }

  /// Creates profile and shortcuts tables (Etapa 6).
  Future<void> _createProfileTables() async {
    await customStatement(ProfileSql.createProfiles);
    await customStatement(ProfileSql.createUserShortcuts);
    await customStatement(ProfileSql.insertDefaultProfile);

    // Add profile_id to existing tables
    for (final alterSql in ProfileSql.alterStatements) {
      try {
        await customStatement(alterSql);
      } catch (_) {
        // Column may already exist — ignore
      }
    }

    for (final indexSql in ProfileSql.createIndexes) {
      await customStatement(indexSql);
    }
  }

  Future<void> _createRatingsTables() async {
    await customStatement(RatingsSql.createUserRatings);
    for (final indexSql in RatingsSql.createIndexes) {
      await customStatement(indexSql);
    }
  }

  Future<void> _createTmdbCacheTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tmdb_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_id TEXT NOT NULL,
        media_type TEXT NOT NULL,
        tmdb_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        overview TEXT,
        poster_url TEXT,
        backdrop_url TEXT,
        vote_average REAL,
        genres TEXT,
        cast_names TEXT,
        director TEXT,
        release_date TEXT,
        runtime INTEGER,
        seasons_json TEXT,
        fetched_at TEXT NOT NULL,
        UNIQUE(source_id, media_type)
      )
    ''');
  }

  Future<void> _createIndexes(Migrator m) async {
    // Channels
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_playlist_id '
      'ON channels (playlist_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_source_id '
      'ON channels (source_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_tvg_id '
      'ON channels (tvg_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_name '
      'ON channels (name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_group_name '
      'ON channels (group_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_is_active '
      'ON channels (is_active)',
    );

    // Favorites
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_favorites_channel_id '
      'ON favorites (channel_id)',
    );

    // EPG Programs
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_programs_channel_id '
      'ON epg_programs (channel_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_programs_start_time '
      'ON epg_programs (start_time_utc)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_programs_channel_start '
      'ON epg_programs (channel_id, start_time_utc)',
    );

    // Watch History
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_watch_history_channel_id '
      'ON watch_history_entries (channel_id)',
    );

    // VOD & Series indexes
    await _createVodSeriesIndexes();
  }

  Future<void> _createVodSeriesIndexes() async {
    // VOD Items
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vod_items_playlist_id '
      'ON vod_items (playlist_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vod_items_source_id '
      'ON vod_items (source_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vod_items_name '
      'ON vod_items (name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vod_items_category '
      'ON vod_items (category_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vod_items_is_active '
      'ON vod_items (is_active)',
    );

    // Series Items
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_items_playlist_id '
      'ON series_items (playlist_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_items_source_id '
      'ON series_items (source_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_items_name '
      'ON series_items (name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_items_category '
      'ON series_items (category_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_items_is_active '
      'ON series_items (is_active)',
    );

    // Seasons
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_seasons_series_id '
      'ON seasons (series_id)',
    );

    // Episodes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_episodes_series_id '
      'ON episodes (series_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_episodes_season_id '
      'ON episodes (season_id)',
    );
  }
}

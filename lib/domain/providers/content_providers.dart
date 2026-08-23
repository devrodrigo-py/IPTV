import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/daos/media_work_dao.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
import 'package:nebula_iptv/data/datasources/tvmaze/tvmaze_datasource.dart';
import 'package:nebula_iptv/domain/services/content_matching_service.dart';
import 'package:nebula_iptv/domain/services/metadata_enrichment_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Provider for the MediaWorkDao.
final mediaWorkDaoProvider = Provider<MediaWorkDao>((ref) {
  final db = ref.read(databaseProvider);
  return db.mediaWorkDao;
});

/// Provider for the TMDB data source.
final tmdbDataSourceProvider = Provider<TmdbDataSource>((ref) {
  return TmdbDataSource();
});

/// Provider for the TVMaze data source.
final tvMazeDataSourceProvider = Provider<TvMazeDataSource>((ref) {
  return TvMazeDataSource();
});

/// Provider for the content matching service.
final contentMatchingServiceProvider = Provider<ContentMatchingService>((ref) {
  final dao = ref.read(mediaWorkDaoProvider);
  return ContentMatchingService(dao);
});

/// Provider for the unified metadata enrichment service.
final metadataEnrichmentServiceProvider =
    Provider<MetadataEnrichmentService>((ref) {
  return MetadataEnrichmentService(
    mediaWorkDao: ref.read(mediaWorkDaoProvider),
    tmdbDataSource: ref.read(tmdbDataSourceProvider),
    tvMazeDataSource: ref.read(tvMazeDataSourceProvider),
    matchingService: ref.read(contentMatchingServiceProvider),
  );
});

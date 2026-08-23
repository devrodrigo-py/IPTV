import 'dart:async';
import 'package:drift/drift.dart';

import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/daos/search_aliases_dao.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';

/// Background batch enrichment service.
///
/// Processes all series and VOD channels, searches TMDB for each,
/// and stores alternative titles as search aliases for cross-language search.
///
/// Example: "Confusões de Leslie" → aliases: ["Parks and Recreation", "Parks & Rec"]
class BatchEnrichmentService {
  final AppDatabase _db;
  final TmdbDataSource _tmdbDs;
  final SearchAliasesDao _aliasesDao;

  bool _isRunning = false;
  bool _shouldStop = false;
  int _processed = 0;
  int _matched = 0;
  int _total = 0;

  bool get isRunning => _isRunning;
  int get processed => _processed;
  int get matched => _matched;
  int get total => _total;
  double get progress => _total > 0 ? _processed / _total : 0.0;

  BatchEnrichmentService({
    required AppDatabase db,
    required TmdbDataSource tmdbDs,
    required SearchAliasesDao aliasesDao,
  })  : _db = db,
        _tmdbDs = tmdbDs,
        _aliasesDao = aliasesDao;

  /// Runs enrichment for all unenriched series and VOD.
  /// Processes series first (higher value), then VOD.
  /// Rate limited to ~3 requests/second.
  Future<void> runEnrichment({int batchSize = 50}) async {
    if (_isRunning) {
      appLogger.w('[BatchEnrich] Already running, skipping');
      return;
    }

    _isRunning = true;
    _shouldStop = false;
    _processed = 0;
    _matched = 0;

    try {
      // Get already enriched channel IDs
      final enriched = await _aliasesDao.getEnrichedChannelIds();
      appLogger.i('[BatchEnrich] Already enriched: ${enriched.length} channels');

      // Process series first
      await _processType('series', enriched, batchSize);

      // Then VOD
      if (!_shouldStop) {
        await _processType('vod', enriched, batchSize);
      }

      appLogger.i(
        '[BatchEnrich] Complete! Processed $_processed/$_total, matched $_matched',
      );
    } catch (e) {
      appLogger.e('[BatchEnrich] Error: $e');
    } finally {
      _isRunning = false;
    }
  }

  /// Stops the enrichment gracefully.
  void stop() {
    _shouldStop = true;
  }

  /// Processes all channels of a given source_type.
  Future<void> _processType(
    String sourceType,
    Set<int> alreadyEnriched,
    int batchSize,
  ) async {
    // Get total count for this type
    final countRows = await _db.customSelect(
      "SELECT COUNT(*) as cnt FROM channels WHERE source_type = ? AND is_active = 1",
      variables: [Variable.withString(sourceType)],
    ).get();
    final totalForType = countRows.first.read<int>('cnt');
    _total += totalForType;

    appLogger.i('[BatchEnrich] Processing $sourceType: $totalForType total');

    int offset = 0;
    while (!_shouldStop) {
      // Fetch batch
      final rows = await _db.customSelect(
        '''
        SELECT id, name, source_id FROM channels
        WHERE source_type = ? AND is_active = 1
        ORDER BY id ASC
        LIMIT ? OFFSET ?
        ''',
        variables: [
          Variable.withString(sourceType),
          Variable.withInt(batchSize),
          Variable.withInt(offset),
        ],
      ).get();

      if (rows.isEmpty) break;

      for (final row in rows) {
        if (_shouldStop) break;

        final channelId = row.read<int>('id');
        final name = row.read<String>('name');

        _processed++;

        // Skip if already enriched
        if (alreadyEnriched.contains(channelId)) continue;

        // Enrich this channel
        await _enrichChannel(channelId, name, sourceType);

        // Rate limit: ~350ms between TMDB requests (≈3/s)
        await Future.delayed(const Duration(milliseconds: 350));
      }

      offset += batchSize;

      // Log progress every batch
      if (!_shouldStop) {
        appLogger.d(
          '[BatchEnrich] Progress: $_processed/$_total ($sourceType), matched $_matched',
        );
      }
    }
  }

  /// Enriches a single channel: searches TMDB and stores aliases.
  Future<void> _enrichChannel(
    int channelId,
    String channelName,
    String sourceType,
  ) async {
    try {
      // Clean up the channel name for search
      final searchName = _cleanNameForSearch(channelName);
      if (searchName.length < 2) return;

      // Search TMDB in pt-BR to find the content
      final result = sourceType == 'series'
          ? await _tmdbDs.searchTv(searchName, language: 'pt-BR')
          : await _tmdbDs.searchMovie(searchName, language: 'pt-BR');

      if (!result.isSuccess) return;

      final data = (result as dynamic).data;
      if (data == null || (data as List).isEmpty) return;
      final results = data as List;

      // Take the first (best) match
      final best = results.first;
      final tmdbTitle = best.title as String;

      // Check if it's a reasonable match (at least one shared word)
      if (!_isReasonableMatch(channelName, tmdbTitle)) return;

      // Now search in English to get the original title
      final resultEn = sourceType == 'series'
          ? await _tmdbDs.searchTv(searchName, language: 'en-US')
          : await _tmdbDs.searchMovie(searchName, language: 'en-US');

      // Collect all title variants
      final aliases = <String>{};

      // Add the pt-BR title
      aliases.add(tmdbTitle);

      // Add the original/English title
      if (resultEn.isSuccess) {
        final enData = (resultEn as dynamic).data;
        if (enData != null && (enData as List).isNotEmpty) {
          final enTitle = enData.first.title as String;
          aliases.add(enTitle);
        }
      }

      // Add the channel's own name (so it can be found by its current name too)
      aliases.add(channelName);

      // Remove the channel name from aliases if it's the same as what we'd search
      // (it's already directly searchable in channels table)
      // Keep it anyway — it creates a unified search experience

      // Store all aliases
      await _aliasesDao.insertAliases(
        channelId: channelId,
        aliases: aliases.toList(),
        source: 'tmdb',
      );

      _matched++;
    } catch (e) {
      // Silently continue on individual failures
    }
  }

  /// Cleans a channel name for TMDB search.
  /// Removes quality tags, year, brackets, etc.
  String _cleanNameForSearch(String name) {
    return name
        .replaceAll(RegExp(r'\[.*?\]'), '') // Remove [brackets]
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove (parens)
        .replaceAll(RegExp(r'\b(FHD|HD|SD|4K|UHD|H\.?265|HEVC)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(20\d{2}|19\d{2})\b'), '') // Remove years
        .replaceAll(RegExp(r'[._]'), ' ') // Dots/underscores to spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Checks if a TMDB result is a reasonable match for the channel name.
  /// At least one significant word must be shared.
  bool _isReasonableMatch(String channelName, String tmdbTitle) {
    final channelWords = channelName
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 2)
        .toSet();
    final tmdbWords = tmdbTitle
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 2)
        .toSet();

    // At least one significant word must match
    return channelWords.intersection(tmdbWords).isNotEmpty;
  }
}

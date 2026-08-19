import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/datasources/epg/epg_datasource.dart';
import 'package:nebula_iptv/data/datasources/epg/xmltv_parser.dart';

/// Result of EPG synchronization.
class EpgSyncResult {
  final int programsImported;
  final int channelsMatched;
  final int parseErrors;

  const EpgSyncResult({
    required this.programsImported,
    required this.channelsMatched,
    required this.parseErrors,
  });
}

/// Repository for EPG data synchronization and queries.
///
/// Handles: fetch XMLTV -> parse -> match channels -> persist.
/// All times stored as UTC (spec §4.4).
class EpgRepository {
  final AppDatabase _db;
  final EpgDataSource _epgDataSource;

  EpgRepository({
    required AppDatabase db,
    required EpgDataSource epgDataSource,
  })  : _db = db,
        _epgDataSource = epgDataSource;

  /// Syncs EPG data for a playlist's EPG URL.
  Future<Result<EpgSyncResult>> syncEpg(String epgUrl) async {
    final fetchResult = await _epgDataSource.fetchEpg(epgUrl);

    return await fetchResult.when(
      success: (parseResult) => _persistEpg(parseResult),
      failure: (f) => Failure(f),
    );
  }

  /// Persists parsed EPG data, matching XMLTV channels to local channels.
  Future<Result<EpgSyncResult>> _persistEpg(
    XmltvParseResult parseResult,
  ) async {
    try {
      // Get all channels and build a lookup by tvgId
      final allChannels = await _db.channelsDao.getAllActiveChannels();
      final channelsByTvgId = <String, int>{};
      for (final ch in allChannels) {
        if (ch.tvgId != null && ch.tvgId!.isNotEmpty) {
          channelsByTvgId[ch.tvgId!] = ch.id;
        }
      }

      var programsImported = 0;
      final matchedChannelIds = <int>{};

      // Group programs by XMLTV channel ID
      final programsByXmltvChannel = <String, List<XmltvProgram>>{};
      for (final program in parseResult.programs) {
        programsByXmltvChannel
            .putIfAbsent(program.channelId, () => [])
            .add(program);
      }

      // Match and persist
      for (final entry in programsByXmltvChannel.entries) {
        final xmltvChannelId = entry.key;
        final programs = entry.value;

        // Try to find matching local channel
        final localChannelId = channelsByTvgId[xmltvChannelId];
        if (localChannelId == null) continue;

        matchedChannelIds.add(localChannelId);

        // Replace all EPG data for this channel
        final companions = programs
            .map(
              (p) => EpgProgramsCompanion.insert(
                channelId: localChannelId,
                title: p.title,
                description: Value(p.description),
                startTimeUtc: p.startUtc,
                endTimeUtc: p.endUtc,
                category: Value(p.category),
                imageUrl: Value(p.iconUrl),
              ),
            )
            .toList();

        await _db.epgDao.replacePrograms(localChannelId, companions);
        programsImported += companions.length;
      }

      // Clean up expired programs
      await _db.epgDao.deleteExpiredPrograms();

      appLogger.i(
        'EPG sync complete: $programsImported programs, '
        '${matchedChannelIds.length} channels matched',
      );

      return Success(
        EpgSyncResult(
          programsImported: programsImported,
          channelsMatched: matchedChannelIds.length,
          parseErrors: parseResult.errorCount,
        ),
      );
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao salvar dados do EPG.',
          originalError: e,
        ),
      );
    }
  }

  /// Gets the current program for a channel.
  Future<EpgProgram?> getCurrentProgram(int channelId) {
    return _db.epgDao.getCurrentProgram(channelId);
  }

  /// Gets upcoming programs for a channel.
  Future<List<EpgProgram>> getUpcomingPrograms(
    int channelId, {
    int limit = 10,
  }) {
    return _db.epgDao.getProgramsForChannel(channelId, limit: limit);
  }
}

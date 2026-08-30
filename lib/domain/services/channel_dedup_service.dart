import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/utils/isolate_parse.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/daos/channel_group_dao.dart';

/// Result of a channel deduplication scan.
class ChannelDeduplicationResult {
  final int groupsCreated;
  final int channelsGrouped;
  final int groupsSkipped; // Already existed (manual source)
  final Duration elapsed;

  const ChannelDeduplicationResult({
    this.groupsCreated = 0,
    this.channelsGrouped = 0,
    this.groupsSkipped = 0,
    this.elapsed = Duration.zero,
  });

  @override
  String toString() =>
      'DeduplicationResult(groups: $groupsCreated, channels: $channelsGrouped, '
      'skipped: $groupsSkipped, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// Lightweight channel identity used as dedup input.
class ChannelNameInfo {
  final int id;
  final String name;

  const ChannelNameInfo({required this.id, required this.name});
}

/// A candidate group produced by the pure normalization pass.
class ComputedChannelGroup {
  final String normalizedName;
  final String displayName;

  /// Members sorted best quality first.
  final List<ComputedChannelMember> members;

  const ComputedChannelGroup({
    required this.normalizedName,
    required this.displayName,
    required this.members,
  });
}

/// A member of a [ComputedChannelGroup].
class ComputedChannelMember {
  final int channelId;
  final String? qualityTag;

  const ComputedChannelMember({required this.channelId, this.qualityTag});
}

/// Service that detects channels which are quality variants of the same stream.
///
/// Algorithm:
/// 1. Normalize all channel names (remove quality tags like [HD], [FHD], etc.)
/// 2. Group channels by their normalized name
/// 3. For groups with 2+ members, create a ChannelGroup
/// 4. Extract quality tag from original name for each member
/// 5. Set primary = highest quality (4K > FHD > HD > SD)
///
/// Spec 3.6: Auto-grouped items NEVER override manual groupings.
class ChannelDeduplicationService {
  final AppDatabase _db;
  final ChannelGroupDao _groupDao;

  ChannelDeduplicationService({
    required AppDatabase db,
    required ChannelGroupDao groupDao,
  })  : _db = db,
        _groupDao = groupDao;

  /// Scans all channels for a playlist and groups quality variants.
  ///
  /// Only creates new groups — never modifies groups with `source: 'manual'`.
  Future<ChannelDeduplicationResult> detectDuplicateChannels({
    int? playlistId,
  }) async {
    final stopwatch = Stopwatch()..start();
    await _groupDao.ensureTables();

    // Load all active channels
    final channels = await _loadChannels(playlistId);
    if (channels.isEmpty) {
      return ChannelDeduplicationResult(elapsed: stopwatch.elapsed);
    }

    appLogger.d(
      '[ChannelDedup] Scanning ${channels.length} channels for duplicates...',
    );

    // Pure CPU pass — normalization, grouping, quality sorting — runs
    // outside the main thread.
    final groups = await parseInIsolate(channels, computeGroups);

    var groupsCreated = 0;
    var channelsGrouped = 0;
    var groupsSkipped = 0;

    // Persist groups with 2+ members
    for (final group in groups) {
      if (group.members.length < 2) continue;

      // Check if a group already exists for this normalized name
      final existingGroupId =
          await _groupDao.findGroupByNormalizedName(group.normalizedName);
      if (existingGroupId != null) {
        groupsSkipped++;
        continue;
      }

      // Create the group (primary = best quality, first member)
      final groupId = await _groupDao.createGroup(
        displayName: group.displayName,
        normalizedName: group.normalizedName,
        primaryChannelId: group.members.first.channelId,
        confidenceScore: 1.0,
        source: 'auto',
      );

      // Add all members
      for (var i = 0; i < group.members.length; i++) {
        final member = group.members[i];
        await _groupDao.addMember(
          groupId: groupId,
          channelId: member.channelId,
          qualityTag: member.qualityTag,
          priority: group.members.length - i, // Higher = better
        );
      }

      groupsCreated++;
      channelsGrouped += group.members.length;
    }

    stopwatch.stop();
    final result = ChannelDeduplicationResult(
      groupsCreated: groupsCreated,
      channelsGrouped: channelsGrouped,
      groupsSkipped: groupsSkipped,
      elapsed: stopwatch.elapsed,
    );

    appLogger.i('[ChannelDedup] $result');
    return result;
  }

  /// Pure normalization + grouping pass — "channel names in, candidate
  /// groups out". No I/O; safe to run inside an isolate.
  static List<ComputedChannelGroup> computeGroups(
    List<ChannelNameInfo> channels,
  ) {
    final grouped = <String, List<ChannelNameInfo>>{};
    for (final ch in channels) {
      final normalized = normalizeChannelName(ch.name);
      if (normalized.isEmpty) continue;
      grouped.putIfAbsent(normalized, () => []).add(ch);
    }

    final result = <ComputedChannelGroup>[];
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;

      final sorted = entry.value.toList()
        ..sort((a, b) {
          final tagA = extractQualityTag(a.name);
          final tagB = extractQualityTag(b.name);
          return qualityPriority(tagB).compareTo(qualityPriority(tagA));
        });

      result.add(
        ComputedChannelGroup(
          normalizedName: entry.key,
          displayName: _pickDisplayName(sorted),
          members: sorted
              .map(
                (ch) => ComputedChannelMember(
                  channelId: ch.id,
                  qualityTag: extractQualityTag(ch.name),
                ),
              )
              .toList(),
        ),
      );
    }
    return result;
  }

  /// Normalizes a channel name for grouping purposes.
  ///
  /// More aggressive than content normalization:
  /// - Removes quality tags: [FHD], [HD], [SD], [4K], [UHD], [ALTER], [BACKUP]
  /// - Removes trailing provider numbering
  /// - Preserves numbers that are part of the name (e.g. "HBO Max 3")
  /// - Does NOT remove year in parentheses
  static String normalizeChannelName(String name) {
    var s = name;

    // Remove bracketed quality/variant tags
    s = s.replaceAll(
      RegExp(
        r'\s*\[(FHD|HD|SD|4K|UHD|ALTER|ALTERNATIVO|BACKUP|H\.?264|H\.?265|HEVC)\]',
        caseSensitive: false,
      ),
      '',
    );

    // Remove parenthesized quality tags
    s = s.replaceAll(
      RegExp(
        r'\s*\((FHD|HD|SD|4K|UHD|ALTER)\)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove standalone quality suffixes at end of string
    s = s.replaceAll(
      RegExp(
        r'\s+(FHD|HD|SD|4K|UHD)$',
        caseSensitive: false,
      ),
      '',
    );

    // Lowercase
    s = s.toLowerCase();

    // Remove diacritics
    s = _removeDiacritics(s);

    // Normalize separators
    s = s.replaceAll(RegExp(r'[_\-\.]+'), ' ');

    // Collapse whitespace and trim
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  /// Extracts the quality tag from a channel name.
  ///
  /// Returns: '4K', 'FHD', 'HD', 'SD', 'ALTER', or null.
  static String? extractQualityTag(String name) {
    // Check bracketed tags first
    final bracketMatch = RegExp(
      r'\[(4K|UHD|FHD|HD|SD|ALTER|ALTERNATIVO|BACKUP)\]',
      caseSensitive: false,
    ).firstMatch(name);

    if (bracketMatch != null) {
      final tag = bracketMatch.group(1)!.toUpperCase();
      if (tag == 'UHD') return '4K';
      if (tag == 'ALTERNATIVO' || tag == 'BACKUP') return 'ALTER';
      return tag;
    }

    // Check parenthesized tags
    final parenMatch = RegExp(
      r'\((4K|UHD|FHD|HD|SD|ALTER)\)',
      caseSensitive: false,
    ).firstMatch(name);

    if (parenMatch != null) {
      final tag = parenMatch.group(1)!.toUpperCase();
      if (tag == 'UHD') return '4K';
      return tag;
    }

    // Check trailing suffix
    final suffixMatch = RegExp(
      r'\s+(4K|UHD|FHD|HD|SD)$',
      caseSensitive: false,
    ).firstMatch(name);

    if (suffixMatch != null) {
      final tag = suffixMatch.group(1)!.toUpperCase();
      if (tag == 'UHD') return '4K';
      return tag;
    }

    return null;
  }

  /// Determines priority for quality tags (higher = better quality).
  static int qualityPriority(String? tag) {
    return switch (tag) {
      '4K' => 100,
      'FHD' => 80,
      'HD' => 60,
      'SD' => 40,
      'ALTER' => 20,
      _ => 50, // Unknown/no tag = middle priority
    };
  }

  /// Picks the best display name for a group (from quality-sorted members).
  static String _pickDisplayName(List<ChannelNameInfo> sorted) {
    // Use the name of the highest-quality channel, stripped of tag
    var name = sorted.first.name;

    // Remove the quality tag from the display name
    name = name.replaceAll(
      RegExp(
        r'\s*[\[\(](FHD|HD|SD|4K|UHD|ALTER|ALTERNATIVO|BACKUP)[\]\)]',
        caseSensitive: false,
      ),
      '',
    );
    name = name.replaceAll(
      RegExp(r'\s+(FHD|HD|SD|4K|UHD)$', caseSensitive: false),
      '',
    );

    return name.trim();
  }

  /// Loads channels from the database.
  Future<List<ChannelNameInfo>> _loadChannels(int? playlistId) async {
    final String query;
    final List<Variable> variables;

    if (playlistId != null) {
      query =
          'SELECT id, name FROM channels WHERE playlist_id = ? AND is_active = 1';
      variables = [Variable.withInt(playlistId)];
    } else {
      query = 'SELECT id, name FROM channels WHERE is_active = 1';
      variables = [];
    }

    final results = await _db.customSelect(query, variables: variables).get();
    return results
        .map(
          (row) => ChannelNameInfo(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
          ),
        )
        .toList();
  }

  /// Removes diacritics/accents.
  static String _removeDiacritics(String text) {
    const map = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ñ': 'n',
      'ç': 'c',
      'ý': 'y',
      'ÿ': 'y',
    };

    final buffer = StringBuffer();
    for (final char in text.split('')) {
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }
}

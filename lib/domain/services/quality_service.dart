import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// Represents a quality variant for a channel.
class QualityVariant {
  final String name; // "FHD", "HD", "SD", "Auto"
  final String streamUrl;
  final int channelId;
  final int priority;

  const QualityVariant({
    required this.name,
    required this.streamUrl,
    required this.channelId,
    this.priority = 0,
  });
}

/// Service for detecting quality variants and auto-quality selection.
class QualityService {
  final AppDatabase _db;

  QualityService(this._db);

  /// Get available quality variants for a channel.
  /// Returns variants from channel_groups, or single variant if no group.
  Future<List<QualityVariant>> getQualityVariants(int channelId) async {
    // Find the channel's group
    final memberRows = await _db.customSelect(
      '''SELECT gm.group_id FROM channel_group_members gm
         WHERE gm.channel_id = ?''',
      variables: [Variable.withInt(channelId)],
    ).get();

    if (memberRows.isEmpty) {
      // No group — single quality only
      return [];
    }

    final groupId = memberRows.first.data['group_id'] as int;

    // Get all members of this group with their quality info
    final groupMembers = await _db.customSelect(
      '''SELECT gm.channel_id, gm.quality_tag, gm.priority, c.name, c.stream_url
         FROM channel_group_members gm
         JOIN channels c ON gm.channel_id = c.id
         WHERE gm.group_id = ? AND c.is_active = 1 AND c.stream_url != ''
         ORDER BY gm.priority DESC''',
      variables: [Variable.withInt(groupId)],
    ).get();

    if (groupMembers.length <= 1) return [];

    return groupMembers
        .map((row) {
          final qualityTag = row.data['quality_tag'] as String? ??
              _inferQuality(row.data['name'] as String? ?? '');
          return QualityVariant(
            name: qualityTag,
            streamUrl: row.data['stream_url'] as String? ?? '',
            channelId: row.data['channel_id'] as int,
            priority: row.data['priority'] as int? ?? 0,
          );
        })
        .where((v) => v.streamUrl.isNotEmpty)
        .toList();
  }

  /// Infer quality from channel name (e.g., "HBO [FHD]", "CNN HD").
  String _inferQuality(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('FHD') ||
        upper.contains('1080') ||
        upper.contains('FULL HD')) {
      return 'FHD';
    }
    if (upper.contains(' HD') ||
        upper.contains('[HD]') ||
        upper.contains('720')) {
      return 'HD';
    }
    if (upper.contains(' SD') ||
        upper.contains('[SD]') ||
        upper.contains('480')) {
      return 'SD';
    }
    return 'Auto';
  }

  /// Measure bandwidth by downloading a small chunk of the stream.
  /// Returns estimated Mbps.
  Future<double> measureBandwidth(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      // Convert to HLS if needed
      var testUrl = url;
      if (url.contains('/live/') && url.endsWith('.ts')) {
        testUrl = '${url.substring(0, url.length - 3)}.m3u8';
      }

      final request = await client.getUrl(Uri.parse(testUrl));
      request.headers.set('Range', 'bytes=0-524287'); // 512KB

      final stopwatch = Stopwatch()..start();
      final response = await request.close();

      int bytesRead = 0;
      await for (final chunk in response) {
        bytesRead += chunk.length;
        if (bytesRead >= 524288) break; // 512KB max
      }
      stopwatch.stop();

      client.close(force: true);

      if (bytesRead == 0 || stopwatch.elapsedMilliseconds == 0) return 0.0;

      // Calculate Mbps
      final mbps = (bytesRead * 8) / (stopwatch.elapsedMilliseconds * 1000);
      appLogger.d(
          '[Quality] Bandwidth test: ${bytesRead}B in ${stopwatch.elapsedMilliseconds}ms = ${mbps.toStringAsFixed(1)} Mbps');
      return mbps;
    } catch (e) {
      appLogger.w('[Quality] Bandwidth test failed: $e');
      return 0.0;
    }
  }

  /// Select the best quality based on bandwidth.
  /// Returns the recommended variant, or null for current quality.
  QualityVariant? selectQuality(List<QualityVariant> variants, double mbps) {
    if (variants.isEmpty) return null;

    // Sort by priority (highest = best quality)
    final sorted = List<QualityVariant>.from(variants)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    if (mbps >= 8.0) {
      // Use highest quality (FHD)
      return sorted.first;
    } else if (mbps >= 4.0) {
      // Use HD
      final hd = sorted.where((v) => v.name == 'HD').firstOrNull;
      return hd ?? sorted[sorted.length ~/ 2]; // middle quality
    } else {
      // Use lowest quality (SD)
      return sorted.last;
    }
  }
}

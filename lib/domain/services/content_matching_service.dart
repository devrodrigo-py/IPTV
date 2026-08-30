import 'package:nebula_iptv/core/utils/string_similarity.dart';
import 'package:nebula_iptv/data/database/daos/media_work_dao.dart';

/// Result of a content matching attempt.
class MatchResult {
  /// The type of match found.
  final MatchType type;

  /// The matched media work, if any.
  final MediaWorkEntry? mediaWork;

  /// Confidence score (0.0 – 1.0).
  final double confidence;

  /// The normalized form of the input name.
  final String normalizedInput;

  const MatchResult({
    required this.type,
    this.mediaWork,
    this.confidence = 0.0,
    required this.normalizedInput,
  });

  @override
  String toString() =>
      'MatchResult(type: $type, confidence: ${confidence.toStringAsFixed(3)}, '
      'mediaWork: ${mediaWork?.canonicalTitle}, normalized: "$normalizedInput")';
}

/// Classification of match result.
enum MatchType {
  /// Found exact alias match (confidence = 1.0).
  exact,

  /// Found fuzzy match above autoMerge threshold (>= 0.85).
  fuzzy,

  /// Score between 0.60–0.84, needs human review.
  pending,

  /// No match found (confidence < 0.60).
  noMatch,
}

/// Thresholds for content matching (seção 3.1 da spec de evolução).
abstract final class MatchThresholds {
  /// Scores >= this value trigger automatic merge.
  static const double autoMerge = 0.85;

  /// Scores >= this value (but < autoMerge) go to pending review queue.
  static const double pendingReview = 0.60;
}

/// Lightweight representation of a media work for matching purposes.
class MediaWorkEntry {
  final int id;
  final String canonicalTitle;
  final String normalizedTitle;
  final String type;
  final List<String> aliases;

  const MediaWorkEntry({
    required this.id,
    required this.canonicalTitle,
    required this.normalizedTitle,
    required this.type,
    this.aliases = const [],
  });
}

/// Content alias entry from the database.
class ContentAliasEntry {
  final int id;
  final int mediaWorkId;
  final String normalizedText;

  const ContentAliasEntry({
    required this.id,
    required this.mediaWorkId,
    required this.normalizedText,
  });
}

/// Service that normalizes IPTV content names and matches them against
/// the local MediaWork database using exact and fuzzy strategies.
///
/// Implements the content matching pipeline from spec section 3.1:
/// 1. Normalize input name (strip quality tags, language tags, accents, etc.)
/// 2. Attempt exact match against content_aliases.normalized_text
/// 3. If no exact match, run Jaro-Winkler fuzzy matching against all works
/// 4. Classify result by confidence threshold
class ContentMatchingService {
  final MediaWorkDao _dao;

  ContentMatchingService(this._dao);

  // ─────────────────────────────────────────────────────────────────────────
  // Normalization
  // ─────────────────────────────────────────────────────────────────────────

  /// Normalizes a content name for matching.
  ///
  /// Pipeline (order matters):
  /// 1. Remove bracketed/parenthesized language & quality tags
  /// 2. Remove standalone quality tags (HD, FHD, 4K, etc.)
  /// 3. Remove season/episode markers (S01E02, 1x01, T01E02)
  /// 4. Remove year in parentheses
  /// 5. Convert separators (underscores, pipes, dashes) to spaces
  /// 6. Remove "TV" suffix (but preserve it when part of a name)
  /// 7. Lowercase and remove diacritics
  /// 8. Remove remaining punctuation
  /// 9. Collapse whitespace and trim
  ///
  /// Deliberately does NOT strip trailing numbers: "The 100", "Room 104" and
  /// "SporTV 2" are real titles — stripping them collapsed everything into
  /// the leading word and made unrelated shows exact-alias-match each other.
  String normalize(String name) {
    var s = name;

    // 1. Remove bracketed/parenthesized language & quality tags.
    //    Matches: [DUB], [LEG], [DUAL], [Nacional], [Legendado], [Dublado],
    //             (Dublado), (Legendado), (Nacional), (DUAL), etc.
    s = s.replaceAll(
      RegExp(
        r'[\[\(](DUB|LEG|DUAL|Nacional|Legendado|Dublado|LEGENDADO|DUBLADO)[\]\)]',
        caseSensitive: false,
      ),
      '',
    );

    // 2. Remove quality/codec tags (with or without brackets).
    //    Matches: [4K], FHD, 1080p, H.265, HEVC, etc.
    s = s.replaceAll(
      RegExp(
        r'[\[\(]?(4K|UHD|FHD|HD|SD|720p|1080p|2160p|H\.?264|H\.?265|HEVC|x264|x265)[\]\)]?',
        caseSensitive: false,
      ),
      '',
    );

    // Also remove standalone language tags without brackets.
    s = s.replaceAll(
      RegExp(
        r'\b(LEGENDADO|DUBLADO|Nacional|DUAL|DUB|LEG)\b',
        caseSensitive: false,
      ),
      '',
    );

    // 3. Remove season/episode markers: S01E02, 1x01, T01E02.
    s = s.replaceAll(
      RegExp(r'[ST]\d{1,2}E\d{1,3}', caseSensitive: false),
      '',
    );
    s = s.replaceAll(
      RegExp(r'\d{1,2}x\d{1,3}', caseSensitive: false),
      '',
    );

    // 4. Remove year in parentheses (but keep the year value available
    //    for future use if needed).
    s = s.replaceAll(RegExp(r'\(\d{4}\)'), '');

    // 5. Convert common separators to spaces.
    //    Pipes, long dashes, underscores, dots between words.
    s = s.replaceAll(RegExp(r'[|]+'), ' ');
    s = s.replaceAll(RegExp(r'-{2,}'), ' ');
    s = s.replaceAll(RegExp(r'_{2,}'), ' ');
    s = s.replaceAll(RegExp(r'[_]'), ' ');
    s = s.replaceAll(RegExp(r'\.'), ' ');

    // 6. Remove "TV" if it appears as a trailing suffix
    //    (e.g., "Action TV" → "Action") but NOT if part of the name
    //    like "TV Globo" or "MTV".
    s = s.replaceAll(RegExp(r'\bTV\s*$', caseSensitive: false), '');

    // 7. Lowercase.
    s = s.toLowerCase();

    // 9. Remove diacritics.
    s = _removeDiacritics(s);

    // 10. Remove remaining punctuation (keep alphanumeric and spaces).
    s = s.replaceAll(RegExp(r'[^\w\s]'), '');

    // 11. Collapse multiple spaces and trim.
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Matching pipeline
  // ─────────────────────────────────────────────────────────────────────────

  /// Attempts to match a content name to an existing MediaWork.
  ///
  /// Pipeline:
  /// 1. Normalize input
  /// 2. Search exact match in content_aliases.normalized_text
  /// 3. If not found, search fuzzy against all MediaWorks and aliases
  /// 4. Return [MatchResult] with type and confidence
  Future<MatchResult> matchContent(String name, {String type = 'movie'}) async {
    final normalized = normalize(name);
    if (normalized.isEmpty) {
      return MatchResult(
        type: MatchType.noMatch,
        normalizedInput: normalized,
      );
    }

    // Step 2: Exact match against content aliases.
    final exactMatch = await _dao.findExactAlias(normalized, type: type);
    if (exactMatch != null) {
      return MatchResult(
        type: MatchType.exact,
        mediaWork: exactMatch,
        confidence: 1.0,
        normalizedInput: normalized,
      );
    }

    // Step 3: Fuzzy match against all media works of the given type.
    final allWorks = await _dao.getAllMediaWorks(type: type);
    if (allWorks.isEmpty) {
      return MatchResult(
        type: MatchType.noMatch,
        normalizedInput: normalized,
      );
    }

    double bestScore = 0.0;
    MediaWorkEntry? bestMatch;

    for (final work in allWorks) {
      // Compare against the canonical title (normalized).
      final titleScore = StringSimilarity.jaroWinkler(
        normalized,
        work.normalizedTitle,
      );

      if (titleScore > bestScore) {
        bestScore = titleScore;
        bestMatch = work;
      }

      // Also compare against each alias.
      for (final alias in work.aliases) {
        final aliasScore = StringSimilarity.jaroWinkler(normalized, alias);
        if (aliasScore > bestScore) {
          bestScore = aliasScore;
          bestMatch = work;
        }
      }

      // Early exit if we already have a perfect match.
      if (bestScore >= 0.99) break;
    }

    // Step 4: Classify by confidence threshold.
    return _classifyResult(
      score: bestScore,
      match: bestMatch,
      normalizedInput: normalized,
    );
  }

  /// Batch-matches a list of content names.
  ///
  /// Returns map of original name → [MatchResult].
  /// Efficient: loads all aliases/works first, then matches in-memory.
  Future<Map<String, MatchResult>> batchMatch(
    List<String> names, {
    String type = 'movie',
  }) async {
    if (names.isEmpty) return {};

    // Pre-load all data for in-memory matching.
    final allAliases = await _dao.getAllAliases(type: type);
    final allWorks = await _dao.getAllMediaWorks(type: type);

    // Build alias lookup: normalized_text → MediaWorkEntry.
    final aliasLookup = <String, MediaWorkEntry>{};
    for (final alias in allAliases) {
      final work = allWorks.where((w) => w.id == alias.mediaWorkId).firstOrNull;
      if (work != null) {
        aliasLookup[alias.normalizedText] = work;
      }
    }

    final results = <String, MatchResult>{};

    for (final name in names) {
      final normalized = normalize(name);
      if (normalized.isEmpty) {
        results[name] = MatchResult(
          type: MatchType.noMatch,
          normalizedInput: normalized,
        );
        continue;
      }

      // Exact match from pre-loaded aliases.
      final exactWork = aliasLookup[normalized];
      if (exactWork != null) {
        results[name] = MatchResult(
          type: MatchType.exact,
          mediaWork: exactWork,
          confidence: 1.0,
          normalizedInput: normalized,
        );
        continue;
      }

      // Fuzzy match against all works (in-memory).
      double bestScore = 0.0;
      MediaWorkEntry? bestMatch;

      for (final work in allWorks) {
        final titleScore = StringSimilarity.jaroWinkler(
          normalized,
          work.normalizedTitle,
        );

        if (titleScore > bestScore) {
          bestScore = titleScore;
          bestMatch = work;
        }

        for (final alias in work.aliases) {
          final aliasScore = StringSimilarity.jaroWinkler(normalized, alias);
          if (aliasScore > bestScore) {
            bestScore = aliasScore;
            bestMatch = work;
          }
        }

        if (bestScore >= 0.99) break;
      }

      results[name] = _classifyResult(
        score: bestScore,
        match: bestMatch,
        normalizedInput: normalized,
      );
    }

    return results;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Classifies a match result based on confidence score thresholds.
  MatchResult _classifyResult({
    required double score,
    required MediaWorkEntry? match,
    required String normalizedInput,
  }) {
    if (score >= MatchThresholds.autoMerge) {
      return MatchResult(
        type: MatchType.fuzzy,
        mediaWork: match,
        confidence: score,
        normalizedInput: normalizedInput,
      );
    } else if (score >= MatchThresholds.pendingReview) {
      return MatchResult(
        type: MatchType.pending,
        mediaWork: match,
        confidence: score,
        normalizedInput: normalizedInput,
      );
    } else {
      return MatchResult(
        type: MatchType.noMatch,
        mediaWork: match,
        confidence: score,
        normalizedInput: normalizedInput,
      );
    }
  }

  /// Removes diacritics/accents from a string using character substitution.
  ///
  /// Handles common Latin diacritics found in Portuguese, Spanish, French,
  /// and other Romance languages frequently seen in IPTV content.
  String _removeDiacritics(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(_diacriticMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Map of accented characters to their ASCII equivalents.
  static const _diacriticMap = <String, String>{
    // Lowercase
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'æ': 'ae',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ñ': 'n',
    'ç': 'c',
    'ý': 'y', 'ÿ': 'y',
    'ð': 'd',
    'ß': 'ss',
    // Uppercase
    'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a', 'Å': 'a',
    'Æ': 'ae',
    'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
    'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
    'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ö': 'o', 'Ø': 'o',
    'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
    'Ñ': 'n',
    'Ç': 'c',
    'Ý': 'y',
    'Ð': 'd',
  };
}

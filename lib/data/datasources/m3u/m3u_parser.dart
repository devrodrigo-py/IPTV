import 'package:nebula_iptv/data/datasources/m3u/m3u_entry.dart';

/// Result of parsing an M3U playlist.
class M3uParseResult {
  /// Successfully parsed entries.
  final List<M3uEntry> entries;

  /// Lines that could not be parsed (with line numbers).
  final List<M3uParseError> errors;

  /// Total number of lines processed.
  final int totalLines;

  const M3uParseResult({
    required this.entries,
    required this.errors,
    required this.totalLines,
  });

  /// Number of valid entries.
  int get validCount => entries.length;

  /// Number of invalid entries.
  int get errorCount => errors.length;
}

/// Describes a parse error for a specific line.
class M3uParseError {
  final int lineNumber;
  final String reason;
  final String? rawContent;

  const M3uParseError({
    required this.lineNumber,
    required this.reason,
    this.rawContent,
  });

  @override
  String toString() => 'Line $lineNumber: $reason';
}

/// Parser for M3U/M3U8 playlist files.
///
/// Supports common EXTINF formats with varying attribute orders,
/// missing fields, extra whitespace, and unknown attributes.
///
/// Tolerant by design: invalid entries are reported but do not
/// invalidate the entire playlist.
class M3uParser {
  const M3uParser();

  /// Parses raw M3U content into structured entries.
  M3uParseResult parse(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final entries = <M3uEntry>[];
    final errors = <M3uParseError>[];

    String? pendingExtinf;
    int? pendingLineNumber;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip empty lines and comments (non-EXTINF)
      if (line.isEmpty) continue;
      if (line.startsWith('#EXTM3U')) continue;

      if (line.startsWith('#EXTINF:')) {
        pendingExtinf = line;
        pendingLineNumber = i + 1;
        continue;
      }

      // Skip other directives
      if (line.startsWith('#')) continue;

      // This should be a URL line
      if (pendingExtinf != null) {
        final entry = _parseEntry(pendingExtinf, line);
        if (entry != null) {
          entries.add(entry);
        } else {
          errors.add(
            M3uParseError(
              lineNumber: pendingLineNumber!,
              reason: 'Não foi possível interpretar a entrada.',
              rawContent: pendingExtinf,
            ),
          );
        }
        pendingExtinf = null;
        pendingLineNumber = null;
      } else {
        // URL without EXTINF — try to use it anyway
        if (_looksLikeUrl(line)) {
          entries.add(
            M3uEntry(
              name: _nameFromUrl(line),
              streamUrl: line,
            ),
          );
        }
      }
    }

    // If there's a dangling EXTINF without URL
    if (pendingExtinf != null && pendingLineNumber != null) {
      errors.add(
        M3uParseError(
          lineNumber: pendingLineNumber,
          reason: 'EXTINF sem URL correspondente.',
          rawContent: pendingExtinf,
        ),
      );
    }

    return M3uParseResult(
      entries: entries,
      errors: errors,
      totalLines: lines.length,
    );
  }

  /// Parses a single EXTINF line + URL into an M3uEntry.
  M3uEntry? _parseEntry(String extinfLine, String url) {
    if (!_looksLikeUrl(url)) return null;

    final afterPrefix = extinfLine.substring('#EXTINF:'.length);
    final name = _extractName(afterPrefix);
    final attributes = _extractAttributes(afterPrefix);

    if (name.isEmpty && attributes.isEmpty) return null;

    return M3uEntry(
      name: name.isNotEmpty ? name : _nameFromUrl(url),
      streamUrl: url,
      tvgId: attributes['tvg-id'],
      tvgName: attributes['tvg-name'],
      logoUrl: attributes['tvg-logo'],
      groupTitle: attributes['group-title'],
      extraAttributes: Map.fromEntries(
        attributes.entries.where((e) => !_knownAttributes.contains(e.key)),
      ),
    );
  }

  /// Extracts the channel name (text after the last unquoted comma).
  String _extractName(String afterPrefix) {
    var inQuotes = false;
    var lastCommaIndex = -1;

    for (var i = 0; i < afterPrefix.length; i++) {
      final char = afterPrefix[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        lastCommaIndex = i;
      }
    }

    if (lastCommaIndex == -1) return '';
    return afterPrefix.substring(lastCommaIndex + 1).trim();
  }

  /// Extracts key="value" attributes from the EXTINF line.
  Map<String, String> _extractAttributes(String afterPrefix) {
    final attributes = <String, String>{};
    final regex = RegExp(r'([\w-]+)="([^"]*)"');
    for (final match in regex.allMatches(afterPrefix)) {
      final key = match.group(1)!.toLowerCase();
      final value = match.group(2)!;
      attributes[key] = value;
    }
    return attributes;
  }

  /// Checks if a string looks like a valid stream URL.
  bool _looksLikeUrl(String text) {
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('rtsp://');
  }

  /// Derives a fallback name from a URL.
  String _nameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        return segments.last.replaceAll(RegExp(r'\.\w+$'), '');
      }
    } catch (_) {}
    return 'Canal desconhecido';
  }

  static const _knownAttributes = {
    'tvg-id',
    'tvg-name',
    'tvg-logo',
    'group-title',
  };
}

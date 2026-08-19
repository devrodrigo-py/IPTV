import 'package:nebula_iptv/core/logging/app_logger.dart';

/// Result of parsing an XMLTV document.
class XmltvParseResult {
  /// Map of channel ID -> display name from XMLTV.
  final Map<String, String> channels;

  /// Parsed programs.
  final List<XmltvProgram> programs;

  /// Number of programs that failed to parse.
  final int errorCount;

  const XmltvParseResult({
    required this.channels,
    required this.programs,
    required this.errorCount,
  });
}

/// A single program from XMLTV before persistence.
class XmltvProgram {
  final String channelId;
  final String title;
  final String? description;
  final DateTime startUtc;
  final DateTime endUtc;
  final String? category;
  final String? iconUrl;

  const XmltvProgram({
    required this.channelId,
    required this.title,
    this.description,
    required this.startUtc,
    required this.endUtc,
    this.category,
    this.iconUrl,
  });
}

/// Parser for XMLTV EPG data (spec §18, §4.4).
///
/// All times are normalized to UTC at parse time.
/// The presentation layer converts to local timezone.
class XmltvParser {
  const XmltvParser();

  /// Parses raw XMLTV content.
  XmltvParseResult parse(String content) {
    final channels = <String, String>{};
    final programs = <XmltvProgram>[];
    var errorCount = 0;

    try {
      // Simple XML parsing without heavy dependencies.
      // Extract <channel> elements
      final channelRegex = RegExp(
        r'<channel\s+id="([^"]+)"[^>]*>.*?<display-name[^>]*>([^<]+)</display-name>.*?</channel>',
        dotAll: true,
      );
      for (final match in channelRegex.allMatches(content)) {
        final id = match.group(1)!;
        final name = _decodeXmlEntities(match.group(2)!.trim());
        channels[id] = name;
      }

      // Extract <programme> elements
      final programRegex = RegExp(
        r'<programme\s+start="([^"]+)"\s+stop="([^"]+)"\s+channel="([^"]+)"[^>]*>(.*?)</programme>',
        dotAll: true,
      );

      for (final match in programRegex.allMatches(content)) {
        try {
          final startStr = match.group(1)!;
          final stopStr = match.group(2)!;
          final channelId = match.group(3)!;
          final body = match.group(4)!;

          final startUtc = _parseXmltvTime(startStr);
          final endUtc = _parseXmltvTime(stopStr);

          if (startUtc == null || endUtc == null) {
            errorCount++;
            continue;
          }

          final title = _extractTag(body, 'title');
          if (title == null || title.isEmpty) {
            errorCount++;
            continue;
          }

          programs.add(
            XmltvProgram(
              channelId: channelId,
              title: title,
              description: _extractTag(body, 'desc'),
              startUtc: startUtc,
              endUtc: endUtc,
              category: _extractTag(body, 'category'),
              iconUrl: _extractAttribute(body, 'icon', 'src'),
            ),
          );
        } catch (e) {
          errorCount++;
        }
      }
    } catch (e) {
      appLogger.e('XMLTV parse failed: $e');
    }

    return XmltvParseResult(
      channels: channels,
      programs: programs,
      errorCount: errorCount,
    );
  }

  /// Parses XMLTV datetime format to UTC (spec §4.4).
  ///
  /// Format: "20210101120000 +0300" or "20210101120000"
  /// Always normalizes to UTC.
  DateTime? _parseXmltvTime(String timeStr) {
    try {
      final cleaned = timeStr.trim();

      // Extract the date/time part (first 14 chars: YYYYMMDDHHmmss)
      if (cleaned.length < 14) return null;

      final year = int.parse(cleaned.substring(0, 4));
      final month = int.parse(cleaned.substring(4, 6));
      final day = int.parse(cleaned.substring(6, 8));
      final hour = int.parse(cleaned.substring(8, 10));
      final minute = int.parse(cleaned.substring(10, 12));
      final second = int.parse(cleaned.substring(12, 14));

      var dt = DateTime.utc(year, month, day, hour, minute, second);

      // Handle timezone offset (e.g., "+0300", "-0500")
      final tzMatch = RegExp(r'([+-])(\d{2})(\d{2})').firstMatch(cleaned);
      if (tzMatch != null) {
        final sign = tzMatch.group(1) == '+' ? 1 : -1;
        final tzHours = int.parse(tzMatch.group(2)!);
        final tzMinutes = int.parse(tzMatch.group(3)!);
        final offset = Duration(hours: tzHours, minutes: tzMinutes) * sign;
        // Convert to UTC by subtracting the offset
        dt = dt.subtract(offset);
      }

      return dt.toUtc();
    } catch (e) {
      return null;
    }
  }

  /// Extracts text content from an XML tag.
  String? _extractTag(String body, String tagName) {
    final regex = RegExp('<$tagName[^>]*>([^<]*)</$tagName>');
    final match = regex.firstMatch(body);
    if (match == null) return null;
    final value = _decodeXmlEntities(match.group(1)!.trim());
    return value.isEmpty ? null : value;
  }

  /// Extracts an attribute value from a self-closing tag.
  String? _extractAttribute(String body, String tagName, String attrName) {
    final regex = RegExp('<$tagName[^>]*$attrName="([^"]*)"[^>]*/?>');
    final match = regex.firstMatch(body);
    return match?.group(1);
  }

  /// Decodes common XML entities.
  String _decodeXmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}

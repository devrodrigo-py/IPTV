import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_parser.dart';

void main() {
  late M3uParser parser;

  setUp(() {
    parser = const M3uParser();
  });

  group('M3uParser', () {
    test('should parse standard playlist with header', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="espn.us" tvg-name="ESPN" tvg-logo="http://logo.com/espn.png" group-title="Sports",ESPN HD
http://stream.example.com/espn
#EXTINF:-1 tvg-id="hbo.us" tvg-name="HBO" tvg-logo="http://logo.com/hbo.png" group-title="Movies",HBO
http://stream.example.com/hbo''';

      final result = parser.parse(content);

      expect(result.entries, hasLength(2));
      expect(result.errors, isEmpty);

      final espn = result.entries[0];
      expect(espn.name, 'ESPN HD');
      expect(espn.tvgId, 'espn.us');
      expect(espn.tvgName, 'ESPN');
      expect(espn.logoUrl, 'http://logo.com/espn.png');
      expect(espn.groupTitle, 'Sports');
      expect(espn.streamUrl, 'http://stream.example.com/espn');
    });

    test('should parse playlist without header', () {
      const content = '''#EXTINF:-1,Channel 1
http://stream.example.com/ch1
#EXTINF:-1,Channel 2
http://stream.example.com/ch2''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].name, 'Channel 1');
    });

    test('should handle empty playlist', () {
      const content = '#EXTM3U\n';
      final result = parser.parse(content);
      expect(result.entries, isEmpty);
      expect(result.errors, isEmpty);
    });

    test('should handle completely invalid content', () {
      const content = 'this is not a playlist at all';
      final result = parser.parse(content);
      expect(result.entries, isEmpty);
    });

    test('should parse single entry', () {
      const content = '''#EXTM3U
#EXTINF:-1,Solo Channel
http://stream.example.com/solo''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));
      expect(result.entries[0].name, 'Solo Channel');
    });

    test('should handle missing fields gracefully', () {
      const content = '''#EXTM3U
#EXTINF:-1,Channel Without Metadata
http://stream.example.com/plain''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));

      final entry = result.entries[0];
      expect(entry.name, 'Channel Without Metadata');
      expect(entry.tvgId, isNull);
      expect(entry.tvgName, isNull);
      expect(entry.logoUrl, isNull);
      expect(entry.groupTitle, isNull);
    });

    test('should handle attributes in different order', () {
      const content = '''#EXTM3U
#EXTINF:-1 group-title="News" tvg-logo="http://l.com/a.png" tvg-id="cnn" tvg-name="CNN",CNN International
http://stream.example.com/cnn''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));

      final entry = result.entries[0];
      expect(entry.tvgId, 'cnn');
      expect(entry.groupTitle, 'News');
      expect(entry.logoUrl, 'http://l.com/a.png');
    });

    test('should handle special characters in names', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="test",Canal São Paulo (HD) - Esportes & Lazer
http://stream.example.com/sp''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));
      expect(
        result.entries[0].name,
        'Canal São Paulo (HD) - Esportes & Lazer',
      );
    });

    test('should handle names containing commas', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="test",News, Sports & More
http://stream.example.com/nsm''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));
      // The name should be everything after the last unquoted comma
      // In this case "Sports & More" because the parser finds the last comma
      expect(result.entries[0].name, 'Sports & More');
    });

    test('should handle invalid URLs and report errors', () {
      const content = '''#EXTM3U
#EXTINF:-1,Valid Channel
http://stream.example.com/valid
#EXTINF:-1,Invalid Channel
not-a-url-at-all''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));
      expect(result.errors, hasLength(1));
      expect(result.entries[0].name, 'Valid Channel');
    });

    test('should handle missing groups', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="ch1",Channel No Group
http://stream.example.com/ng''';

      final result = parser.parse(content);
      expect(result.entries[0].groupTitle, isNull);
    });

    test('should handle missing logos', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="ch1" group-title="Test",No Logo Channel
http://stream.example.com/nl''';

      final result = parser.parse(content);
      expect(result.entries[0].logoUrl, isNull);
    });

    test('should handle missing tvg-id', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-name="Name Only" group-title="Group",Name Only
http://stream.example.com/no''';

      final result = parser.parse(content);
      expect(result.entries[0].tvgId, isNull);
      expect(result.entries[0].sourceId, isNull);
    });

    test('should detect duplicate streams', () {
      const content = '''#EXTM3U
#EXTINF:-1,Channel A
http://stream.example.com/same
#EXTINF:-1,Channel B
http://stream.example.com/same''';

      final result = parser.parse(content);
      // Parser does not deduplicate — that's the repository's job
      expect(result.entries, hasLength(2));
    });

    test('should handle extra whitespace and empty lines', () {
      const content = '''#EXTM3U

   #EXTINF:-1 tvg-id="ch1",  Spaced Channel  

   http://stream.example.com/spaced   

#EXTINF:-1,Normal
http://stream.example.com/normal
''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].name, 'Spaced Channel');
    });

    test('should handle incomplete entries (EXTINF without URL)', () {
      const content = '''#EXTM3U
#EXTINF:-1,Has URL
http://stream.example.com/ok
#EXTINF:-1,Dangling Entry''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));
      expect(result.errors, hasLength(1));
      expect(result.errors[0].reason, contains('sem URL'));
    });

    test('should handle unknown attributes', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="ch1" custom-attr="value" another="test",Custom Channel
http://stream.example.com/custom''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));
      expect(
        result.entries[0].extraAttributes,
        containsPair('custom-attr', 'value'),
      );
      expect(
        result.entries[0].extraAttributes,
        containsPair('another', 'test'),
      );
    });

    test('should handle HTTPS and RTSP URLs', () {
      const content = '''#EXTM3U
#EXTINF:-1,HTTPS Channel
https://secure.example.com/stream
#EXTINF:-1,RTSP Channel
rtsp://rtsp.example.com/live''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(2));
      expect(result.entries[0].hasValidUrl, isTrue);
      expect(result.entries[1].hasValidUrl, isTrue);
    });

    test('should handle large playlist efficiently', () {
      final buffer = StringBuffer('#EXTM3U\n');
      for (var i = 0; i < 5000; i++) {
        buffer.writeln(
          '#EXTINF:-1 tvg-id="ch$i" group-title="Group${i % 10}",Channel $i',
        );
        buffer.writeln('http://stream.example.com/$i');
      }

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(buffer.toString());
      stopwatch.stop();

      expect(result.entries, hasLength(5000));
      expect(result.errors, isEmpty);
      // Should complete in reasonable time (< 2s)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test('should handle URL-only lines without EXTINF', () {
      const content = '''#EXTM3U
http://stream.example.com/bare''';

      final result = parser.parse(content);
      expect(result.entries, hasLength(1));
      // Name should be derived from URL
      expect(result.entries[0].name, isNotEmpty);
    });

    test('sourceId should prioritize tvg-id', () {
      const content = '''#EXTM3U
#EXTINF:-1 tvg-id="unique.id",Test
http://stream.example.com/test''';

      final result = parser.parse(content);
      expect(result.entries[0].sourceId, 'unique.id');
    });

    test('should provide parse statistics', () {
      const content = '''#EXTM3U
#EXTINF:-1,Good 1
http://stream.example.com/1
#EXTINF:-1,Good 2
http://stream.example.com/2
#EXTINF:-1,Bad
invalid-url''';

      final result = parser.parse(content);
      expect(result.validCount, 2);
      expect(result.errorCount, 1);
      expect(result.totalLines, greaterThan(0));
    });
  });
}

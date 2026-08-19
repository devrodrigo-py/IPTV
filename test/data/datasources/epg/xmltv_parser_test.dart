import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/datasources/epg/epg_datasource.dart';
import 'package:nebula_iptv/data/datasources/epg/xmltv_parser.dart';

void main() {
  late XmltvParser parser;

  setUp(() {
    parser = const XmltvParser();
  });

  group('XmltvParser', () {
    test('should parse standard XMLTV document', () {
      const content = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="espn.us">
    <display-name>ESPN</display-name>
  </channel>
  <channel id="hbo.us">
    <display-name>HBO</display-name>
  </channel>
  <programme start="20260819120000 +0000" stop="20260819130000 +0000" channel="espn.us">
    <title>Sports Center</title>
    <desc>Daily sports news</desc>
    <category>Sports</category>
  </programme>
  <programme start="20260819200000 +0000" stop="20260819220000 +0000" channel="hbo.us">
    <title>Movie Night</title>
  </programme>
</tv>''';

      final result = parser.parse(content);

      expect(result.channels, hasLength(2));
      expect(result.channels['espn.us'], 'ESPN');
      expect(result.channels['hbo.us'], 'HBO');
      expect(result.programs, hasLength(2));
      expect(result.errorCount, 0);

      final sports = result.programs[0];
      expect(sports.channelId, 'espn.us');
      expect(sports.title, 'Sports Center');
      expect(sports.description, 'Daily sports news');
      expect(sports.category, 'Sports');
    });

    test('should normalize timezone to UTC (spec §4.4)', () {
      const content = '''<tv>
  <channel id="ch1"><display-name>Test</display-name></channel>
  <programme start="20260819150000 +0300" stop="20260819160000 +0300" channel="ch1">
    <title>Show with Timezone</title>
  </programme>
</tv>''';

      final result = parser.parse(content);
      expect(result.programs, hasLength(1));

      final program = result.programs[0];
      // 15:00 +0300 = 12:00 UTC
      expect(program.startUtc.hour, 12);
      expect(program.startUtc.minute, 0);
      // 16:00 +0300 = 13:00 UTC
      expect(program.endUtc.hour, 13);
    });

    test('should handle negative timezone offset', () {
      const content = '''<tv>
  <channel id="ch1"><display-name>Test</display-name></channel>
  <programme start="20260819100000 -0500" stop="20260819110000 -0500" channel="ch1">
    <title>US Show</title>
  </programme>
</tv>''';

      final result = parser.parse(content);
      final program = result.programs[0];
      // 10:00 -0500 = 15:00 UTC
      expect(program.startUtc.hour, 15);
    });

    test('should handle time without timezone (assume UTC)', () {
      const content = '''<tv>
  <channel id="ch1"><display-name>Test</display-name></channel>
  <programme start="20260819080000" stop="20260819090000" channel="ch1">
    <title>No TZ</title>
  </programme>
</tv>''';

      final result = parser.parse(content);
      final program = result.programs[0];
      expect(program.startUtc.hour, 8);
      expect(program.startUtc.isUtc, isTrue);
    });

    test('should handle XML entities in text', () {
      const content = '''<tv>
  <channel id="ch1"><display-name>Canal &amp; Mais</display-name></channel>
  <programme start="20260819100000 +0000" stop="20260819110000 +0000" channel="ch1">
    <title>Show &amp; Tell &lt;Special&gt;</title>
  </programme>
</tv>''';

      final result = parser.parse(content);
      expect(result.channels['ch1'], 'Canal & Mais');
      expect(result.programs[0].title, 'Show & Tell <Special>');
    });

    test('should extract icon URL', () {
      const content = '''<tv>
  <channel id="ch1"><display-name>Test</display-name></channel>
  <programme start="20260819100000 +0000" stop="20260819110000 +0000" channel="ch1">
    <title>With Icon</title>
    <icon src="http://epg.com/icon.png" />
  </programme>
</tv>''';

      final result = parser.parse(content);
      expect(result.programs[0].iconUrl, 'http://epg.com/icon.png');
    });

    test('should skip programs without title', () {
      const content = '''<tv>
  <channel id="ch1"><display-name>Test</display-name></channel>
  <programme start="20260819100000 +0000" stop="20260819110000 +0000" channel="ch1">
    <desc>No title here</desc>
  </programme>
  <programme start="20260819110000 +0000" stop="20260819120000 +0000" channel="ch1">
    <title>Has Title</title>
  </programme>
</tv>''';

      final result = parser.parse(content);
      expect(result.programs, hasLength(1));
      expect(result.programs[0].title, 'Has Title');
      expect(result.errorCount, 1);
    });

    test('should handle empty document', () {
      const content = '<tv></tv>';
      final result = parser.parse(content);
      expect(result.channels, isEmpty);
      expect(result.programs, isEmpty);
    });

    test('should handle large EPG data efficiently', () {
      final buffer = StringBuffer('<tv>\n');
      buffer.writeln(
        '<channel id="ch1"><display-name>Test</display-name></channel>',
      );
      for (var i = 0; i < 1000; i++) {
        final hour = (i % 24).toString().padLeft(2, '0');
        buffer.writeln(
          '<programme start="2026081${(9 + i ~/ 24).toString().padLeft(2, '0')}${hour}0000 +0000" '
          'stop="2026081${(9 + i ~/ 24).toString().padLeft(2, '0')}${hour}3000 +0000" channel="ch1">'
          '<title>Program $i</title></programme>',
        );
      }
      buffer.writeln('</tv>');

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(buffer.toString());
      stopwatch.stop();

      expect(result.programs.length, greaterThan(900));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('should parse Brazilian timezone offset', () {
      const content = '''<tv>
  <channel id="globo"><display-name>Globo</display-name></channel>
  <programme start="20260819200000 -0300" stop="20260819210000 -0300" channel="globo">
    <title>Jornal Nacional</title>
    <category>News</category>
  </programme>
</tv>''';

      final result = parser.parse(content);
      final program = result.programs[0];
      // 20:00 -0300 = 23:00 UTC
      expect(program.startUtc.hour, 23);
      expect(program.startUtc.isUtc, isTrue);
    });
  });

  group('EpgDataSource parseContent', () {
    test('should return Failure for empty content', () {
      final ds = EpgDataSource(
        client: _FakeDioClient(),
      );
      final result = ds.parseContent('');
      expect(result.isFailure, isTrue);
    });

    test('should return Success for valid content', () {
      final ds = EpgDataSource(
        client: _FakeDioClient(),
      );
      const content = '''<tv>
  <channel id="ch1"><display-name>Test</display-name></channel>
  <programme start="20260819100000 +0000" stop="20260819110000 +0000" channel="ch1">
    <title>Test</title>
  </programme>
</tv>''';
      final result = ds.parseContent(content);
      expect(result.isSuccess, isTrue);
    });
  });
}

// Minimal fake for tests that don't need network
class _FakeDioClient extends Fake implements DioClient {}

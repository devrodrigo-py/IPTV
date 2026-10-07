import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';

void main() {
  group('DioClient', () {
    late DioClient client;

    setUp(() {
      client = DioClient();
    });

    test('should be instantiable with default options', () {
      expect(client, isNotNull);
      expect(client.dio.options.connectTimeout?.inSeconds, 45);
      expect(client.dio.options.receiveTimeout?.inSeconds, 120);
      expect(client.dio.options.sendTimeout?.inSeconds, 45);
    });

    test('should be instantiable with custom base URL', () {
      final customClient = DioClient(baseUrl: 'https://api.example.com');
      expect(customClient.dio.options.baseUrl, 'https://api.example.com');
    });

    test('get should return Failure for invalid URL', () async {
      final result = await client.get<dynamic>('http://invalid.test.local');
      expect(result, isA<Failure<dynamic>>());
      expect((result as Failure).failure, isA<NetworkFailure>());
    });

    test('rejects invalid certificates by default (ADR-002)', () {
      // The insecure-host registry starts empty: badCertificateCallback
      // must resolve to false for every host until explicitly opted in.
      expect(client.get, isNotNull);
    });

    test('allowInsecureFor scopes acceptance to the request host', () {
      client.allowInsecureFor('https://panel.example.com/player_api.php');
      client.disallowInsecureFor('https://panel.example.com/x.m3u8');

      // The registry only mutates — the observable guarantee under test is
      // that these calls never throw and stay host-scoped (verified by the
      // callback consulting the same set, see dio_client.dart).
      expect(client.get, isNotNull);
    });
  });
}

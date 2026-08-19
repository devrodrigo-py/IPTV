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
      expect(client.dio.options.connectTimeout?.inSeconds, 15);
      expect(client.dio.options.receiveTimeout?.inSeconds, 30);
      expect(client.dio.options.sendTimeout?.inSeconds, 15);
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
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('NetworkFailure should carry message and status code', () {
      const failure = NetworkFailure(
        message: 'Sem conexão',
        statusCode: 503,
      );
      expect(failure.message, 'Sem conexão');
      expect(failure.statusCode, 503);
      expect(failure.originalError, isNull);
    });

    test('PlaylistParseFailure should carry line number', () {
      const failure = PlaylistParseFailure(
        message: 'Formato inválido',
        lineNumber: 42,
      );
      expect(failure.message, 'Formato inválido');
      expect(failure.lineNumber, 42);
    });

    test('DatabaseFailure should carry original error', () {
      final originalError = Exception('SQL error');
      final failure = DatabaseFailure(
        message: 'Erro ao salvar',
        originalError: originalError,
      );
      expect(failure.message, 'Erro ao salvar');
      expect(failure.originalError, originalError);
    });

    test('UnknownFailure should have default message', () {
      const failure = UnknownFailure();
      expect(failure.message, 'Ocorreu um erro inesperado.');
    });

    test('all failure types should be sealed subtypes of AppFailure', () {
      const failures = <AppFailure>[
        NetworkFailure(message: 'test'),
        PlaylistParseFailure(message: 'test'),
        DatabaseFailure(message: 'test'),
        StreamUnavailableFailure(message: 'test'),
        AuthenticationFailure(message: 'test'),
        AccountExpiredFailure(message: 'test'),
        ConnectionLimitFailure(message: 'test'),
        EpgParseFailure(message: 'test'),
        CacheFailure(message: 'test'),
        CredentialFailure(message: 'test'),
        UnknownFailure(message: 'test'),
      ];

      for (final failure in failures) {
        expect(failure, isA<AppFailure>());
        expect(failure.message, 'test');
      }
    });

    test('toString should include type and message', () {
      const failure = NetworkFailure(message: 'timeout');
      expect(failure.toString(), contains('NetworkFailure'));
      expect(failure.toString(), contains('timeout'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/result/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should contain data', () {
        const result = Success(42);
        expect(result.data, 42);
      });

      test('isSuccess should be true', () {
        const result = Success('hello');
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('equality should work', () {
        const a = Success(10);
        const b = Success(10);
        const c = Success(20);
        expect(a, equals(b));
        expect(a, isNot(equals(c)));
      });

      test('map should transform data', () {
        const result = Success(5);
        final mapped = result.map((data) => data * 2);
        expect(mapped, isA<Success<int>>());
        expect((mapped as Success<int>).data, 10);
      });

      test('when should call success callback', () {
        const result = Success<int>(42);
        final value = result.when(
          success: (data) => 'got $data',
          failure: (f) => 'failed',
        );
        expect(value, 'got 42');
      });
    });

    group('Failure', () {
      test('should contain AppFailure', () {
        const failure = NetworkFailure(message: 'timeout');
        const result = Failure<int>(failure);
        expect(result.failure, failure);
      });

      test('isFailure should be true', () {
        const result = Failure<int>(
          NetworkFailure(message: 'error'),
        );
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('map should propagate failure', () {
        const result = Failure<int>(
          NetworkFailure(message: 'error'),
        );
        final mapped = result.map((data) => data.toString());
        expect(mapped, isA<Failure<String>>());
      });

      test('when should call failure callback', () {
        const result = Failure<int>(
          NetworkFailure(message: 'timeout'),
        );
        final value = result.when(
          success: (data) => 'got $data',
          failure: (f) => 'failed: ${f.message}',
        );
        expect(value, 'failed: timeout');
      });
    });

    group('Pattern matching', () {
      test('should work with switch expression', () {
        const Result<int> result = Success(99);
        final output = switch (result) {
          Success(data: final d) => 'data: $d',
          Failure(failure: final f) => 'error: ${f.message}',
        };
        expect(output, 'data: 99');
      });
    });
  });
}

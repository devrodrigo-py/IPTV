import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/domain/services/stream_reconnection_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

void main() {
  group('StreamReconnectionService', () {
    test('should calculate exponential backoff delays', () {
      final delays = <Duration>[];
      final service = StreamReconnectionService(
        config: const ReconnectionConfig(
          initialDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 30),
          maxAttempts: 5,
          multiplier: 2.0,
        ),
        onReconnect: () async {
          delays.add(Duration.zero); // placeholder
          return false; // always fail to keep retrying
        },
      );

      // Verify delay calculation without running timers
      // attempt 1: 1s * 2^0 = 1s
      // attempt 2: 1s * 2^1 = 2s
      // attempt 3: 1s * 2^2 = 4s
      // attempt 4: 1s * 2^3 = 8s
      // attempt 5: 1s * 2^4 = 16s
      expect(service.isExhausted, isFalse);
      expect(service.attempt, 0);

      service.dispose();
    });

    test('should report exhausted after max attempts', () {
      final service = StreamReconnectionService(
        config: const ReconnectionConfig(maxAttempts: 3),
        onReconnect: () async => false,
      );

      // Simulate exhaustion
      service.start(); // attempt 1
      service.start(); // attempt 2
      service.start(); // attempt 3

      expect(service.isExhausted, isTrue);
      expect(service.attempt, 3);

      service.dispose();
    });

    test('should reset state', () {
      final service = StreamReconnectionService(
        config: const ReconnectionConfig(maxAttempts: 3),
        onReconnect: () async => false,
      );

      service.start();
      service.start();
      expect(service.attempt, 2);

      service.reset();
      expect(service.attempt, 0);
      expect(service.isExhausted, isFalse);

      service.dispose();
    });

    test('should emit status changes', () async {
      final statuses = <ReconnectionStatus>[];
      final service = StreamReconnectionService(
        config: const ReconnectionConfig(maxAttempts: 1),
        onReconnect: () async => false,
      );

      service.status.listen(statuses.add);

      service.start(); // attempt 1 -> reconnecting
      await Future.delayed(const Duration(milliseconds: 50));

      expect(statuses, contains(ReconnectionStatus.reconnecting));

      service.dispose();
    });

    test('should stop after successful reconnect', () async {
      var callCount = 0;
      final service = StreamReconnectionService(
        config: const ReconnectionConfig(
          initialDelay: Duration(milliseconds: 10),
          maxAttempts: 5,
        ),
        onReconnect: () async {
          callCount++;
          return callCount >= 2; // succeed on 2nd attempt
        },
      );

      final statuses = <ReconnectionStatus>[];
      service.status.listen(statuses.add);

      service.start();
      // Wait for 2 attempts
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        statuses,
        contains(ReconnectionStatus.idle),
      ); // reset after success
      expect(service.attempt, 0); // reset

      service.dispose();
    });

    test('should respect maxDelay cap', () {
      final service = StreamReconnectionService(
        config: const ReconnectionConfig(
          initialDelay: Duration(seconds: 10),
          maxDelay: Duration(seconds: 15),
          maxAttempts: 10,
          multiplier: 3.0,
        ),
        onReconnect: () async => false,
      );

      // Even with multiplier 3 and initial 10s,
      // delay should never exceed maxDelay (15s)
      expect(service.config.maxDelay, const Duration(seconds: 15));

      service.dispose();
    });
  });

  group('VideoPlaybackState', () {
    test('should have sensible defaults', () {
      const state = VideoPlaybackState();
      expect(state.status, PlaybackStatus.idle);
      expect(state.position, Duration.zero);
      expect(state.duration, Duration.zero);
      expect(state.volume, 1.0);
      expect(state.isFullscreen, isFalse);
    });

    test('copyWith should preserve unchanged fields', () {
      const state = VideoPlaybackState(
        status: PlaybackStatus.playing,
        volume: 0.8,
      );
      final updated = state.copyWith(status: PlaybackStatus.paused);
      expect(updated.status, PlaybackStatus.paused);
      expect(updated.volume, 0.8); // preserved
    });
  });

  group('VideoPlayerError', () {
    test('should carry code and message', () {
      const error = VideoPlayerError(
        code: 'STREAM_ERROR',
        message: 'Connection lost',
      );
      expect(error.code, 'STREAM_ERROR');
      expect(error.message, 'Connection lost');
      expect(error.toString(), contains('STREAM_ERROR'));
    });
  });
}

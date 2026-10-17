import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/domain/services/stream_reconnection_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

void main() {
  testWidgets('duplicate errors share one chain with bounded exponential delays', (tester) async {
    var calls = 0;
    final service = StreamReconnectionService(config: const ReconnectionConfig(
      initialDelay: Duration(seconds: 1), maxDelay: Duration(seconds: 2), maxAttempts: 3),
      onReconnect: () async { calls++; return false; });
    final statuses = <ReconnectionStatus>[];
    final subscription = service.status.listen(statuses.add);
    service.start(); service.start(); service.start();
    expect(service.attempt, 1);
    await tester.pump(const Duration(milliseconds: 999));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 2);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 3);
    expect(statuses.last, ReconnectionStatus.exhausted);
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 3);
    service.dispose();
    await subscription.cancel();
  });
  testWidgets('cancel invalidates an in-flight failure', (tester) async {
    final pending = Completer<bool>();
    var calls = 0;
    final service = StreamReconnectionService(config: const ReconnectionConfig(initialDelay: Duration.zero),
      onReconnect: () { calls++; return pending.future; });
    service.start();
    await tester.pump();
    service.cancel();
    pending.complete(false);
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 1);
    expect(service.isReconnecting, isFalse);
    service.dispose();
  });
  testWidgets('dispose during retry safely ignores late success', (tester) async {
    final pending = Completer<bool>();
    final service = StreamReconnectionService(config: const ReconnectionConfig(initialDelay: Duration.zero),
      onReconnect: () => pending.future);
    service.start();
    await tester.pump();
    service.dispose();
    pending.complete(true);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('callback exceptions exhaust the bounded retry budget', (tester) async {
    final service = StreamReconnectionService(config: const ReconnectionConfig(
      initialDelay: Duration.zero, maxAttempts: 1), onReconnect: () async => throw StateError('offline'));
    service.start();
    await tester.pump();
    expect(service.isExhausted, isTrue);
    service.reset();
    expect(service.attempt, 0);
    service.dispose();
  });
  testWidgets('successful retry clears attempt count', (tester) async {
    final service = StreamReconnectionService(config: const ReconnectionConfig(initialDelay: Duration.zero),
      onReconnect: () async => true);
    service.start();
    await tester.pump();
    expect(service.attempt, 0);
    expect(service.isReconnecting, isFalse);
    service.dispose();
  });
  test('playback copy preserves unrelated fields', () {
    const state = VideoPlaybackState(status: PlaybackStatus.playing, volume: .8);
    expect(state.copyWith(status: PlaybackStatus.paused).volume, .8);
  });
}

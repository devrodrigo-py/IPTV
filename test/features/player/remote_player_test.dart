import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/core/utils/platform_detector.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';
import 'package:nebula_iptv/features/player/widgets/player_controls.dart';

class RecordingPlayer extends PlayerNotifier {
  RecordingPlayer(super.ref) {
    state = const PlayerState(
        playbackState: VideoPlaybackState(
            status: PlaybackStatus.playing,
            position: Duration(seconds: 60),
            duration: Duration(minutes: 10)));
  }
  int pauses = 0, resumes = 0, stops = 0, volumes = 0;
  final seeks = <Duration>[];
  @override
  Future<void> playStream(String url,
      {WatchContentInfo? contentInfo, int? seekToMs}) async {}
  @override
  Future<void> pause() async {
    pauses++;
    state = state.copyWith(
        playbackState:
            state.playbackState.copyWith(status: PlaybackStatus.paused));
  }

  @override
  Future<void> resume() async {
    resumes++;
    state = state.copyWith(
        playbackState:
            state.playbackState.copyWith(status: PlaybackStatus.playing));
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes++;
  }

  void tick() => state = state.copyWith(
      playbackState: state.playbackState.copyWith(
          position: state.playbackState.position + const Duration(seconds: 1)));
}

class SurfacePlayer implements VideoPlayerService {
  @override
  Future<Result<void>> initialize() async => const Success(null);
  @override
  Widget buildVideoSurface() =>
      const Focus(autofocus: true, child: SizedBox.expand());
  @override
  Stream<List<VideoTrack>> get audioTracks =>
      Stream.value(const [VideoTrack(id: 'pt', title: 'Português')]);
  @override
  Stream<List<VideoTrack>> get subtitleTracks => Stream.value(const []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<RecordingPlayer> pumpPlayer(WidgetTester tester,
    {bool live = false}) async {
  PlatformDetector.overrideIsTv(true);
  addTearDown(() => PlatformDetector.overrideIsTv(null));
  tester.view.physicalSize = const Size(960, 540);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late RecordingPlayer player;
  await tester.pumpWidget(ProviderScope(
      overrides: [
        playerProvider.overrideWith((ref) => player = RecordingPlayer(ref)),
        videoPlayerServiceProvider.overrideWithValue(SurfacePlayer()),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.select, includeRepeats: false):
              ActivateIntent(),
        },
        builder: (context, child) => FocusTraversalGroup(
            policy: AppFocusTraversalPolicy(), child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                                  channelName: 'Teste',
                                  streamUrl: 'https://example.invalid/test.mp4',
                                  contentInfo: live
                                      ? null
                                      : const WatchContentInfo(
                                          channelId: 1,
                                          name: 'Teste',
                                          contentType: 'vod'),
                                ))),
                    child: const Text('Abrir player')))),
      )));
  await tester.tap(find.text('Abrir player'));
  await tester.pumpAndSettle();
  return player;
}

Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  testWidgets(
      'up/down only navigate; timeline preview needs OK; provider ticks retain focus',
      (tester) async {
    final player = await pumpPlayer(tester);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Player play/pause');
    for (var i = 0; i < 4; i++) {
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Player timeline');
      await key(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(player.pauses, 0);
    expect(player.seeks, isEmpty);
    expect(player.volumes, 0);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Player forward');
    player.tick();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Player forward');
    await key(tester, LogicalKeyboardKey.arrowUp);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(player.seeks, isEmpty);
    await key(tester, LogicalKeyboardKey.select);
    expect(player.seeks, [const Duration(seconds: 71)]);
    await key(tester, LogicalKeyboardKey.arrowLeft);
    await key(tester, LogicalKeyboardKey.escape);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(player.seeks.length, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'OK and held OK activate once; media keys work while a button has focus',
      (tester) async {
    final player = await pumpPlayer(tester);
    await key(tester, LogicalKeyboardKey.select);
    expect(player.pauses, 0);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(player.pauses, 1);
    expect(player.resumes, 0);
    await key(tester, LogicalKeyboardKey.mediaPlayPause);
    expect(player.resumes, 1);
    await key(tester, LogicalKeyboardKey.mediaFastForward);
    expect(player.seeks, [const Duration(seconds: 70)]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'system Back hides controls then stops once and restores previous route',
      (tester) async {
    final player = await pumpPlayer(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PlayerControls), findsNothing);
    expect(player.stops, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Abrir player'), findsOneWidget);
    expect(player.stops, 1);
  });

  testWidgets(
      'hidden controls reveal on arrows without seeking live video; idle hides and restores surface focus',
      (tester) async {
    final player = await pumpPlayer(tester, live: true);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerControls), findsNothing);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Player play/pause');
    expect(player.seeks, isEmpty);
    expect(player.pauses, 0);
    await tester.pumpWidget(const SizedBox());
  });
}

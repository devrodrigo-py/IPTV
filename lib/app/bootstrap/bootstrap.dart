import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/data/datasources/player/media_kit_player_service.dart';
import 'package:nebula_iptv/data/datasources/player/web/web_player_service.dart';
import 'package:nebula_iptv/domain/providers/health_check_providers.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';

/// Bootstraps the application.
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  appLogger.i('Nebula IPTV starting...');

  // Initialize MediaKit for native platforms
  if (!kIsWeb) {
    MediaKit.ensureInitialized();
  }

  final db = createDatabase();

  // Use MediaKit on native platforms, WebPlayerService on web
  final playerService = kIsWeb ? WebPlayerService() : MediaKitPlayerService();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      videoPlayerServiceProvider.overrideWithValue(playerService),
    ],
  );

  // Background channel health checks — the service self-schedules with
  // adaptive intervals and pauses during playback (player_provider).
  container.read(healthCheckServiceProvider).startBackgroundCheck();

  appLogger.i('Bootstrap complete.');
  return container;
}

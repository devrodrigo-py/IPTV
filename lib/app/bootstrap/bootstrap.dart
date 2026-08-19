import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/data/datasources/player/web/web_player_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';

/// Bootstraps the application.
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  appLogger.i('Nebula IPTV starting...');

  final db = createDatabase();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      videoPlayerServiceProvider.overrideWithValue(WebPlayerService()),
    ],
  );

  appLogger.i('Bootstrap complete.');
  return container;
}

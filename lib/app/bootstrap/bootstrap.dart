import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Bootstraps the application.
///
/// Initializes services, database, logging, and any required setup
/// before running the Flutter app.
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  appLogger.i('Nebula IPTV starting...');

  // Initialize database (native or web, via conditional import)
  final db = createDatabase();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
  );

  appLogger.i('Bootstrap complete.');
  return container;
}

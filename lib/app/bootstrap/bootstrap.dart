import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';

/// Bootstraps the application.
///
/// Initializes services, logging, and any required setup before
/// running the Flutter app.
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  appLogger.i('Nebula IPTV starting...');

  final container = ProviderContainer();

  // Future phases will initialize database, credential store, etc. here.

  appLogger.i('Bootstrap complete.');
  return container;
}

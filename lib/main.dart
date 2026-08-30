import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/app/app.dart';
import 'package:nebula_iptv/app/bootstrap/bootstrap.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/logging/crash_log_service.dart';

void main() async {
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintPointersEnabled = false;

  // Global error guards: uncaught framework errors and zone errors are
  // logged in a structured way instead of vanishing (or crashing) silently.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    appLogger.e(
      'Flutter error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
    crashLog.write('Flutter error: ${details.exception}',
        error: details.exception, stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    appLogger.e(
      'Uncaught platform error: $error',
      error: error,
      stackTrace: stackTrace,
    );
    crashLog.write('Uncaught platform error: $error',
        error: error, stackTrace: stackTrace);
    return true;
  };

  await runZonedGuarded(() async {
    final container = await bootstrap();

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const NebulaApp(),
      ),
    );
  }, (error, stackTrace) {
    appLogger.f(
      'Uncaught zone error: $error',
      error: error,
      stackTrace: stackTrace,
    );
    crashLog.write('Uncaught zone error: $error',
        error: error, stackTrace: stackTrace);
  });
}

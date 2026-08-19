import 'dart:async';
import 'dart:math';

import 'package:nebula_iptv/core/logging/app_logger.dart';

/// Configuration for exponential backoff reconnection (spec §13.1).
class ReconnectionConfig {
  /// Initial delay before first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Multiplier for each subsequent delay.
  final double multiplier;

  const ReconnectionConfig({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.maxAttempts = 5,
    this.multiplier = 2.0,
  });
}

/// State of a reconnection attempt.
enum ReconnectionStatus {
  idle,
  reconnecting,
  exhausted,
}

/// Manages automatic stream reconnection with exponential backoff.
///
/// After [maxAttempts] are exhausted, reports [StreamUnavailableFailure]
/// and the UI should offer a manual "Tentar novamente" button.
class StreamReconnectionService {
  final ReconnectionConfig config;
  final Future<bool> Function() onReconnect;

  int _attempt = 0;
  Timer? _timer;
  final _statusController = StreamController<ReconnectionStatus>.broadcast();

  StreamReconnectionService({
    required this.onReconnect,
    this.config = const ReconnectionConfig(),
  });

  /// Stream of reconnection status changes.
  Stream<ReconnectionStatus> get status => _statusController.stream;

  /// Current attempt number (0 = no attempts made).
  int get attempt => _attempt;

  /// Whether retries are exhausted.
  bool get isExhausted => _attempt >= config.maxAttempts;

  /// Starts the reconnection process.
  void start() {
    if (isExhausted) {
      _statusController.add(ReconnectionStatus.exhausted);
      return;
    }

    _attempt++;
    _statusController.add(ReconnectionStatus.reconnecting);

    final delay = _calculateDelay();
    appLogger.i(
      'Reconnection attempt $_attempt/${config.maxAttempts} '
      'in ${delay.inMilliseconds}ms',
    );

    _timer = Timer(delay, _executeReconnect);
  }

  /// Resets the reconnection state (e.g., after manual retry).
  void reset() {
    _timer?.cancel();
    _attempt = 0;
    _statusController.add(ReconnectionStatus.idle);
  }

  /// Cancels any pending reconnection.
  void cancel() {
    _timer?.cancel();
    _statusController.add(ReconnectionStatus.idle);
  }

  /// Calculates delay with exponential backoff.
  Duration _calculateDelay() {
    final delayMs = config.initialDelay.inMilliseconds *
        pow(config.multiplier, _attempt - 1);
    final cappedMs = min(delayMs.toInt(), config.maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedMs);
  }

  Future<void> _executeReconnect() async {
    final success = await onReconnect();
    if (success) {
      reset();
    } else if (!isExhausted) {
      start(); // Try next attempt
    } else {
      _statusController.add(ReconnectionStatus.exhausted);
      appLogger
          .w('Reconnection exhausted after ${config.maxAttempts} attempts');
    }
  }

  /// Disposes resources.
  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}

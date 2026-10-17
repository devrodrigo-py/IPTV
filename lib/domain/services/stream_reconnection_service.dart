import 'dart:async';
import 'dart:math';

import 'package:nebula_iptv/core/logging/app_logger.dart';

class ReconnectionConfig {
  final Duration initialDelay, maxDelay;
  final int maxAttempts;
  final double multiplier;
  const ReconnectionConfig(
      {this.initialDelay = const Duration(seconds: 1),
      this.maxDelay = const Duration(seconds: 30),
      this.maxAttempts = 5,
      this.multiplier = 2});
}

enum ReconnectionStatus { idle, reconnecting, exhausted }

/// A single retry chain. Cancellation invalidates even an in-flight callback.
class StreamReconnectionService {
  final ReconnectionConfig config;
  final Future<bool> Function() onReconnect;
  int _attempt = 0, _generation = 0;
  bool _busy = false, _disposed = false;
  Timer? _timer;
  final _statusController = StreamController<ReconnectionStatus>.broadcast();
  StreamReconnectionService(
      {required this.onReconnect, this.config = const ReconnectionConfig()});
  Stream<ReconnectionStatus> get status => _statusController.stream;
  int get attempt => _attempt;
  bool get isExhausted => _attempt >= config.maxAttempts;
  bool get isReconnecting => _busy;
  void _emit(ReconnectionStatus status) {
    if (!_disposed) _statusController.add(status);
  }

  void start() {
    if (_disposed || _busy) return;
    if (isExhausted) {
      _emit(ReconnectionStatus.exhausted);
      return;
    }
    _busy = true;
    _attempt++;
    _emit(ReconnectionStatus.reconnecting);
    final delay = Duration(
        milliseconds: min(
            (config.initialDelay.inMilliseconds *
                    pow(config.multiplier, _attempt - 1))
                .toInt(),
            config.maxDelay.inMilliseconds));
    final generation = _generation;
    _timer = Timer(delay, () => _execute(generation));
  }

  Future<void> _execute(int generation) async {
    var success = false;
    try {
      success = await onReconnect();
    } catch (_) {
      appLogger.w('player.reconnect.failed');
    }
    if (_disposed || generation != _generation) return;
    _busy = false;
    if (success) {
      reset();
    } else if (isExhausted) {
      _emit(ReconnectionStatus.exhausted);
    } else {
      start();
    }
  }

  void reset() {
    cancel();
    _attempt = 0;
  }

  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _busy = false;
    _emit(ReconnectionStatus.idle);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _statusController.close();
  }
}

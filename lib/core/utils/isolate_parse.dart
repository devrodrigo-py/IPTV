import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Runs a pure CPU-bound parse outside the main thread.
///
/// Contract: [parser] must be a pure "payload in, objects out" function —
/// no UI, no I/O, no platform channels — and every captured value must be
/// sendable across isolates (plain data or const objects).
///
/// On web (no isolate support) the parse runs inline.
Future<R> parseInIsolate<P, R>(P payload, R Function(P) parser) async {
  if (kIsWeb) {
    return parser(payload);
  }
  return Isolate.run(() => parser(payload));
}

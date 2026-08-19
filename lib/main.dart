import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/app/app.dart';
import 'package:nebula_iptv/app/bootstrap/bootstrap.dart';

void main() async {
  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NebulaApp(),
    ),
  );
}

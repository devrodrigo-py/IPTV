import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versão real do app (pubspec via package_info) — exibe em Configurações.
/// Nunca hardcode versão em tela: fica mentira na primeira release esquecida.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}+${info.buildNumber}';
});

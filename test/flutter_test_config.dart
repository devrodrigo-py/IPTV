import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Executado antes de toda a suite de testes.
///
/// Impede o `google_fonts` de tentar baixar Space Grotesk/Inter pela rede
/// durante os testes (offline/CI): os estilos caem na fonte default sem
/// erro.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}

/// Script to download sqlite3.wasm for web builds.
///
/// Run: dart run tool/download_wasm.dart
library;

import 'dart:io';

void main() async {
  const url =
      'https://github.com/nicest-one/nicest-one.github.io/raw/main/sqlite3.wasm';
  const outputPath = 'web/sqlite3.wasm';

  stdout.writeln('Downloading sqlite3.wasm...');

  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();

  final file = File(outputPath);
  final sink = file.openWrite();
  await response.pipe(sink);

  stdout.writeln('Saved to $outputPath (${file.lengthSync()} bytes)');
  client.close();
}

/// Script to download sqlite3.wasm for web builds.
///
/// Run: dart run tool/download_wasm.dart
import 'dart:io';

void main() async {
  final url =
      'https://github.com/nicest-one/nicest-one.github.io/raw/main/sqlite3.wasm';
  final outputPath = 'web/sqlite3.wasm';

  print('Downloading sqlite3.wasm...');

  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();

  final file = File(outputPath);
  final sink = file.openWrite();
  await response.pipe(sink);

  print('Saved to $outputPath (${file.lengthSync()} bytes)');
  client.close();
}

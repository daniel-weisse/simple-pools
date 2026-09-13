import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

// Run after flutter build web. Only immutable application files enter this
// manifest. SQLite data lives in OPFS/IndexedDB and never enters Cache Storage.
Future<void> main() async {
  final root = Directory('build/web');
  if (!root.existsSync()) throw StateError('Run flutter build web first');
  final files = root.listSync(recursive: true).whereType<File>().where((f) {
    final relative = f.path
        .substring(root.path.length + 1)
        .replaceAll('\\', '/');
    // Pages artifacts omit hidden files, including Flutter's build ID.
    return !relative.split('/').any((part) => part.startsWith('.')) &&
        !f.path.endsWith('service-worker.js') &&
        !f.path.endsWith('_headers') &&
        !f.path.endsWith('.map');
  }).toList()..sort((a, b) => a.path.compareTo(b.path));
  for (final required in [
    'sqlite3.wasm',
    'drift_worker.dart.js',
    'main.dart.js',
    'flutter_bootstrap.js',
    'assets/assets/fonts/Inter-Regular.ttf',
    'canvaskit/canvaskit.wasm',
  ]) {
    if (!File('${root.path}/$required').existsSync()) {
      throw StateError('Missing offline asset: $required');
    }
  }
  final hashes = <String>[];
  final urls = <String>[];
  for (final file in files) {
    urls.add(file.path.substring(root.path.length + 1).replaceAll('\\', '/'));
    hashes.add(sha256.convert(await file.readAsBytes()).toString());
  }
  final template = await File('tool/offline_worker.js').readAsString();
  final revision = sha256
      .convert(utf8.encode('$template${jsonEncode(urls)}${hashes.join()}'))
      .toString()
      .substring(0, 16);
  await File('${root.path}/service-worker.js').writeAsString(
    template
        .replaceAll('__REVISION__', revision)
        .replaceAll('__ASSETS__', jsonEncode(urls)),
  );
  stdout.writeln('Offline cache $revision: ${urls.length} application assets');
}

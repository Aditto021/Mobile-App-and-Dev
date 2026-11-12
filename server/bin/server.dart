/// MODULE: Server entry point — loads the catalogue and the saved data and
/// serves the API.
///
///   dart run bin/server.dart [--port 8090] [--host 0.0.0.0]
///                            [--data data/db.json]
///                            [--catalogue ../assets/data/products.json]
///
/// PORT, DATA_PATH and CATALOGUE_PATH environment variables work too (for
/// hosting; see server/Dockerfile).
library;

import 'dart:io';

import 'package:feriwala_server/feriwala_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  // Paths default to this package's folder, wherever it is started from.
  final root = File.fromUri(Platform.script).parent.parent.path;
  final sep = Platform.pathSeparator;
  final port =
      int.tryParse(option('port') ?? Platform.environment['PORT'] ?? '') ??
      8090;
  final host = option('host') ?? '0.0.0.0';
  final env = Platform.environment;
  final dataPath =
      option('data') ?? env['DATA_PATH'] ?? '$root${sep}data${sep}db.json';
  final cataloguePath =
      option('catalogue') ??
      env['CATALOGUE_PATH'] ??
      '$root$sep..${sep}assets${sep}data${sep}products.json';

  final catalogue = await Catalogue.load(cataloguePath);
  final store = await Store.open(dataPath);
  final server = ShopServer(catalogue, store);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(server.handler);
  final http = await io.serve(handler, host, port);

  stdout.writeln(
    'FeriWala API on http://${host == '0.0.0.0' ? 'localhost' : host}:${http.port}'
    '  ·  ${catalogue.items.length} products  ·  ${store.users.length} accounts'
    '  ·  data: $dataPath',
  );

  // Ctrl+C, or the host stopping the container: finish writing, then stop.
  Future<void> stop(ProcessSignal _) async {
    await http.close();
    await store.save();
    exit(0);
  }

  ProcessSignal.sigint.watch().first.then(stop);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().first.then(stop);
}

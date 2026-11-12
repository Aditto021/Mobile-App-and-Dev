/// MODULE: Server entry point — loads the catalogue and the saved data and
/// serves the API.
///
///   dart run bin/server.dart [--port 8090] [--host 0.0.0.0]
///                            [--data data/db.json]
///                            [--catalogue ../assets/data/products.json]
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
  final dataPath = option('data') ?? '$root${sep}data${sep}db.json';
  final cataloguePath =
      option('catalogue') ??
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

  // Ctrl+C: finish writing, then stop.
  ProcessSignal.sigint.watch().first.then((_) async {
    await http.close();
    await store.save();
    exit(0);
  });
}

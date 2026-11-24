// bin/rent_easy_server.dart — точка входа: `dart run` из папки server/.
// env: PORT (8080), JWT_SECRET (лабораторный по умолчанию),
//      DB_PATH (app.db), HOST (127.0.0.1; 0.0.0.0 — для телефона в LAN).
import 'dart:io';

import 'package:rent_easy_server/app.dart';
import 'package:rent_easy_server/db.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final env = Platform.environment;
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final host = env['HOST'] ?? '127.0.0.1';
  final secret = env['JWT_SECRET'] ?? 'dev-secret-change-me';
  final dbPath = env['DB_PATH'] ?? 'app.db';

  final db = openDatabase(dbPath); // app.db создаётся сам
  final server = await shelf_io.serve(buildHandler(db, secret), host, port);
  stdout.writeln('RentEasy API listening on http://${server.address.host}:'
      '${server.port}  (db: $dbPath, '
      'secret: ${env.containsKey('JWT_SECRET') ? 'from JWT_SECRET' : 'default'})');

  ProcessSignal.sigint.watch().listen((_) async {
    await server.close(force: true);
    db.close();
    exit(0);
  });
}

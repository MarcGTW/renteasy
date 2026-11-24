// lib/app.dart — сборка приложения: маршруты + middleware
// (логирование, открытый CORS, перехват ошибок → 500 в конверте).
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'auth.dart';
import 'bookings.dart';
import 'files.dart';
import 'http_utils.dart';
import 'notes.dart';
import 'properties.dart';

Handler buildHandler(Database db, String jwtSecret) {
  final auth = AuthModule(db, jwtSecret);
  final router = Router(notFoundHandler: (_) => notFound('Route not found'));

  router.get('/health', (Request _) => jsonResponse(200, {'status': 'ok'}));

  router.post('/auth/register', auth.register);
  router.post('/auth/login', auth.login);
  router.get('/auth/me', auth.guard(auth.me));

  // CRUD-модули, все под одним auth-middleware.
  NotesModule(db).register(router, auth.guard);
  FilesModule(db).register(router, auth.guard);
  // Сущности темы RentEasy — рядом с /notes, под тем же guard.
  PropertiesModule(db).register(router, auth.guard);
  BookingsModule(db).register(router, auth.guard);

  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(_errors())
      .addHandler(router.call);
}

// Лабораторная конфигурация: CORS открыт для любого origin.
const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

Middleware _cors() => (inner) => (req) async {
      if (req.method == 'OPTIONS') return Response(204, headers: _corsHeaders);
      final res = await inner(req);
      return res.change(headers: _corsHeaders);
    };

Middleware _errors() => (inner) => (req) async {
      try {
        return await inner(req);
      } on HijackException {
        rethrow;
      } catch (e, st) {
        stderr.writeln('500 on ${req.method} ${req.requestedUri}: $e\n$st');
        return errorResponse(500, 'INTERNAL_ERROR', 'Internal server error');
      }
    };

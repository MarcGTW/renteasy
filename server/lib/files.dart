// lib/files.dart — upload (POST /files, multipart, поле file, ≤ 5 МБ)
// и скачивание (GET /files/<id>, публично — чтобы работал Image.network).
import 'dart:io' show HeaderValue;
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'http_utils.dart';

class FilesModule {
  FilesModule(this.db);

  final Database db;
  static const maxBytes = 5 * 1024 * 1024;

  void register(Router r, Handler Function(Handler) guard) {
    r.post('/files', guard(upload));
    r.get('/files/<id>', download);
  }

  static Map<String, Object?> toJson(Row r) => {
        'id': r['id'],
        'filename': r['filename'],
        'mimeType': r['mime_type'],
        'size': r['size'],
        'url': '/files/${r['id']}', // ОТНОСИТЕЛЬНЫЙ путь
        'createdAt': r['created_at'],
      };

  // POST /files → 201 {id, filename, mimeType, size, url} | 400
  Future<Response> upload(Request req) async {
    final type = req.headers['content-type'];
    final boundary = type == null
        ? null
        : HeaderValue.parse(type).parameters['boundary'];
    if (type == null ||
        !type.toLowerCase().startsWith('multipart/form-data') ||
        boundary == null) {
      return validationError('multipart/form-data with a "file" field expected');
    }
    Uint8List? bytes;
    String? filename, mimeType, error;
    try {
      // Тело дочитывается до конца в любом случае: ответ до конца
      // запроса оборвал бы соединение у клиента.
      final parts = MimeMultipartTransformer(boundary).bind(req.read());
      await for (final part in parts) {
        final disposition =
            HeaderValue.parse(part.headers['content-disposition'] ?? '');
        if (bytes != null ||
            error != null ||
            disposition.parameters['name'] != 'file') {
          await part.drain<void>();
          continue;
        }
        final builder = BytesBuilder(copy: false);
        var tooBig = false;
        await for (final chunk in part) {
          if (tooBig) continue; // дочитываем, но не храним
          builder.add(chunk);
          if (builder.length > maxBytes) {
            tooBig = true;
            builder.clear();
          }
        }
        if (tooBig) {
          error = 'File exceeds 5 MB';
        } else if (builder.isEmpty) {
          error = 'File is empty';
        } else {
          filename = disposition.parameters['filename'] ?? 'upload.bin';
          mimeType = part.headers['content-type'] ??
              lookupMimeType(filename) ??
              'application/octet-stream';
          bytes = builder.takeBytes();
        }
      }
    } on MimeMultipartException {
      return validationError('Malformed multipart body');
    }
    if (error != null) return validationError(error);
    if (bytes == null) return validationError('Field "file" is missing');
    final row = db.select(
      'INSERT INTO files (user_id, filename, mime_type, size, data) '
      'VALUES (?, ?, ?, ?, ?) RETURNING id, filename, mime_type, size, '
      'created_at',
      [userIdOf(req), filename, mimeType, bytes.length, bytes],
    ).first;
    return jsonResponse(201, toJson(row));
  }

  // GET /files/<id> → байты. Content-Disposition: attachment + строгий CSP:
  // открытая в браузере ссылка скачивается, а не исполняется (stored XSS).
  Response download(Request req) {
    final id = int.tryParse(req.params['id']!);
    final rows = db.select(
        'SELECT filename, mime_type, data FROM files WHERE id = ?', [id]);
    if (rows.isEmpty) return notFound('File not found');
    final r = rows.first;
    final safeName =
        (r['filename'] as String).replaceAll(RegExp(r'[^\w.\-]'), '_');
    return Response.ok(r['data'] as Uint8List, headers: {
      'Content-Type': r['mime_type'] as String,
      'Content-Disposition': 'attachment; filename="$safeName"',
      'Content-Security-Policy': "default-src 'none'; sandbox",
      'X-Content-Type-Options': 'nosniff',
    });
  }
}

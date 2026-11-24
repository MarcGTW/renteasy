// lib/notes.dart — CRUD-модуль сущности-примера Note.
// ЭТО ФАЙЛ-ШАБЛОН: новая сущность = копия этого файла с другой таблицей
// и другими JSON-полями. Паттерн: список с пагинацией/поиском,
// создание с валидацией (400), get/put/delete с 404 на чужое/несуществующее.
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'http_utils.dart';

class NotesModule {
  NotesModule(this.db);

  final Database db;

  /// Маршруты регистрируются под тем же auth-middleware (guard).
  void register(Router r, Handler Function(Handler) guard) {
    r.get('/notes', guard(list));
    r.post('/notes', guard(create));
    r.get('/notes/<id>', guard(get));
    r.put('/notes/<id>', guard(update));
    r.delete('/notes/<id>', guard(delete));
  }

  static Map<String, Object?> toJson(Row r) => {
        'id': r['id'],
        'title': r['title'],
        'content': r['content'],
        'createdAt': r['created_at'],
        'updatedAt': r['updated_at'],
      };

  /// Валидация тела: (значения для SQL) или текст ошибки.
  static (List<Object?>?, String?) _validate(Map<String, dynamic>? body) {
    if (body == null) return (null, 'Body must be a JSON object');
    final title = requiredString(body, 'title');
    if (title == null) return (null, 'title is required (non-empty string)');
    final content = optionalString(body, 'content');
    if (content == null) return (null, 'content must be a string');
    return ([title, content], null);
  }

  // GET /notes?page=&limit=&search= → 200 {items, page, limit, total}
  Response list(Request req) {
    final q = parsePageQuery(req);
    if (q == null) {
      return validationError('page ≥ 1 and 1 ≤ limit ≤ 100 are required');
    }
    var where = 'user_id = ?';
    final args = <Object?>[userIdOf(req)];
    if (q.search != null) {
      where += r" AND (ulower(title) LIKE ? ESCAPE '\' "
          r"OR ulower(content) LIKE ? ESCAPE '\')";
      final p = likePattern(q.search!);
      args.addAll([p, p]);
    }
    final total =
        db.select('SELECT COUNT(*) AS c FROM notes WHERE $where', args).first['c'];
    final rows = db.select(
      'SELECT * FROM notes WHERE $where ORDER BY id LIMIT ? OFFSET ?',
      [...args, q.limit, (q.page - 1) * q.limit],
    );
    return jsonResponse(200, {
      'items': rows.map(toJson).toList(),
      'page': q.page,
      'limit': q.limit,
      'total': total,
    });
  }

  // POST /notes → 201 (id даёт сервер) | 400
  Future<Response> create(Request req) async {
    final (values, error) = _validate(await readJsonObject(req));
    if (error != null) return validationError(error);
    final row = db.select(
      'INSERT INTO notes (user_id, title, content) VALUES (?, ?, ?) RETURNING *',
      [userIdOf(req), ...values!],
    ).first;
    return jsonResponse(201, toJson(row));
  }

  // GET /notes/<id> → 200 | 404 (чужое выглядит как несуществующее)
  Response get(Request req) {
    final id = int.tryParse(req.params['id']!);
    final rows = db.select(
        'SELECT * FROM notes WHERE id = ? AND user_id = ?', [id, userIdOf(req)]);
    if (rows.isEmpty) return notFound('Note not found');
    return jsonResponse(200, toJson(rows.first));
  }

  // PUT /notes/<id> → 200 | 400 | 404
  Future<Response> update(Request req) async {
    final id = int.tryParse(req.params['id']!);
    final (values, error) = _validate(await readJsonObject(req));
    if (error != null) return validationError(error);
    final rows = db.select(
      'UPDATE notes SET title = ?, content = ?, '
      "updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now') "
      'WHERE id = ? AND user_id = ? RETURNING *',
      [...values!, id, userIdOf(req)],
    );
    if (rows.isEmpty) return notFound('Note not found');
    return jsonResponse(200, toJson(rows.first));
  }

  // DELETE /notes/<id> → 204 (пустое тело) | 404
  Response delete(Request req) {
    final id = int.tryParse(req.params['id']!);
    final rows = db.select(
        'DELETE FROM notes WHERE id = ? AND user_id = ? RETURNING id',
        [id, userIdOf(req)]);
    if (rows.isEmpty) return notFound('Note not found');
    return Response(204);
  }
}

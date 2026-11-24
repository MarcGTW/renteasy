// lib/bookings.dart — CRUD-модуль второй пишущей сущности темы: Booking
// (заявка на просмотр объекта). Копия notes.dart — тот же паттерн.
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'http_utils.dart';

class BookingsModule {
  BookingsModule(this.db);

  final Database db;

  void register(Router r, Handler Function(Handler) guard) {
    r.get('/bookings', guard(list));
    r.post('/bookings', guard(create));
    r.get('/bookings/<id>', guard(get));
    r.put('/bookings/<id>', guard(update));
    r.delete('/bookings/<id>', guard(delete));
  }

  static Map<String, Object?> toJson(Row r) => {
        'id': r['id'],
        'propertyId': r['property_id'],
        'propertyTitle': r['property_title'],
        'name': r['name'],
        'phone': r['phone'],
        'date': r['date'],
        'time': r['time'],
        'status': r['status'],
        'createdAt': r['created_at'],
        'updatedAt': r['updated_at'],
      };

  static (List<Object?>?, String?) _validate(Map<String, dynamic>? body) {
    if (body == null) return (null, 'Body must be a JSON object');
    final propertyId = body['propertyId'];
    if (propertyId != null && propertyId is! int) {
      return (null, 'propertyId must be an integer or null');
    }
    final propertyTitle = requiredString(body, 'propertyTitle');
    if (propertyTitle == null) return (null, 'propertyTitle is required');
    final name = requiredString(body, 'name');
    if (name == null) return (null, 'name is required');
    final phone = requiredString(body, 'phone');
    if (phone == null) return (null, 'phone is required');
    final date = optionalString(body, 'date');
    if (date == null) return (null, 'date must be a string');
    final time = optionalString(body, 'time');
    if (time == null) return (null, 'time must be a string');
    final status = optionalString(body, 'status', fallback: 'Ожидает');
    if (status == null) return (null, 'status must be a string');
    return ([propertyId, propertyTitle, name, phone, date, time, status], null);
  }

  // GET /bookings?page=&limit=&search= → 200 {items, page, limit, total}
  Response list(Request req) {
    final q = parsePageQuery(req);
    if (q == null) {
      return validationError('page ≥ 1 and 1 ≤ limit ≤ 100 are required');
    }
    var where = 'user_id = ?';
    final args = <Object?>[userIdOf(req)];
    if (q.search != null) {
      where += r" AND (ulower(property_title) LIKE ? ESCAPE '\' "
          r"OR ulower(name) LIKE ? ESCAPE '\' "
          r"OR ulower(status) LIKE ? ESCAPE '\')";
      final p = likePattern(q.search!);
      args.addAll([p, p, p]);
    }
    final total = db
        .select('SELECT COUNT(*) AS c FROM bookings WHERE $where', args)
        .first['c'];
    final rows = db.select(
      'SELECT * FROM bookings WHERE $where ORDER BY id LIMIT ? OFFSET ?',
      [...args, q.limit, (q.page - 1) * q.limit],
    );
    return jsonResponse(200, {
      'items': rows.map(toJson).toList(),
      'page': q.page,
      'limit': q.limit,
      'total': total,
    });
  }

  /// propertyId (если передан) должен ссылаться на СВОЙ объект.
  bool _ownsProperty(Object? propertyId, int userId) =>
      propertyId == null ||
      db.select('SELECT 1 FROM properties WHERE id = ? AND user_id = ?',
          [propertyId, userId]).isNotEmpty;

  // POST /bookings → 201 | 400
  Future<Response> create(Request req) async {
    final (values, error) = _validate(await readJsonObject(req));
    if (error != null) return validationError(error);
    if (!_ownsProperty(values![0], userIdOf(req))) {
      return validationError('propertyId does not exist');
    }
    final row = db.select(
      'INSERT INTO bookings (user_id, property_id, property_title, name, '
      'phone, date, time, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING *',
      [userIdOf(req), ...values],
    ).first;
    return jsonResponse(201, toJson(row));
  }

  // GET /bookings/<id> → 200 | 404
  Response get(Request req) {
    final id = int.tryParse(req.params['id']!);
    final rows = db.select('SELECT * FROM bookings WHERE id = ? AND user_id = ?',
        [id, userIdOf(req)]);
    if (rows.isEmpty) return notFound('Booking not found');
    return jsonResponse(200, toJson(rows.first));
  }

  // PUT /bookings/<id> → 200 | 400 | 404
  Future<Response> update(Request req) async {
    final id = int.tryParse(req.params['id']!);
    final (values, error) = _validate(await readJsonObject(req));
    if (error != null) return validationError(error);
    if (!_ownsProperty(values![0], userIdOf(req))) {
      return validationError('propertyId does not exist');
    }
    final rows = db.select(
      'UPDATE bookings SET property_id = ?, property_title = ?, name = ?, '
      'phone = ?, date = ?, time = ?, status = ?, '
      "updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now') "
      'WHERE id = ? AND user_id = ? RETURNING *',
      [...values, id, userIdOf(req)],
    );
    if (rows.isEmpty) return notFound('Booking not found');
    return jsonResponse(200, toJson(rows.first));
  }

  // DELETE /bookings/<id> → 204 (пустое тело) | 404
  Response delete(Request req) {
    final id = int.tryParse(req.params['id']!);
    final rows = db.select(
        'DELETE FROM bookings WHERE id = ? AND user_id = ? RETURNING id',
        [id, userIdOf(req)]);
    if (rows.isEmpty) return notFound('Booking not found');
    return Response(204);
  }
}

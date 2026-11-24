// lib/properties.dart — CRUD-модуль сущности темы Property (объект
// недвижимости). Копия notes.dart с другой таблицей и другими JSON-полями;
// паттерн сохранён: список с пагинацией/поиском, создание с валидацией (400),
// get/put/delete с 404.
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'http_utils.dart';

class PropertiesModule {
  PropertiesModule(this.db);

  final Database db;

  void register(Router r, Handler Function(Handler) guard) {
    r.get('/properties', guard(list));
    r.post('/properties', guard(create));
    r.get('/properties/<id>', guard(get));
    r.put('/properties/<id>', guard(update));
    r.delete('/properties/<id>', guard(delete));
  }

  static Map<String, Object?> toJson(Row r) => {
        'id': r['id'],
        'title': r['title'],
        'address': r['address'],
        'price': r['price'],
        'type': r['type'],
        'rooms': r['rooms'],
        'area': r['area'],
        'rating': r['rating'],
        'agentName': r['agent_name'],
        'agentPhone': r['agent_phone'],
        'imageInitials': r['image_initials'],
        'imageUrl': r['image_url'],
        'createdAt': r['created_at'],
        'updatedAt': r['updated_at'],
      };

  static const _columns = 'title, address, price, type, rooms, area, rating, '
      'agent_name, agent_phone, image_initials, image_url';

  static (List<Object?>?, String?) _validate(Map<String, dynamic>? body) {
    if (body == null) return (null, 'Body must be a JSON object');
    final title = requiredString(body, 'title');
    if (title == null) return (null, 'title is required (non-empty string)');
    final address = optionalString(body, 'address');
    if (address == null) return (null, 'address must be a string');
    final price = optionalNum(body, 'price');
    if (price == null) return (null, 'price must be a number ≥ 0');
    final type = optionalString(body, 'type', fallback: 'Аренда');
    if (type == null) return (null, 'type must be a string');
    final rooms = optionalInt(body, 'rooms', fallback: 1);
    if (rooms == null) return (null, 'rooms must be an integer ≥ 0');
    final area = optionalNum(body, 'area');
    if (area == null) return (null, 'area must be a number ≥ 0');
    final rating = optionalNum(body, 'rating', max: 5);
    if (rating == null) return (null, 'rating must be a number 0..5');
    final agentName = optionalString(body, 'agentName');
    if (agentName == null) return (null, 'agentName must be a string');
    final agentPhone = optionalString(body, 'agentPhone');
    if (agentPhone == null) return (null, 'agentPhone must be a string');
    final initials = optionalString(body, 'imageInitials');
    if (initials == null) return (null, 'imageInitials must be a string');
    final imageUrl = body['imageUrl'];
    if (imageUrl != null && imageUrl is! String) {
      return (null, 'imageUrl must be a string or null');
    }
    return (
      [
        title, address, price, type, rooms, area, rating, //
        agentName, agentPhone, initials, imageUrl,
      ],
      null
    );
  }

  // GET /properties?page=&limit=&search= → 200 {items, page, limit, total}
  Response list(Request req) {
    final q = parsePageQuery(req);
    if (q == null) {
      return validationError('page ≥ 1 and 1 ≤ limit ≤ 100 are required');
    }
    var where = '(user_id IS NULL OR user_id = ?)';
    final args = <Object?>[userIdOf(req)];
    if (q.search != null) {
      // поиск — НА СЕРВЕРЕ: по названию, адресу, типу сделки, риелтору
      where += r" AND (ulower(title) LIKE ? ESCAPE '\' "
          r"OR ulower(address) LIKE ? ESCAPE '\' "
          r"OR ulower(type) LIKE ? ESCAPE '\' "
          r"OR ulower(agent_name) LIKE ? ESCAPE '\')";
      final p = likePattern(q.search!);
      args.addAll([p, p, p, p]);
    }
    final total = db
        .select('SELECT COUNT(*) AS c FROM properties WHERE $where', args)
        .first['c'];
    final rows = db.select(
      'SELECT * FROM properties WHERE $where ORDER BY id LIMIT ? OFFSET ?',
      [...args, q.limit, (q.page - 1) * q.limit],
    );
    return jsonResponse(200, {
      'items': rows.map(toJson).toList(),
      'page': q.page,
      'limit': q.limit,
      'total': total,
    });
  }

  // POST /properties → 201 (id даёт сервер) | 400
  Future<Response> create(Request req) async {
    final (values, error) = _validate(await readJsonObject(req));
    if (error != null) return validationError(error);
    final row = db.select(
      'INSERT INTO properties (user_id, $_columns) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING *',
      [userIdOf(req), ...values!],
    ).first;
    return jsonResponse(201, toJson(row));
  }

  // GET /properties/<id> → 200 | 404
  Response get(Request req) {
    final id = int.tryParse(req.params['id']!);
    final rows = db.select(
        'SELECT * FROM properties WHERE id = ? AND (user_id IS NULL OR user_id = ?)',
        [id, userIdOf(req)]);
    if (rows.isEmpty) return notFound('Property not found');
    return jsonResponse(200, toJson(rows.first));
  }

  // PUT /properties/<id> → 200 | 400 | 404
  Future<Response> update(Request req) async {
    final id = int.tryParse(req.params['id']!);
    final (values, error) = _validate(await readJsonObject(req));
    if (error != null) return validationError(error);
    final rows = db.select(
      'UPDATE properties SET title = ?, address = ?, price = ?, type = ?, '
      'rooms = ?, area = ?, rating = ?, agent_name = ?, agent_phone = ?, '
      'image_initials = ?, image_url = ?, '
      "updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now') "
      'WHERE id = ? AND (user_id IS NULL OR user_id = ?) RETURNING *',
      [...values!, id, userIdOf(req)],
    );
    if (rows.isEmpty) return notFound('Property not found');
    return jsonResponse(200, toJson(rows.first));
  }

  // DELETE /properties/<id> → 204 (пустое тело) | 404
  Response delete(Request req) {
    final id = int.tryParse(req.params['id']!);
    final rows = db.select(
        'DELETE FROM properties WHERE id = ? AND (user_id IS NULL OR user_id = ?) RETURNING id',
        [id, userIdOf(req)]);
    if (rows.isEmpty) return notFound('Property not found');
    return Response(204);
  }
}

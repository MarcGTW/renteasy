// lib/http_utils.dart — общие помощники: JSON-ответы, конверт ошибки,
// разбор тела и параметров пагинации. Одинаковы для всех CRUD-модулей.
import 'dart:convert';

import 'package:shelf/shelf.dart';

const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

/// Ответ с JSON-телом.
Response jsonResponse(int status, Object? body) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

/// Стандартизированный конверт ошибки контракта:
/// {"error": {"code": "...", "message": "..."}}
Response errorResponse(int status, String code, String message) =>
    jsonResponse(status, {
      'error': {'code': code, 'message': message},
    });

Response validationError(String message) =>
    errorResponse(400, 'VALIDATION_ERROR', message);

Response notFound([String message = 'Resource not found']) =>
    errorResponse(404, 'NOT_FOUND', message);

Response unauthorized([String message = 'Missing or invalid token']) =>
    errorResponse(401, 'UNAUTHORIZED', message);

/// Тело запроса как JSON-объект; null — тело вне контракта.
Future<Map<String, dynamic>?> readJsonObject(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    return data is Map<String, dynamic> ? data : null;
  } on FormatException {
    return null;
  }
}

/// id текущего пользователя, положенный auth-middleware в context.
int userIdOf(Request req) => req.context['userId'] as int;

typedef PageQuery = ({int page, int limit, String? search});

/// Разбор ?page=&limit=&search= ; null — недопустимые значения (→ 400).
PageQuery? parsePageQuery(Request req) {
  final q = req.url.queryParameters;
  final page = int.tryParse(q['page'] ?? '1');
  final limit = int.tryParse(q['limit'] ?? '20');
  if (page == null || limit == null || page < 1 || limit < 1 || limit > 100) {
    return null;
  }
  final search = q['search']?.trim();
  return (
    page: page,
    limit: limit,
    search: (search == null || search.isEmpty) ? null : search,
  );
}

/// Шаблон для LIKE: экранирует % и _, переводит в нижний регистр
/// (сравнение идёт через ulower(), который понимает и кириллицу).
String likePattern(String search) {
  final escaped = search
      .toLowerCase()
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return '%$escaped%';
}

/// Проверки полей тела: строка (обязательная / необязательная), число.
String? requiredString(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is! String || v.trim().isEmpty) return null;
  return v.trim();
}

/// Необязательная строка: отсутствует → fallback; не строка → null (ошибка).
String? optionalString(Map<String, dynamic> body, String key,
    {String fallback = ''}) {
  if (!body.containsKey(key) || body[key] == null) return fallback;
  final v = body[key];
  return v is String ? v.trim() : null;
}

/// Необязательное число ≥ min (JSON: 120 приходит как int, 120.5 — как double);
/// отсутствует → fallback; не число / вне диапазона → null (ошибка).
num? optionalNum(Map<String, dynamic> body, String key,
    {num fallback = 0, num min = 0, num? max}) {
  if (!body.containsKey(key) || body[key] == null) return fallback;
  final v = body[key];
  if (v is! num || v < min || (max != null && v > max)) return null;
  return v;
}

/// Необязательное целое ≥ min; отсутствует → fallback; иначе null (ошибка).
int? optionalInt(Map<String, dynamic> body, String key,
    {int fallback = 0, int min = 0}) {
  if (!body.containsKey(key) || body[key] == null) return fallback;
  final v = body[key];
  if (v is! num || v != v.roundToDouble() || v < min) return null;
  return v.toInt();
}

// conformance/bin/conformance.dart — набор тестов соответствия контракту.
// Бьёт по серверу через HTTP ровно так, как это делает приложение,
// и проверяет каждую букву базового контракта (auth, notes, пагинация,
// поиск, files, конверт ошибок, CORS).
//
//   cd server/conformance && dart pub get
//   dart run bin/conformance.dart --base-url http://localhost:8080
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

late String base;
var passed = 0;
var failed = 0;

void check(String name, bool ok, [String detail = '']) {
  if (ok) {
    passed++;
    stdout.writeln('  ✓ $name');
  } else {
    failed++;
    stdout.writeln('  ✗ $name${detail.isEmpty ? '' : '  — $detail'}');
  }
}

void section(String title) => stdout.writeln('\n$title');

Uri u(String path, [Map<String, String>? q]) =>
    Uri.parse('$base$path').replace(queryParameters: q);

Map<String, String> jsonH([String? token]) => {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

Map<String, String> authH(String token) => {'Authorization': 'Bearer $token'};

dynamic body(http.Response r) {
  try {
    return jsonDecode(utf8.decode(r.bodyBytes));
  } on FormatException {
    return null;
  }
}

/// Тело — конверт ошибки с ожидаемым кодом.
bool isError(http.Response r, int status, String code) {
  final b = body(r);
  return r.statusCode == status &&
      b is Map &&
      b['error'] is Map &&
      b['error']['code'] == code &&
      b['error']['message'] is String;
}

String got(http.Response r) =>
    'got ${r.statusCode} ${r.body.length > 160 ? '${r.body.substring(0, 160)}…' : r.body}';

Future<http.Response> register(String email, String password, String? name) =>
    http.post(u('/auth/register'),
        headers: jsonH(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': ?name,
        }));

Future<http.Response> upload(String? token, List<int> bytes,
    {String field = 'file', String filename = 'test.png'}) async {
  final req = http.MultipartRequest('POST', u('/files'));
  if (token != null) req.headers['Authorization'] = 'Bearer $token';
  req.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
  return http.Response.fromStream(await req.send());
}

Future<void> main(List<String> args) async {
  final i = args.indexOf('--base-url');
  base = (i >= 0 && i + 1 < args.length ? args[i + 1] : 'http://localhost:8080')
      .replaceAll(RegExp(r'/$'), '');
  stdout.writeln('Conformance suite → $base');

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final emailA = 'conf_a_$stamp@test.md';
  final emailB = 'conf_b_$stamp@test.md';
  const pass = 'parola123';

  try {
    // ---------------------------------------------------------------- health
    section('Health & errors');
    var r = await http.get(u('/health'));
    check('GET /health → 200', r.statusCode == 200, got(r));
    check('GET /health → {"status":"ok"}', body(r)?['status'] == 'ok', got(r));
    r = await http.get(u('/no-such-route-$stamp'));
    check('unknown route → 404 NOT_FOUND envelope',
        isError(r, 404, 'NOT_FOUND'), got(r));
    final pre = await http.Request('OPTIONS', u('/notes')).send();
    check(
        'CORS preflight → 204 + Access-Control-Allow-Origin',
        pre.statusCode == 204 &&
            pre.headers['access-control-allow-origin'] == '*',
        'got ${pre.statusCode} ${pre.headers}');

    // -------------------------------------------------------------- register
    section('Auth: register / login / me');
    r = await register(emailA, pass, 'Ana');
    final reg = body(r);
    check('register → 201', r.statusCode == 201, got(r));
    check(
        'register → {token, user{id,email,name}}',
        reg is Map &&
            reg['token'] is String &&
            reg['user'] is Map &&
            reg['user']['id'] is int &&
            reg['user']['email'] == emailA &&
            reg['user']['name'] == 'Ana',
        got(r));
    check('user JSON has no password fields',
        reg is Map && reg['user'] is Map &&
            !(reg['user'] as Map).keys.any((k) => '$k'.contains('pass')),
        got(r));
    final tokenA = (reg is Map ? reg['token'] : null) as String? ?? '';

    r = await register(emailA, pass, 'Ana');
    check('same email again → 409 EMAIL_TAKEN',
        isError(r, 409, 'EMAIL_TAKEN'), got(r));
    r = await register('nameless_$stamp@test.md', pass, null);
    check('register without name → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
    r = await register('not-an-email', pass, 'X');
    check('register with invalid email → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
    r = await register('short_$stamp@test.md', '123', 'X');
    check('register with short password → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
    r = await http.post(u('/auth/register'),
        headers: jsonH(), body: '<html>not json</html>');
    check('register with non-JSON body → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));

    r = await http.post(u('/auth/login'),
        headers: jsonH(), body: jsonEncode({'email': emailA, 'password': pass}));
    check('login → 200 {token, user}',
        r.statusCode == 200 && body(r)?['token'] is String, got(r));
    r = await http.post(u('/auth/login'),
        headers: jsonH(),
        body: jsonEncode({'email': emailA, 'password': 'wrong-pass'}));
    check('login with wrong password → 401 UNAUTHORIZED',
        isError(r, 401, 'UNAUTHORIZED'), got(r));
    r = await http.post(u('/auth/login'),
        headers: jsonH(),
        body: jsonEncode({'email': 'ghost_$stamp@test.md', 'password': pass}));
    check('login with unknown email → 401 UNAUTHORIZED',
        isError(r, 401, 'UNAUTHORIZED'), got(r));
    r = await http.get(u('/auth/me'), headers: authH(tokenA));
    check('GET /auth/me → 200 current user',
        r.statusCode == 200 && body(r)?['email'] == emailA, got(r));

    // ---------------------------------------------------------- auth guard
    section('Auth guard');
    r = await http.get(u('/notes'));
    check('GET /notes without token → 401 UNAUTHORIZED',
        isError(r, 401, 'UNAUTHORIZED'), got(r));
    r = await http.get(u('/notes'), headers: authH('garbage'));
    check('GET /notes with garbage token → 401',
        isError(r, 401, 'UNAUTHORIZED'), got(r));
    final tampered = '${tokenA.substring(0, tokenA.length - 3)}'
        '${tokenA.endsWith('AAA') ? 'BBB' : 'AAA'}';
    r = await http.get(u('/notes'), headers: authH(tampered));
    check('GET /notes with tampered signature → 401',
        isError(r, 401, 'UNAUTHORIZED'), got(r));

    // ------------------------------------------------------------ notes CRUD
    section('Notes CRUD');
    r = await http.get(u('/notes'), headers: authH(tokenA));
    final empty = body(r);
    check(
        'empty list → 200 {items:[], page:1, limit:20, total:0}',
        r.statusCode == 200 &&
            empty is Map &&
            empty['items'] is List &&
            (empty['items'] as List).isEmpty &&
            empty['page'] == 1 &&
            empty['limit'] == 20 &&
            empty['total'] == 0,
        got(r));

    r = await http.post(u('/notes'),
        headers: jsonH(tokenA),
        body: jsonEncode({'title': 'Покупки', 'content': 'молоко, хлеб'}));
    final note = body(r);
    check(
        'POST /notes → 201, id from server',
        r.statusCode == 201 &&
            note is Map &&
            note['id'] is int &&
            note['title'] == 'Покупки' &&
            note['content'] == 'молоко, хлеб',
        got(r));
    final noteId = (note is Map ? note['id'] : null) ?? -1;

    r = await http.post(u('/notes'),
        headers: jsonH(tokenA), body: jsonEncode({'content': 'no title'}));
    check('POST /notes without title → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
    r = await http.post(u('/notes'),
        headers: jsonH(tokenA), body: jsonEncode({'title': 42}));
    check('POST /notes with non-string title → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));

    r = await http.get(u('/notes/$noteId'), headers: authH(tokenA));
    check('GET /notes/{id} → 200',
        r.statusCode == 200 && body(r)?['id'] == noteId, got(r));
    r = await http.get(u('/notes/999999999'), headers: authH(tokenA));
    check('GET /notes/{missing} → 404 NOT_FOUND',
        isError(r, 404, 'NOT_FOUND'), got(r));

    r = await http.put(u('/notes/$noteId'),
        headers: jsonH(tokenA),
        body: jsonEncode({'title': 'Покупки (обновлено)', 'content': 'сыр'}));
    check('PUT /notes/{id} → 200 updated',
        r.statusCode == 200 && body(r)?['title'] == 'Покупки (обновлено)',
        got(r));
    r = await http.put(u('/notes/$noteId'),
        headers: jsonH(tokenA), body: jsonEncode({'title': ''}));
    check('PUT /notes/{id} invalid → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
    r = await http.put(u('/notes/999999999'),
        headers: jsonH(tokenA), body: jsonEncode({'title': 'x'}));
    check('PUT /notes/{missing} → 404 NOT_FOUND',
        isError(r, 404, 'NOT_FOUND'), got(r));

    r = await http.delete(u('/notes/$noteId'), headers: authH(tokenA));
    check('DELETE /notes/{id} → 204, empty body',
        r.statusCode == 204 && r.bodyBytes.isEmpty, got(r));
    r = await http.delete(u('/notes/$noteId'), headers: authH(tokenA));
    check('DELETE /notes/{id} again → 404 NOT_FOUND',
        isError(r, 404, 'NOT_FOUND'), got(r));

    // ---------------------------------------------------- pagination/search
    section('Pagination & search');
    for (var n = 1; n <= 25; n++) {
      await http.post(u('/notes'),
          headers: jsonH(tokenA),
          body: jsonEncode({
            'title': n <= 3 ? 'Ремонт кухни $n' : 'Note $n',
            'content': 'item $n',
          }));
    }
    r = await http.get(u('/notes', {'page': '2', 'limit': '10'}),
        headers: authH(tokenA));
    var b = body(r);
    check(
        '?page=2&limit=10 → 10 items, page 2, limit 10, total 25',
        r.statusCode == 200 &&
            (b['items'] as List).length == 10 &&
            b['page'] == 2 &&
            b['limit'] == 10 &&
            b['total'] == 25,
        got(r));
    r = await http.get(u('/notes', {'page': '3', 'limit': '10'}),
        headers: authH(tokenA));
    b = body(r);
    check('?page=3&limit=10 → last 5 items',
        r.statusCode == 200 && (b['items'] as List).length == 5, got(r));
    r = await http.get(u('/notes', {'page': '0'}), headers: authH(tokenA));
    check('?page=0 → 400 VALIDATION_ERROR',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
    r = await http.get(u('/notes', {'search': 'ремонт'}),
        headers: authH(tokenA));
    b = body(r);
    check(
        '?search=ремонт (Cyrillic, case-insensitive) → 3 items, total 3',
        r.statusCode == 200 &&
            (b['items'] as List).length == 3 &&
            b['total'] == 3,
        got(r));

    // ------------------------------------------------------------ ownership
    section('Ownership (per-user data)');
    r = await register(emailB, pass, 'Bob');
    final tokenB = body(r)?['token'] as String? ?? '';
    final anyA = (await http.get(u('/notes', {'limit': '1'}),
            headers: authH(tokenA)))
        .body;
    final foreignId = (jsonDecode(anyA)['items'] as List).first['id'];
    r = await http.get(u('/notes/$foreignId'), headers: authH(tokenB));
    check('another user\'s note → 404 (not 403)',
        isError(r, 404, 'NOT_FOUND'), got(r));
    r = await http.get(u('/notes'), headers: authH(tokenB));
    check('another user\'s list is empty (total 0)',
        r.statusCode == 200 && body(r)?['total'] == 0, got(r));

    // ----------------------------------------------------------------- files
    section('Files');
    final png = base64.decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    r = await upload(tokenA, png);
    final file = body(r);
    check(
        'POST /files (multipart) → 201 {id, url:"/files/{id}"}',
        r.statusCode == 201 &&
            file is Map &&
            file['id'] is int &&
            file['url'] == '/files/${file['id']}',
        got(r));
    final fileUrl = (file is Map ? file['url'] : null) ?? '/files/0';
    r = await http.get(u(fileUrl));
    check('GET /files/{id} → 200, same bytes',
        r.statusCode == 200 && _same(r.bodyBytes, png), got(r));
    check(
        'download has Content-Disposition: attachment + CSP',
        (r.headers['content-disposition'] ?? '').startsWith('attachment') &&
            (r.headers['content-security-policy'] ?? '').isNotEmpty,
        '${r.headers}');
    r = await upload(null, png);
    check('POST /files without token → 401',
        isError(r, 401, 'UNAUTHORIZED'), got(r));
    r = await upload(tokenA, png, field: 'document');
    check('POST /files without "file" field → 400',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
    r = await upload(tokenA, List<int>.filled(5 * 1024 * 1024 + 1, 7),
        filename: 'big.bin');
    check('POST /files over 5 MB → 400',
        isError(r, 400, 'VALIDATION_ERROR'), got(r));
  } on SocketException catch (e) {
    check('server reachable at $base', false, '$e');
  } on http.ClientException catch (e) {
    check('server reachable at $base', false, '$e');
  }

  final total = passed + failed;
  stdout.writeln(failed == 0
      ? '\nPASS — $passed/$total checks passed'
      : '\nFAIL — $passed/$total checks passed, $failed failed');
  exit(failed == 0 ? 0 : 1);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

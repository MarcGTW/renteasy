// lib/auth.dart — регистрация, вход, JWT и auth-middleware.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import 'http_utils.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthModule {
  AuthModule(this.db, this.secret);

  final Database db;
  final String secret; // env JWT_SECRET; по умолчанию — лабораторный
  static const tokenTtl = Duration(days: 7);

  // POST /auth/register {email, password, name} → 201 {token, user}
  Future<Response> register(Request req) async {
    final body = await readJsonObject(req);
    if (body == null) return validationError('Body must be a JSON object');
    final email = requiredString(body, 'email')?.toLowerCase();
    final password = body['password'];
    final name = requiredString(body, 'name');
    if (email == null || !_emailRe.hasMatch(email)) {
      return validationError('A valid email is required');
    }
    if (password is! String || password.length < 6) {
      return validationError('Password must be at least 6 characters');
    }
    if (name == null) return validationError('Name is required');

    final exists = db.select('SELECT 1 FROM users WHERE email = ?', [email]);
    if (exists.isNotEmpty) {
      return errorResponse(409, 'EMAIL_TAKEN', 'Email is already registered');
    }
    final row = db.select(
      'INSERT INTO users (email, password_hash, name) VALUES (?, ?, ?) '
      'RETURNING *',
      [email, hashPassword(password), name],
    ).first;
    return jsonResponse(201, {
      'token': issueToken(row['id'] as int),
      'user': userJson(row),
    });
  }

  // POST /auth/login {email, password} → 200 {token, user}
  Future<Response> login(Request req) async {
    final body = await readJsonObject(req);
    if (body == null) return validationError('Body must be a JSON object');
    final email = requiredString(body, 'email')?.toLowerCase();
    final password = body['password'];
    if (email == null || password is! String) {
      return validationError('Email and password are required');
    }
    final rows = db.select('SELECT * FROM users WHERE email = ?', [email]);
    // Одинаковый ответ для «нет такого email» и «неверный пароль».
    if (rows.isEmpty ||
        !verifyPassword(password, rows.first['password_hash'] as String)) {
      return unauthorized('Invalid email or password');
    }
    final row = rows.first;
    return jsonResponse(200, {
      'token': issueToken(row['id'] as int),
      'user': userJson(row),
    });
  }

  // GET /auth/me → 200 user (под auth-middleware)
  Response me(Request req) {
    final rows =
        db.select('SELECT * FROM users WHERE id = ?', [userIdOf(req)]);
    return jsonResponse(200, userJson(rows.first));
  }

  static Map<String, Object?> userJson(Row r) => {
        'id': r['id'],
        'email': r['email'],
        'name': r['name'],
        'createdAt': r['created_at'],
      }; // password_hash наружу не уходит никогда

  String issueToken(int userId) => JWT({'uid': userId}, subject: '$userId')
      .sign(SecretKey(secret), expiresIn: tokenTtl);

  /// id пользователя из token-а; null — подпись/срок не прошли.
  int? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      final uid = (jwt.payload as Map)['uid'];
      return uid is int ? uid : null;
    } on JWTException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Middleware: без валидного `Authorization: Bearer <jwt>` — 401.
  Handler guard(Handler inner) => (Request req) {
        final header = req.headers['authorization'] ?? '';
        if (!header.startsWith('Bearer ')) return unauthorized();
        final uid = verifyToken(header.substring(7).trim());
        if (uid == null) return unauthorized();
        final user = db.select('SELECT 1 FROM users WHERE id = ?', [uid]);
        if (user.isEmpty) return unauthorized();
        return inner(req.change(context: {'userId': uid}));
      };
}

// ---- пароли: PBKDF2-HMAC-SHA256 с солью; в базе только хеш ----

const _iterations = 10000;

String hashPassword(String password) {
  final rnd = Random.secure();
  final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
  final hash = _pbkdf2(utf8.encode(password), salt, _iterations, 32);
  return 'pbkdf2\$$_iterations\$${base64.encode(salt)}\$${base64.encode(hash)}';
}

bool verifyPassword(String password, String stored) {
  final parts = stored.split(r'$');
  if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
  final iterations = int.parse(parts[1]);
  final salt = base64.decode(parts[2]);
  final expected = base64.decode(parts[3]);
  final actual =
      _pbkdf2(utf8.encode(password), salt, iterations, expected.length);
  var diff = 0; // сравнение за постоянное время
  for (var i = 0; i < expected.length; i++) {
    diff |= expected[i] ^ actual[i];
  }
  return diff == 0;
}

List<int> _pbkdf2(List<int> password, List<int> salt, int iterations, int len) {
  final hmac = Hmac(sha256, password);
  final out = <int>[];
  for (var block = 1; out.length < len; block++) {
    var u = hmac.convert([
      ...salt,
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ]).bytes;
    final t = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.addAll(t);
  }
  return out.sublist(0, len);
}

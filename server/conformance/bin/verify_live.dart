// conformance/bin/verify_live.dart — сквозная проверка живого сервера RentEasy.
// Запуск при работающем сервере: dart run bin/verify_live.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void assertTrue(bool cond, String msg) {
  if (!cond) {
    stderr.writeln('FAIL: $msg');
    exit(1);
  }
  stdout.writeln('  ✓ $msg');
}

Future<void> main() async {
  const base = 'http://localhost:8080';
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'live_$stamp@test.md';
  const jsonH = {'Content-Type': 'application/json'};

  // 1. Register + 409 + Login + 401
  var res = await http.post(Uri.parse('$base/auth/register'),
      headers: jsonH,
      body: jsonEncode({'email': email, 'password': 'parola123', 'name': 'Live'}));
  assertTrue(res.statusCode == 201, 'POST /auth/register → 201');
  final token = (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;

  res = await http.post(Uri.parse('$base/auth/register'),
      headers: jsonH,
      body: jsonEncode({'email': email, 'password': 'parola123', 'name': 'Live'}));
  assertTrue(res.statusCode == 409 && jsonDecode(res.body)['error']['code'] == 'EMAIL_TAKEN',
      'duplicate register → 409 EMAIL_TAKEN');

  res = await http.post(Uri.parse('$base/auth/login'),
      headers: jsonH,
      body: jsonEncode({'email': email, 'password': 'wrong'}));
  assertTrue(res.statusCode == 401 && jsonDecode(res.body)['error']['code'] == 'UNAUTHORIZED',
      'wrong password → 401 UNAUTHORIZED');

  final authH = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

  // 2. Pagination (>20 starter properties) + Cyrillic search
  res = await http.get(Uri.parse('$base/properties?page=1&limit=20'), headers: authH);
  final page1 = jsonDecode(res.body) as Map<String, dynamic>;
  assertTrue(res.statusCode == 200 && (page1['items'] as List).length == 20,
      'GET /properties?page=1&limit=20 → 20 items (total=${page1['total']})');

  res = await http.get(Uri.parse('$base/properties?page=2&limit=20'), headers: authH);
  final page2 = jsonDecode(res.body) as Map<String, dynamic>;
  assertTrue(res.statusCode == 200 && (page2['items'] as List).isNotEmpty,
      'GET /properties?page=2&limit=20 → ${(page2['items'] as List).length} items');

  res = await http.get(
      Uri.parse('$base/properties').replace(queryParameters: {'search': 'Ботаника'}),
      headers: authH);
  final searchRes = jsonDecode(res.body) as Map<String, dynamic>;
  assertTrue(res.statusCode == 200 && (searchRes['items'] as List).isNotEmpty,
      'GET /properties?search=Ботаника → ${(searchRes['items'] as List).length} items');

  // 3. Property & Booking CRUD (201, 200, 204, 404)
  res = await http.post(Uri.parse('$base/properties'),
      headers: authH,
      body: jsonEncode({
        'title': 'Тестовая квартира',
        'address': 'г. Кишинёв, ул. Тестовая 1',
        'price': 450,
        'type': 'Аренда',
        'rooms': 2,
        'area': 50,
        'rating': 4.8,
        'agentName': 'Алена Русу',
        'agentPhone': '+373 69 112233',
        'imageInitials': 'Т2',
      }));
  assertTrue(res.statusCode == 201, 'POST /properties → 201');
  final propId = jsonDecode(res.body)['id'];

  res = await http.get(Uri.parse('$base/properties/9999999'), headers: authH);
  assertTrue(res.statusCode == 404 && jsonDecode(res.body)['error']['code'] == 'NOT_FOUND',
      'GET /properties/9999999 → 404 NOT_FOUND');

  res = await http.delete(Uri.parse('$base/properties/$propId'), headers: authH);
  assertTrue(res.statusCode == 204 && res.bodyBytes.isEmpty, 'DELETE /properties/$propId → 204');

  res = await http.post(Uri.parse('$base/bookings'),
      headers: authH,
      body: jsonEncode({
        'propertyTitle': '2-комнатная новостройка в Центре',
        'name': 'Live',
        'phone': '37369123456',
        'date': '15.12.2026',
        'time': '15:00',
        'status': 'Ожидает',
      }));
  assertTrue(res.statusCode == 201, 'POST /bookings → 201');
  final bookingId = jsonDecode(res.body)['id'];

  res = await http.delete(Uri.parse('$base/bookings/$bookingId'), headers: authH);
  assertTrue(res.statusCode == 204 && res.bodyBytes.isEmpty, 'DELETE /bookings/$bookingId → 204');

  // 4. Tampered token → 401
  res = await http.get(Uri.parse('$base/properties'),
      headers: {'Authorization': 'Bearer invalid.jwt.token'});
  assertTrue(res.statusCode == 401, 'invalid token → 401 UNAUTHORIZED');

  stdout.writeln('\nLIVE E2E VERIFICATION PASSED');
}

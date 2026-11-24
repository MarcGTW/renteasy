import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rent_easy/data/api_message.dart';
import 'package:rent_easy/data/auth_api.dart';
import 'package:rent_easy/data/http_booking_repository.dart';
import 'package:rent_easy/data/http_property_repository.dart';
import 'package:rent_easy/data/result.dart';
import 'package:rent_easy/data/token_store.dart';
import 'package:rent_easy/models/booking.dart';
import 'package:rent_easy/models/property.dart';
import 'package:rent_easy/models/property_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('apiMessage', () {
    test('translates known contract error codes to Russian', () {
      http.Response errRes(int status, String code) => http.Response(
        jsonEncode({
          'error': {'code': code, 'message': 'English message'},
        }),
        status,
      );

      expect(
        apiMessage(errRes(400, 'VALIDATION_ERROR')),
        'Отправленные данные недействительны',
      );
      expect(
        apiMessage(errRes(401, 'UNAUTHORIZED')),
        'Неверный email или пароль',
      );
      expect(
        apiMessage(errRes(409, 'EMAIL_TAKEN')),
        'Аккаунт с этим email уже существует',
      );
      expect(
        apiMessage(errRes(404, 'NOT_FOUND')),
        'Запись не существует',
      );
      expect(
        apiMessage(errRes(429, 'RATE_LIMITED')),
        'Ошибка сервера (RATE_LIMITED)',
      );
    });

    test('handles HTML / non-JSON 500 responses gracefully', () {
      final htmlRes = http.Response('<html>500 Error</html>', 500);
      expect(apiMessage(htmlRes), 'Ошибка сервера (500)');

      final badShape = http.Response(jsonEncode({'oops': true}), 400);
      expect(apiMessage(badShape), 'Ошибка сервера (400)');
    });
  });

  group('JSON serialization', () {
    test('Property.fromJson handles int price and toJson omits id', () {
      final p = Property.fromJson({
        'id': 42,
        'title': 'Лофт',
        'address': 'Центр',
        'price': 120, // приходит как int из JSON
        'type': 'Аренда',
        'rooms': 2,
        'area': 55,
        'rating': 5,
        'agentName': 'Алена',
        'agentPhone': '+37369112233',
        'imageInitials': 'Л2',
      });

      expect(p.id, '42');
      expect(p.price, 120.0);
      expect(p.area, 55.0);
      expect(p.rating, 5.0);

      final json = p.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['title'], 'Лофт');
      expect(json['price'], 120.0);
    });

    test('Booking.fromJson parses id and toJson omits id', () {
      final b = Booking.fromJson({
        'id': 7,
        'propertyTitle': 'Студия',
        'name': 'Ana',
        'phone': '37369123456',
        'date': '10.12.2026',
        'time': '14:00',
        'status': 'Ожидает',
      });

      expect(b.id, '7');
      expect(b.propertyTitle, 'Студия');
      final json = b.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['status'], 'Ожидает');
    });
  });

  group('AuthApi & TokenStore', () {
    test('register saves token and login error translates 401', () async {
      final store = TokenStore();
      final auth = AuthApi('http://api.test', store);

      final client = MockClient((req) async {
        if (req.url.path == '/auth/register') {
          return http.Response(
            jsonEncode({'token': 'jwt-123', 'user': {'id': 1}}),
            201,
          );
        }
        return http.Response(
          jsonEncode({
            'error': {'code': 'UNAUTHORIZED', 'message': 'Invalid'},
          }),
          401,
        );
      });

      await http.runWithClient(() async {
        final regResult = await auth.register('a@test.md', '123456', 'Ana');
        expect(regResult, isA<Ok<void>>());
        expect(await store.read(), 'jwt-123');

        final badLogin = await auth.login('a@test.md', 'wrong');
        expect(badLogin, isA<Err<void>>());
        expect((badLogin as Err<void>).msg, 'Неверный email или пароль');

        await auth.logout();
        expect(await store.read(), isNull);
      }, () => client);
    });
  });

  group('HttpPropertyRepository & HttpBookingRepository', () {
    test('fetchAll passes page/limit/search and handles 204 & 401', () async {
      final store = TokenStore();
      await store.save('valid-jwt');
      var unauthorizedCalled = false;

      final repo = HttpPropertyRepository(
        'http://api.test',
        store,
        onUnauthorized: () => unauthorizedCalled = true,
      );
      final bookingRepo = HttpBookingRepository(
        'http://api.test',
        store,
        onUnauthorized: () => unauthorizedCalled = true,
      );

      final client = MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer valid-jwt');

        if (req.method == 'GET' && req.url.path == '/properties') {
          expect(req.url.queryParameters['page'], '2');
          expect(req.url.queryParameters['limit'], '20');
          expect(req.url.queryParameters['search'], 'Ботаника');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'items': [
                  {'id': 11, 'title': 'Квартира на Ботанике', 'price': 500},
                ],
                'page': 2,
                'limit': 20,
                'total': 21,
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (req.method == 'DELETE' && req.url.path == '/bookings/5') {
          return http.Response('', 204);
        }

        if (req.method == 'GET' && req.url.path == '/properties/99') {
          return http.Response('', 401);
        }

        return http.Response('Not found', 404);
      });

      await http.runWithClient(() async {
        final listRes = await repo.fetchAll(
          page: 2,
          limit: 20,
          search: 'Ботаника',
        );
        expect(listRes, isA<Ok<List<Property>>>());
        expect((listRes as Ok<List<Property>>).value.first.id, '11');

        final delRes = await bookingRepo.delete('5');
        expect(delRes, isA<Ok<void>>());

        final unauthRes = await repo.fetchById('99');
        expect(unauthRes, isA<Err<Property>>());
        expect(
          (unauthRes as Err<Property>).msg,
          'Сессия истекла — войдите снова',
        );
        expect(unauthorizedCalled, isTrue);
        expect(await store.read(), isNull);
      }, () => client);
    });

    test('maps SocketException, TimeoutException and FormatException', () async {
      final store = TokenStore();
      final repo = HttpPropertyRepository('http://api.test', store);

      await http.runWithClient(() async {
        final r = await repo.fetchAll();
        expect((r as Err<List<Property>>).msg, 'Нет сети — повторите попытку');
      }, () => MockClient((_) => throw const SocketException('offline')));

      await http.runWithClient(() async {
        final r = await repo.fetchAll();
        expect((r as Err<List<Property>>).msg, 'Сервер не отвечает');
      }, () => MockClient((_) => throw TimeoutException('timeout')));

      await http.runWithClient(() async {
        final r = await repo.fetchAll();
        expect((r as Err<List<Property>>).msg, 'Ответ не тот, что обещан');
      }, () => MockClient((_) async => http.Response('<html>oops</html>', 200)));
    });

    test('PropertyModel loads pages, appends loadMore and keeps search', () async {
      final store = TokenStore();
      final repo = HttpPropertyRepository('http://api.test', store);
      final model = PropertyModel(repo);

      final client = MockClient((req) async {
        final page = int.parse(req.url.queryParameters['page'] ?? '1');
        final search = req.url.queryParameters['search'];
        final items = page == 1
            ? List.generate(
                20,
                (i) => {'id': i + 1, 'title': '${search ?? 'Объект'} ${i + 1}'},
              )
            : List.generate(5, (i) => {'id': 21 + i, 'title': 'Объект ${21 + i}'});
        return http.Response.bytes(
          utf8.encode(jsonEncode({'items': items, 'page': page, 'limit': 20})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      await http.runWithClient(() async {
        await model.load(search: 'Центр');
        expect(model.properties.length, 20);
        expect(model.hasMore, isTrue);
        expect(model.search, 'Центр');

        await model.loadMore();
        expect(model.properties.length, 25);
        expect(model.hasMore, isFalse);
      }, () => client);
    });
  });
}

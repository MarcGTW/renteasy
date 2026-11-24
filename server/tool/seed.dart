// tool/seed.dart — наполняет базу объектами недвижимости через API
// (для демонстрации пагинации: > 20 записей). Пользователь создаётся,
// если ещё не зарегистрирован.
//
//   dart run tool/seed.dart --email ana@test.md --password parola123 --count 30
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

String arg(List<String> args, String name, String fallback) {
  final i = args.indexOf('--$name');
  return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
}

const _districts = [
  ('Центр', 'ул. Штефан чел Маре', 'Ц'),
  ('Ботаника', 'бульвар Дачия', 'Б'),
  ('Рышкановка', 'Московский проспект', 'Р'),
  ('Буюканы', 'ул. Альба-Юлия', 'Бу'),
  ('Чеканы', 'ул. Мирча чел Бэтрын', 'Ч'),
  ('Телецентр', 'ул. Пушкина', 'Т'),
];
const _agents = [
  ('Алена Русу', '+373 69 112233'),
  ('Максим Гросу', '+373 79 445566'),
  ('Ирина Чебан', '+373 68 778899'),
  ('Дмитрий Урсу', '+373 60 223344'),
];

Future<void> main(List<String> args) async {
  final base = arg(args, 'base-url', 'http://localhost:8080');
  final email = arg(args, 'email', 'ana@test.md');
  final password = arg(args, 'password', 'parola123');
  final count = int.parse(arg(args, 'count', '30'));
  const json = {'Content-Type': 'application/json'};

  var res = await http.post(Uri.parse('$base/auth/login'),
      headers: json, body: jsonEncode({'email': email, 'password': password}));
  if (res.statusCode == 401) {
    res = await http.post(Uri.parse('$base/auth/register'),
        headers: json,
        body: jsonEncode({'email': email, 'password': password, 'name': 'Ana'}));
  }
  if (res.statusCode != 200 && res.statusCode != 201) {
    stderr.writeln('auth failed: ${res.statusCode} ${res.body}');
    exit(1);
  }
  final token = (jsonDecode(res.body) as Map<String, dynamic>)['token'];

  for (var i = 1; i <= count; i++) {
    final d = _districts[i % _districts.length];
    final a = _agents[i % _agents.length];
    final rooms = 1 + i % 4;
    final rent = i.isEven;
    final body = {
      'title': '$rooms-комнатная квартира, ${d.$1} №$i',
      'address': 'г. Кишинёв, ${d.$2} ${10 + i}',
      'price': rent ? 300 + rooms * 90 + i * 5 : 45000 + rooms * 15000 + i * 700,
      'type': rent ? 'Аренда' : 'Продажа',
      'rooms': rooms,
      'area': 30 + rooms * 18 + i % 7,
      'rating': 4 + (i % 10) / 10,
      'agentName': a.$1,
      'agentPhone': a.$2,
      'imageInitials': '${d.$3}$rooms',
    };
    final r = await http.post(Uri.parse('$base/properties'),
        headers: {...json, 'Authorization': 'Bearer $token'},
        body: jsonEncode(body));
    stdout.writeln('${r.statusCode} ${body['title']}');
  }
  stdout.writeln('Done: $count properties for $email');
}

// lib/db.dart — SQLite: схема применяется при каждом запуске.
// CREATE TABLE IF NOT EXISTS: НОВАЯ таблица появится при следующем запуске,
// уже созданная — НЕ изменится. Поменяли колонки — удалите app.db.
import 'package:sqlite3/sqlite3.dart';

const schema = '''
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  email         TEXT    NOT NULL UNIQUE,
  password_hash TEXT    NOT NULL,
  name          TEXT    NOT NULL,
  created_at    TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT    NOT NULL,
  content    TEXT    NOT NULL DEFAULT '',
  created_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS files (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  filename   TEXT    NOT NULL,
  mime_type  TEXT    NOT NULL,
  size       INTEGER NOT NULL,
  data       BLOB    NOT NULL,
  created_at TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

-- Сущность темы RentEasy: объект недвижимости (каталог + личные объявления).
-- user_id NULL для стартового каталога (виден любому вошедшему пользователю).
CREATE TABLE IF NOT EXISTS properties (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id        INTEGER REFERENCES users(id) ON DELETE SET NULL,
  title          TEXT    NOT NULL,
  address        TEXT    NOT NULL DEFAULT '',
  price          REAL    NOT NULL DEFAULT 0,
  type           TEXT    NOT NULL DEFAULT 'Аренда',
  rooms          INTEGER NOT NULL DEFAULT 1,
  area           REAL    NOT NULL DEFAULT 0,
  rating         REAL    NOT NULL DEFAULT 0,
  agent_name     TEXT    NOT NULL DEFAULT '',
  agent_phone    TEXT    NOT NULL DEFAULT '',
  image_initials TEXT    NOT NULL DEFAULT '',
  image_url      TEXT,
  created_at     TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

-- Вторая пишущая сущность темы: заявка на просмотр. Связь с объектом —
-- просто дополнительная колонка REFERENCES (необязательная).
CREATE TABLE IF NOT EXISTS bookings (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id        INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  property_id    INTEGER REFERENCES properties(id) ON DELETE SET NULL,
  property_title TEXT    NOT NULL,
  name           TEXT    NOT NULL,
  phone          TEXT    NOT NULL,
  date           TEXT    NOT NULL DEFAULT '',
  time           TEXT    NOT NULL DEFAULT '',
  status         TEXT    NOT NULL DEFAULT 'Ожидает',
  created_at     TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
''';

Database openDatabase(String path) {
  final db = sqlite3.open(path);
  db.execute('PRAGMA foreign_keys = ON;');
  db.execute(schema);
  // Встроенные lower()/LIKE в SQLite понимают только ASCII —
  // ulower() даёт регистронезависимый поиск и по кириллице.
  db.createFunction(
    functionName: 'ulower',
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    function: (args) => (args[0] as String?)?.toLowerCase(),
  );
  _seedPropertiesIfEmpty(db);
  return db;
}

void _seedPropertiesIfEmpty(Database db) {
  final count = db.select('SELECT COUNT(*) AS c FROM properties').first['c'] as int;
  if (count > 0) return;

  const starter = [
    ('2-комнатная новостройка в Центре', 'г. Кишинёв, ул. Лев Толстой 24', 550.0, 'Аренда', 2, 65.0, 4.9, 'Алена Русу', '+373 69 112233', 'К2'),
    ('Пентхаус с видом на парк', 'г. Кишинёв, ул. Мирон Костин 12', 120000.0, 'Продажа', 3, 110.0, 5.0, 'Максим Гросу', '+373 79 445566', 'П3'),
    ('Уютная студия на Рышкановке', 'г. Кишинёв, Московский проспект 8', 350.0, 'Аренда', 1, 38.0, 4.7, 'Ирина Чебан', '+373 68 778899', 'С1'),
    ('3-комнатная квартира на Ботанике', 'г. Кишинёв, бульвар Дачия 20', 85000.0, 'Продажа', 3, 82.0, 4.8, 'Дмитрий Урсу', '+373 60 223344', 'К3'),
    ('Современные апартаменты Буюканы', 'г. Кишинёв, ул. Альба-Юлия 75', 480.0, 'Аренда', 2, 58.0, 4.6, 'Алена Русу', '+373 69 112233', 'А2'),
    ('Таунхаус с террасой Чеканы', 'г. Кишинёв, ул. Мирча чел Бэтрын 32', 145000.0, 'Продажа', 4, 140.0, 4.9, 'Максим Гросу', '+373 79 445566', 'Т4'),
    ('Светлая 1-комнатная в Центре', 'г. Кишинёв, ул. Пушкина 44', 420.0, 'Аренда', 1, 42.0, 4.8, 'Ирина Чебан', '+373 68 778899', 'Ц1'),
    ('2-комнатная у Долины Роз, Ботаника', 'г. Кишинёв, ул. Трандафирилор 15', 62000.0, 'Продажа', 2, 61.0, 4.7, 'Дмитрий Урсу', '+373 60 223344', 'Б2'),
    ('Дизайнерский лофт в Центре', 'г. Кишинёв, ул. Вероника Микле 7', 720.0, 'Аренда', 2, 74.0, 5.0, 'Алена Русу', '+373 69 112233', 'Л2'),
    ('Просторная квартира на Телецентре', 'г. Кишинёв, Хынчештское шоссе 58', 78000.0, 'Продажа', 3, 79.0, 4.6, 'Максим Гросу', '+373 79 445566', 'Т3'),
    ('Квартира-студия на Ботанике', 'г. Кишинёв, ул. Индепенденцей 18', 370.0, 'Аренда', 1, 36.0, 4.5, 'Ирина Чебан', '+373 68 778899', 'Б1'),
    ('Семейная 3-комнатная на Рышкановке', 'г. Кишинёв, ул. Киевская 9', 92000.0, 'Продажа', 3, 88.0, 4.8, 'Дмитрий Урсу', '+373 60 223344', 'Р3'),
    ('Апартаменты у парка Валя Морилор', 'г. Кишинёв, ул. Алексей Матеевич 87', 650.0, 'Аренда', 2, 68.0, 4.9, 'Алена Русу', '+373 69 112233', 'Ц2'),
    ('2-комнатная новостройка на Чеканах', 'г. Кишинёв, ул. Игорь Виеру 14', 59500.0, 'Продажа', 2, 60.0, 4.7, 'Максим Гросу', '+373 79 445566', 'Ч2'),
    ('Уютная 2-комнатная на Буюканах', 'г. Кишинёв, ул. Ион Крянгэ 39', 460.0, 'Аренда', 2, 54.0, 4.6, 'Ирина Чебан', '+373 68 778899', 'Бу2'),
    ('Дуплекс с панорамным видом, Телецентр', 'г. Кишинёв, ул. Друмул Виилор 28', 132000.0, 'Продажа', 4, 122.0, 4.9, 'Дмитрий Урсу', '+373 60 223344', 'Т4'),
    ('1-комнатная рядом с Штефан чел Маре', 'г. Кишинёв, бул. Штефан чел Маре 134', 490.0, 'Аренда', 1, 44.0, 4.8, 'Алена Русу', '+373 69 112233', 'Ц1'),
    ('3-комнатная в новом комплексе Буюканы', 'г. Кишинёв, ул. Николае Костин 52', 95000.0, 'Продажа', 3, 91.0, 4.8, 'Максим Гросу', '+373 79 445566', 'Бу3'),
    ('Студия с ремонтом на Чеканах', 'г. Кишинёв, ул. Петру Заднипру 6', 330.0, 'Аренда', 1, 35.0, 4.5, 'Ирина Чебан', '+373 68 778899', 'Ч1'),
    ('4-комнатная квартира на Ботанике', 'г. Кишинёв, ул. Дечебал 72', 112000.0, 'Продажа', 4, 105.0, 4.9, 'Дмитрий Урсу', '+373 60 223344', 'Б4'),
    ('2-комнатная у озера на Рышкановке', 'г. Кишинёв, ул. Богдан Воевод 4', 510.0, 'Аренда', 2, 62.0, 4.7, 'Алена Русу', '+373 69 112233', 'Р2'),
    ('Квартира с террасой в Центре', 'г. Кишинёв, ул. Букурешть 63', 128000.0, 'Продажа', 3, 96.0, 5.0, 'Максим Гросу', '+373 79 445566', 'Ц3'),
    ('1-комнатная на Телецентре', 'г. Кишинёв, ул. Миорица 11', 340.0, 'Аренда', 1, 37.0, 4.6, 'Ирина Чебан', '+373 68 778899', 'Т1'),
    ('2-комнатная возле парка Алунелул', 'г. Кишинёв, ул. Каля Ешилор 21', 64000.0, 'Продажа', 2, 63.0, 4.7, 'Дмитрий Урсу', '+373 60 223344', 'Бу2'),
    ('3-комнатная бизнес-класса, Центр', 'г. Кишинёв, ул. Колумна 102', 850.0, 'Аренда', 3, 94.0, 4.9, 'Алена Русу', '+373 69 112233', 'Ц3'),
  ];

  final stmt = db.prepare(
    'INSERT INTO properties (user_id, title, address, price, type, rooms, '
    'area, rating, agent_name, agent_phone, image_initials) '
    'VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
  );
  try {
    for (final p in starter) {
      stmt.execute([
        p.$1, p.$2, p.$3, p.$4, p.$5, p.$6, p.$7, p.$8, p.$9, p.$10,
      ]);
    }
  } finally {
    stmt.close();
  }
}

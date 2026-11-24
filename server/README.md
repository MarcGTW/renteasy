# RentEasy backend (порт на Dart)

Backend лабораторной L5. Контракт шаблона курса (05_Backend): auth с JWT,
CRUD на сущности-примере Note, пагинация, поиск, upload, стандартизированные
ошибки, SQLite, ноль настройки. Язык порта — **Dart** (shelf + sqlite3).

## Запуск

```bash
cd server && dart run          # слушает на порту 8080 (env PORT); app.db создаётся сам
```

Переменные окружения (все необязательные):

| Переменная   | По умолчанию            | Назначение                                    |
|--------------|-------------------------|-----------------------------------------------|
| `PORT`       | `8080`                  | порт                                          |
| `HOST`       | `127.0.0.1`             | `0.0.0.0` — если приложение на физическом телефоне |
| `JWT_SECRET` | `dev-secret-change-me`  | секрет подписи JWT (лабораторный по умолчанию) |
| `DB_PATH`    | `app.db`                | файл SQLite                                   |

PowerShell: `$env:JWT_SECRET='alt-secret'; dart run` — перезапуск с другим секретом
(проверка потока 401). Bash: `JWT_SECRET=alt-secret dart run`.

Проверка: `http://localhost:8080/health` → `{"status":"ok"}`.

## Набор тестов соответствия

```bash
cd server/conformance && dart pub get
dart run bin/conformance.dart --base-url http://localhost:8080
# → список проверок с ✓ и итог: PASS — N/N checks passed
```

## Контракт

Любая ошибка — одно и то же тело: `{"error":{"code":"...","message":"..."}}`.
Коды: `VALIDATION_ERROR` (400), `UNAUTHORIZED` (401), `NOT_FOUND` (404),
`EMAIL_TAKEN` (409), `INTERNAL_ERROR` (500).

| Метод  | Путь               | Auth | Успех | Примечание |
|--------|--------------------|------|-------|------------|
| GET    | `/health`          | —    | 200   | `{"status":"ok"}` |
| POST   | `/auth/register`   | —    | 201   | `{email,password,name}` → `{token,user}`; 409 EMAIL_TAKEN |
| POST   | `/auth/login`      | —    | 200   | `{email,password}` → `{token,user}`; 401 UNAUTHORIZED |
| GET    | `/auth/me`         | JWT  | 200   | текущий пользователь |
| GET    | `/notes`           | JWT  | 200   | `?page=&limit=&search=` → `{items,page,limit,total}` |
| POST   | `/notes`           | JWT  | 201   | `{title,content}`; 400 без title |
| GET    | `/notes/{id}`      | JWT  | 200   | 404 — нет или чужая |
| PUT    | `/notes/{id}`      | JWT  | 200   | 400 / 404 |
| DELETE | `/notes/{id}`      | JWT  | 204   | пустое тело; 404 |
| GET    | `/properties`      | JWT  | 200   | `?page=&limit=&search=` → `{items,page,limit,total}` (25 стартовых + свои) |
| POST   | `/properties`      | JWT  | 201   | `{title,address,price,type,rooms,area,rating,agentName,agentPhone,imageInitials}`; 400 без title |
| GET    | `/properties/{id}` | JWT  | 200   | 404 — нет или чужое |
| PUT    | `/properties/{id}` | JWT  | 200   | 400 / 404 |
| DELETE | `/properties/{id}` | JWT  | 204   | пустое тело; 404 |
| GET    | `/bookings`        | JWT  | 200   | `?page=&limit=&search=` → `{items,page,limit,total}` |
| POST   | `/bookings`        | JWT  | 201   | `{propertyTitle,name,phone,date,time,status,propertyId?}`; 400 |
| GET    | `/bookings/{id}`   | JWT  | 200   | 404 — нет или чужая |
| PUT    | `/bookings/{id}`   | JWT  | 200   | 400 / 404 |
| DELETE | `/bookings/{id}`   | JWT  | 204   | пустое тело; 404 |
| POST   | `/files`           | JWT  | 201   | multipart, поле `file`, ≤ 5 МБ → `{id,url:"/files/{id}",...}` |
| GET    | `/files/{id}`      | —    | 200   | байты; `Content-Disposition: attachment` + CSP |

Чужая запись отвечает **404, а не 403**: сервер не раскрывает, что объект
существует — «не моё» и «не существует» выглядят одинаково.

Скачивания отдаются с `Content-Disposition: attachment` и ограничивающим CSP —
ссылка, открытая прямо в браузере, скачивается, а не отображается; без этих
заголовков любой, кто загрузил бы text/html, выполнял бы скрипт на origin-е API
(stored XSS). `Image.network` игнорирует оба заголовка.

## Структура

```
bin/rent_easy_server.dart   точка входа (env, запуск)
lib/app.dart                маршруты + middleware (лог, CORS, 500 в конверте)
lib/db.dart                 схема SQLite (CREATE TABLE IF NOT EXISTS)
lib/auth.dart               register / login / me, JWT, guard-middleware
lib/notes.dart              CRUD-шаблон: копируется для каждой сущности темы
lib/properties.dart         CRUD-модуль сущности темы Property (/properties)
lib/bookings.dart           CRUD-модуль сущности темы Booking (/bookings)
lib/files.dart              upload / download
lib/http_utils.dart         JSON-ответы, конверт ошибки, пагинация
conformance/                набор тестов соответствия
```

Лабораторная конфигурация, принятая как есть: открытый CORS, секрет JWT по
умолчанию, сервер на ноутбуке (без deploy).

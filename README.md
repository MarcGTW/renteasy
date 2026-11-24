# RentEasy

Мобильное приложение аренды и продажи недвижимости (Flutter) — лабораторные
работы по дисциплине «Программирование мобильных приложений» (PAM).

- `lib/` — Flutter-приложение.
- `server/` — собственный backend (L5). **Выбранный язык backend-а: Dart**
  (shelf + sqlite3 + JWT). Запуск: `cd server && dart run` → `http://localhost:8080`.
  Подробности, контракт и набор тестов соответствия — в [server/README.md](server/README.md).

Запуск приложения на эмуляторе Android (сервер на ноутбуке виден как `10.0.2.2`):

```bash
flutter run                                   # apiBase = http://10.0.2.2:8080
flutter run -d chrome --dart-define=API_BASE=http://localhost:8080   # web / desktop
```

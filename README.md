# RentEasy

Мобильное приложение аренды и продажи недвижимости (Flutter) — лабораторные
работы по дисциплине «Программирование мобильных приложений» (PAM).

- `lib/` — Flutter-приложение.
- `server/` — собственный backend (L5). **Выбранный язык backend-а: Dart**
  (shelf + sqlite3 + JWT). Запуск: `cd server && dart run` → `http://localhost:8080`.
  Подробности, контракт и набор тестов соответствия — в [server/README.md](server/README.md).

Запуск приложения на физическом телефоне по USB (проброс порта к серверу на ноутбуке):

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
flutter run                                   # apiBase = http://localhost:8080
```

Для Android-эмулятора без `adb reverse`:

```powershell
flutter run --dart-define=API_BASE=http://10.0.2.2:8080
```

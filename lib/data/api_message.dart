import 'dart:convert';

import 'package:http/http.dart' as http;

/// Вскрывает стандартный конверт ошибки сервера
/// `{"error": {"code": "...", "message": "..."}}` и переводит код в
/// сообщение для пользователя на русском языке.
String apiMessage(http.Response res) {
  try {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final error = data['error'] as Map<String, dynamic>;
    final code = error['code'] as String;
    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' => 'Неверный email или пароль',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      _ => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    return 'Ошибка сервера (${res.statusCode})';
  } on TypeError {
    return 'Ошибка сервера (${res.statusCode})';
  }
}

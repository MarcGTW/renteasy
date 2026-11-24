import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

/// Общий HTTP-помощник для репозиториев L5:
/// ставит заголовок `Authorization: Bearer <token>`, ограничивает запрос
/// таймаутом и сводит все три слоя отказа C8 (сеть/таймаут, статус сервера,
/// ошибки парсинга) в `Err(msg)`. При 401 стирает token и вызывает [onUnauthorized].
class HttpJsonClient {
  HttpJsonClient(this.baseUrl, this.tokens, {this.onUnauthorized});

  final String baseUrl;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 8);

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await tokens.read() ?? ''}',
  };

  Future<String> _sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }

  Future<Result<T>> send<T>(
    Future<http.Response> Function(Map<String, String> headers) request,
    int expectedStatus,
    T Function(http.Response res) parse,
  ) async {
    try {
      final res = await request(await _headers()).timeout(_timeout);
      if (res.statusCode == 401) return Err(await _sessionDied());
      if (res.statusCode != expectedStatus) return Err(apiMessage(res));
      return Ok(parse(res));
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking.dart';
import 'booking_repository.dart';
import 'http_json.dart';
import 'result.dart';
import 'token_store.dart';

/// HTTP-реализация контракта [BookingRepository] поверх `/bookings`.
class HttpBookingRepository implements BookingRepository {
  HttpBookingRepository(String baseUrl, TokenStore tokens, {
    void Function()? onUnauthorized,
  }) : _client = HttpJsonClient(baseUrl, tokens, onUnauthorized: onUnauthorized);

  final HttpJsonClient _client;

  @override
  Future<Result<List<Booking>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    final uri = Uri.parse('${_client.baseUrl}/bookings').replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _client.send(
      (h) => http.get(uri, headers: h),
      200,
      (res) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['items'] as List)
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Result<Booking>> fetchById(String id) => _client.send(
    (h) => http.get(Uri.parse('${_client.baseUrl}/bookings/$id'), headers: h),
    200,
    (res) => Booking.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
  );

  @override
  Future<Result<Booking>> create(Booking booking) => _client.send(
    (h) => http.post(
      Uri.parse('${_client.baseUrl}/bookings'),
      headers: h,
      body: jsonEncode(booking.toJson()),
    ),
    201,
    (res) => Booking.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
  );

  @override
  Future<Result<Booking>> update(Booking booking) => _client.send(
    (h) => http.put(
      Uri.parse('${_client.baseUrl}/bookings/${booking.id}'),
      headers: h,
      body: jsonEncode(booking.toJson()),
    ),
    200,
    (res) => Booking.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
  );

  @override
  Future<Result<void>> delete(String id) => _client.send(
    (h) => http.delete(
      Uri.parse('${_client.baseUrl}/bookings/$id'),
      headers: h,
    ),
    204,
    (_) {}, // 204 имеет пустое тело — без jsonDecode
  );
}

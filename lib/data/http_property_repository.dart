import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/property.dart';
import 'http_json.dart';
import 'property_repository.dart';
import 'result.dart';
import 'token_store.dart';

/// HTTP-реализация контракта [PropertyRepository] поверх `/properties`.
class HttpPropertyRepository implements PropertyRepository {
  HttpPropertyRepository(String baseUrl, TokenStore tokens, {
    void Function()? onUnauthorized,
  }) : _client = HttpJsonClient(baseUrl, tokens, onUnauthorized: onUnauthorized);

  final HttpJsonClient _client;

  @override
  Future<Result<List<Property>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    final uri = Uri.parse('${_client.baseUrl}/properties').replace(
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
            .map((e) => Property.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Result<Property>> fetchById(String id) => _client.send(
    (h) => http.get(Uri.parse('${_client.baseUrl}/properties/$id'), headers: h),
    200,
    (res) => Property.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
  );

  @override
  Future<Result<Property>> create(Property property) => _client.send(
    (h) => http.post(
      Uri.parse('${_client.baseUrl}/properties'),
      headers: h,
      body: jsonEncode(property.toJson()),
    ),
    201,
    (res) => Property.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
  );

  @override
  Future<Result<Property>> update(Property property) => _client.send(
    (h) => http.put(
      Uri.parse('${_client.baseUrl}/properties/${property.id}'),
      headers: h,
      body: jsonEncode(property.toJson()),
    ),
    200,
    (res) => Property.fromJson(jsonDecode(res.body) as Map<String, dynamic>),
  );

  @override
  Future<Result<void>> delete(String id) => _client.send(
    (h) => http.delete(
      Uri.parse('${_client.baseUrl}/properties/$id'),
      headers: h,
    ),
    204,
    (_) {}, // 204 имеет пустое тело — без jsonDecode
  );
}

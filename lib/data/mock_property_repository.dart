
import '../models/property.dart';
import 'mock_data.dart';
import 'property_repository.dart';
import 'result.dart';

class MockPropertyRepository implements PropertyRepository {
  final List<Property> _properties = List.from(mockProperties);

  bool simulateError = false;

  int _nextId = 7;

  Future<bool> _prepareRequest() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return !simulateError;
  }

  @override
  Future<Result<List<Property>>> fetchAll() async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка загрузки объектов недвижимости');
    }

    return Ok(List.unmodifiable(_properties));
  }

  @override
  Future<Result<Property>> fetchById(String id) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка загрузки объекта недвижимости');
    }

    try {
      final property = _properties.firstWhere((item) => item.id == id);
      return Ok(property);
    } catch (_) {
      return const Err('Объект недвижимости не найден');
    }
  }

  @override
  Future<Result<Property>> create(Property property) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка создания объекта недвижимости');
    }

    final newProperty = property.copyWith(id: (_nextId++).toString());
    _properties.add(newProperty);

    return Ok(newProperty);
  }

  @override
  Future<Result<Property>> update(Property property) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка обновления объекта недвижимости');
    }

    final index = _properties.indexWhere(
      (item) => item.id == property.id,
    );

    if (index == -1) {
      return const Err('Объект недвижимости не найден');
    }

    _properties[index] = property;

    return Ok(property);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка удаления объекта недвижимости');
    }

    final index = _properties.indexWhere((item) => item.id == id);

    if (index == -1) {
      return const Err('Объект недвижимости не найден');
    }

    _properties.removeAt(index);

    return const Ok(null);
  }
}

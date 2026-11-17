import 'package:flutter/foundation.dart';

import '../data/property_repository.dart';
import '../data/result.dart';
import 'property.dart';

class PropertyModel extends ChangeNotifier {
  final PropertyRepository _repository;

  PropertyModel(this._repository);

  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;

  List<Property> get properties => List.unmodifiable(_properties);

  int get count => _properties.length;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Property? byId(String id) {
    for (final property in _properties) {
      if (property.id == id) {
        return property;
      }
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.fetchAll();

    switch (result) {
      case Ok<List<Property>>():
        _properties = List.of(result.value);
        _error = null;

      case Err<List<Property>>():
        _error = result.msg;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> add(Property property) async {
    final result = await _repository.create(property);

    switch (result) {
      case Ok<Property>():
        _properties = [..._properties, result.value];
        notifyListeners();
        return true;

      case Err<Property>():
        _error = result.msg;
        notifyListeners();
        return false;
    }
  }

  Future<bool> update(Property property) async {
    final result = await _repository.update(property);

    switch (result) {
      case Ok<Property>():
        final index = _properties.indexWhere(
          (item) => item.id == property.id,
        );

        if (index != -1) {
          _properties[index] = result.value;
        }

        notifyListeners();
        return true;

      case Err<Property>():
        _error = result.msg;
        notifyListeners();
        return false;
    }
  }

  Future<bool> remove(String id) async {
    final result = await _repository.delete(id);

    switch (result) {
      case Ok<void>():
        _properties.removeWhere((property) => property.id == id);
        notifyListeners();
        return true;

      case Err<void>():
        _error = result.msg;
        notifyListeners();
        return false;
    }
  }
}
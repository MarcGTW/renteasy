import 'package:flutter/foundation.dart';

import '../data/property_repository.dart';
import '../data/result.dart';
import 'property.dart';

class PropertyModel extends ChangeNotifier {
  final PropertyRepository _repository;

  PropertyModel(this._repository);

  static const int _limit = 20;

  List<Property> _properties = [];
  bool _isLoading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _search = '';
  String? _error;

  List<Property> get properties => List.unmodifiable(_properties);

  int get count => _properties.length;

  bool get isLoading => _isLoading;

  bool get hasMore => _hasMore;

  String get search => _search;

  String? get error => _error;

  Property? byId(String id) {
    for (final property in _properties) {
      if (property.id == id) {
        return property;
      }
    }
    return null;
  }

  Future<void> load({String? search}) async {
    _search = search ?? _search;
    _page = 1;
    _hasMore = false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.fetchAll(
      page: _page,
      limit: _limit,
      search: _search,
    );

    switch (result) {
      case Ok<List<Property>>():
        _properties = List.of(result.value);
        _hasMore = result.value.length == _limit;
        _error = null;

      case Err<List<Property>>():
        _error = result.msg;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || _isLoading || !_hasMore) return;
    // Без notifyListeners() здесь: loadMore() вызывается из itemBuilder.
    _loadingMore = true;

    final result = await _repository.fetchAll(
      page: _page + 1,
      limit: _limit,
      search: _search,
    );

    switch (result) {
      case Ok<List<Property>>():
        _page += 1;
        _properties = [..._properties, ...result.value];
        _hasMore = result.value.length == _limit;

      case Err<List<Property>>():
        _error = result.msg;
    }

    _loadingMore = false;
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
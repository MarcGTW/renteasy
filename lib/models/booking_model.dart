import 'package:flutter/foundation.dart';

import '../data/booking_repository.dart';
import '../data/result.dart';
import 'booking.dart';

class BookingModel extends ChangeNotifier {
  final BookingRepository _repository;

  BookingModel(this._repository);

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => List.unmodifiable(_bookings);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.fetchAll();

    switch (result) {
      case Ok<List<Booking>>():
        _bookings = List.of(result.value);
        _error = null;

      case Err<List<Booking>>():
        _error = result.msg;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Booking?> getById(String id) async {
    final result = await _repository.fetchById(id);

    switch (result) {
      case Ok<Booking>():
        return result.value;

      case Err<Booking>():
        _error = result.msg;
        notifyListeners();
        return null;
    }
  }

  Future<bool> add(Booking booking) async {
    final result = await _repository.create(booking);

    switch (result) {
      case Ok<Booking>():
        _bookings = [..._bookings, result.value];
        notifyListeners();
        return true;

      case Err<Booking>():
        _error = result.msg;
        notifyListeners();
        return false;
    }
  }

  Future<bool> update(Booking booking) async {
    final result = await _repository.update(booking);

    switch (result) {
      case Ok<Booking>():
        final index = _bookings.indexWhere(
          (item) => item.id == booking.id,
        );

        if (index != -1) {
          _bookings[index] = result.value;
        }

        notifyListeners();
        return true;

      case Err<Booking>():
        _error = result.msg;
        notifyListeners();
        return false;
    }
  }

  Future<bool> remove(String id) async {
    final result = await _repository.delete(id);

    switch (result) {
      case Ok<void>():
        _bookings.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;

      case Err<void>():
        _error = result.msg;
        notifyListeners();
        return false;
    }
  }
}
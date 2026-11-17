
import '../models/booking.dart';
import 'booking_repository.dart';
import 'mock_bookings.dart';
import 'result.dart';

class MockBookingRepository implements BookingRepository {
  final List<Booking> _bookings = List.from(mockBookings);

  bool simulateError = false;
  int _nextId = 7;

  Future<bool> _prepareRequest() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return !simulateError;
  }

  @override
  Future<Result<List<Booking>>> fetchAll() async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка загрузки заявок');
    }

    return Ok(List.unmodifiable(_bookings));
  }

  @override
  Future<Result<Booking>> fetchById(String id) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка загрузки заявки');
    }

    final index = _bookings.indexWhere((item) => item.id == id);

    if (index == -1) {
      return const Err('Заявка не найдена');
    }

    return Ok(_bookings[index]);
  }

  @override
  Future<Result<Booking>> create(Booking booking) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка создания заявки');
    }

    final newBooking = booking.copyWith(
      id: (_nextId++).toString(),
    );

    _bookings.add(newBooking);

    return Ok(newBooking);
  }

  @override
  Future<Result<Booking>> update(Booking booking) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка обновления заявки');
    }

    final index = _bookings.indexWhere(
      (item) => item.id == booking.id,
    );

    if (index == -1) {
      return const Err('Заявка не найдена');
    }

    _bookings[index] = booking;

    return Ok(booking);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (!await _prepareRequest()) {
      return const Err('Ошибка удаления заявки');
    }

    final index = _bookings.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      return const Err('Заявка не найдена');
    }

    _bookings.removeAt(index);

    return const Ok(null);
  }
}

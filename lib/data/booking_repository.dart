
import '../models/booking.dart';
import 'result.dart';

abstract class BookingRepository {
  Future<Result<List<Booking>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<Booking>> fetchById(String id);

  Future<Result<Booking>> create(Booking booking);

  Future<Result<Booking>> update(Booking booking);

  Future<Result<void>> delete(String id);
}

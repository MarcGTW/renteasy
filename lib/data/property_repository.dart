
import '../models/property.dart';
import 'result.dart';

abstract class PropertyRepository {
  Future<Result<List<Property>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<Property>> fetchById(String id);

  Future<Result<Property>> create(Property property);

  Future<Result<Property>> update(Property property);

  Future<Result<void>> delete(String id);
}

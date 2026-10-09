import 'package:runners_app/api/api_client.dart';
import 'package:runners_app/models/geo_point.dart';

class RunnerRepository {
  new({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<void> setOnline({required bool isOnline}) {
    return _api.patch('/api/runners/me/status', {'is_online': isOnline});
  }

  Future<void> publishLocation(GeoPoint point) {
    return _api.post('/api/runners/me/location', point.toJson());
  }
}

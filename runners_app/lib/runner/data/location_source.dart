import 'package:geolocator/geolocator.dart';
import 'package:runners_app/models/geo_point.dart';

class LocationFailure implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationSource {
  Future<GeoPoint> current();
}

class GeolocatorLocationSource implements LocationSource {
  const new();

  @override
  Future<GeoPoint> current() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationFailure('Location services are turned off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationFailure('Location permission was denied');
    }

    final position = await Geolocator.getCurrentPosition();
    return GeoPoint(lat: position.latitude, lng: position.longitude);
  }
}

import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const new({required this.lat, required this.lng});

  factory fromJson(Map<String, dynamic> json) {
    return GeoPoint(lat: _asDouble(json['lat']), lng: _asDouble(json['lng']));
  }

  static GeoPoint? maybe(Object? json) {
    if (json is! Map) return null;
    return GeoPoint.fromJson(Map<String, dynamic>.from(json));
  }

  final double lat;
  final double lng;

  bool get isValid => lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  List<Object> get props => [lat, lng];
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw const FormatException('Expected a coordinate');
}

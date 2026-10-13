import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/models/zambia.dart';

class PlaceHit {
  const new({required this.name, required this.point});

  final String name;
  final GeoPoint point;
}

class ZambiaPlaces {
  const new({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<PlaceHit>> search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'countrycodes': 'zm',
      'limit': '6',
    });
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            uri,
            headers: const {
              'accept': 'application/json',
              'user-agent': 'Errand/1.0 (com.runners.runners_app)',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const [];
      return placesFromBody(jsonDecode(response.body));
    } finally {
      if (_client == null) client.close();
    }
  }
}

List<PlaceHit> placesFromBody(Object? decoded) {
  if (decoded is! List) return const [];
  return [
    for (final item in decoded)
      if (item is Map) ?placeFromJson(Map<String, dynamic>.from(item)),
  ];
}

PlaceHit? placeFromJson(Map<String, dynamic> json) {
  final lat = double.tryParse('${json['lat']}');
  final lng = double.tryParse('${json['lon']}');
  final name = json['display_name'];
  if (lat == null || lng == null || name is! String || name.trim().isEmpty) {
    return null;
  }
  final point = GeoPoint(lat: lat, lng: lng);
  if (!inZambia(point)) return null;
  final label = name.trim();
  return PlaceHit(
    name: label.length > 180 ? label.substring(0, 180) : label,
    point: point,
  );
}

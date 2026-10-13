import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:runners_app/models/geo_point.dart';

class RoadRoute {
  const new({http.Client? client}) : _client = client;

  static final _cache = <String, List<GeoPoint>>{};

  final http.Client? _client;

  Future<List<GeoPoint>> between(GeoPoint from, GeoPoint to) async {
    final key = '${_pin(from)}>${_pin(to)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final points = await _fetch(from, to);
    if (_cache.length > 40) _cache.remove(_cache.keys.first);
    _cache[key] = points;
    return points;
  }

  Future<List<GeoPoint>> _fetch(GeoPoint from, GeoPoint to) async {
    final path =
        '/route/v1/driving/'
        '${from.lng},${from.lat};${to.lng},${to.lat}';
    final uri = Uri.https('router.project-osrm.org', path, const {
      'overview': 'full',
      'geometries': 'geojson',
      'alternatives': 'false',
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
      if (response.statusCode != 200) return [from, to];
      final points = routeFromOsrm(jsonDecode(response.body));
      if (points.length < 2) return [from, to];
      return points;
    } on Object {
      return [from, to];
    } finally {
      if (_client == null) client.close();
    }
  }
}

List<GeoPoint> routeFromOsrm(Object? decoded) {
  if (decoded is! Map) return const [];
  final routes = decoded['routes'];
  if (routes is! List || routes.isEmpty) return const [];
  final first = routes.first;
  if (first is! Map) return const [];
  final geometry = first['geometry'];
  if (geometry is! Map) return const [];
  final coordinates = geometry['coordinates'];
  if (coordinates is! List) return const [];
  return [
    for (final pair in coordinates)
      if (pair is List && pair.length >= 2 && pair[0] is num && pair[1] is num)
        GeoPoint(
          lat: (pair[1] as num).toDouble(),
          lng: (pair[0] as num).toDouble(),
        ),
  ];
}

String _pin(GeoPoint point) {
  return '${point.lat.toStringAsFixed(5)},${point.lng.toStringAsFixed(5)}';
}

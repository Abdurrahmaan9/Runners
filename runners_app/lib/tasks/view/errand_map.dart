import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/models/zambia.dart';
import 'package:runners_app/theme/app_theme.dart';

enum ErrandStopKind { pickup, dropoff, runner }

class ErrandStop {
  const new({
    required this.id,
    required this.point,
    required this.kind,
    this.title = '',
  });

  final String id;
  final GeoPoint point;
  final ErrandStopKind kind;
  final String title;
}

const _lusaka = GeoPoint(lat: -15.3875, lng: 28.3228);

List<ErrandStop> stopsFromTask(
  RunnerTask task, {
  GeoPoint? runner,
  String runnerTitle = '',
}) {
  final pickup = task.pickupLocation;
  return [
    if (pickup != null)
      ErrandStop(
        id: '${task.id}-pickup',
        point: pickup,
        kind: ErrandStopKind.pickup,
        title: task.pickupAddress,
      ),
    ErrandStop(
      id: '${task.id}-dropoff',
      point: task.dropoffLocation,
      kind: ErrandStopKind.dropoff,
      title: task.dropoffAddress,
    ),
    if (runner != null)
      ErrandStop(
        id: '${task.id}-runner',
        point: runner,
        kind: ErrandStopKind.runner,
        title: runnerTitle,
      ),
  ];
}

List<ErrandStop> stopsFromTasks(List<RunnerTask> tasks) {
  return [for (final task in tasks) ...stopsFromTask(task)];
}

List<List<GeoPoint>> routesFromTasks(List<RunnerTask> tasks) {
  return [
    for (final task in tasks)
      if (task.pickupLocation != null)
        [task.pickupLocation!, task.dropoffLocation],
  ];
}

class ErrandMap extends StatefulWidget {
  const new({
    super.key,
    this.stops = const [],
    this.routes = const [],
    this.follow,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.gestures = true,
  });

  final List<ErrandStop> stops;
  final List<List<GeoPoint>> routes;
  final GeoPoint? follow;
  final EdgeInsets padding;
  final ValueChanged<GeoPoint>? onTap;
  final bool gestures;

  @override
  State<ErrandMap> createState() => _ErrandMapState();
}

class _ErrandMapState extends State<ErrandMap> {
  final _map = MapController();
  var _ready = false;
  GeoPoint? _followed;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ErrandMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final follow = widget.follow;
    if (follow != null && follow != _followed) {
      _followed = follow;
      _goTo(follow, zoom: 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final target = widget.follow ?? _firstPoint() ?? _lusaka;
    return SizedBox.expand(
      child: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _latLng(target),
          minZoom: 6,
          cameraConstraint: CameraConstraint.containCenter(
            bounds: LatLngBounds(
              const LatLng(zambiaSouth, zambiaWest),
              const LatLng(zambiaNorth, zambiaEast),
            ),
          ),
          backgroundColor: dark
              ? const Color(0xFF121A17)
              : const Color(0xFFE7EEEA),
          interactionOptions: InteractionOptions(
            flags: widget.gestures ? InteractiveFlag.all : InteractiveFlag.none,
          ),
          onTap: widget.onTap == null
              ? null
              : (_, point) => widget.onTap!(
                  GeoPoint(lat: point.latitude, lng: point.longitude),
                ),
          onMapReady: _onReady,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.runners.runners_app',
          ),
          PolylineLayer(
            polylines: [
              for (final route in widget.routes)
                if (route.length >= 2)
                  Polyline(
                    points: [for (final point in route) _latLng(point)],
                    color: AppTheme.teal,
                    strokeWidth: 4,
                  ),
            ],
          ),
          MarkerLayer(
            markers: [
              for (final stop in widget.stops)
                Marker(
                  point: _latLng(stop.point),
                  width: 22,
                  height: 22,
                  child: _Pin(color: _color(stop.kind)),
                ),
            ],
          ),
          const SimpleAttributionWidget(
            source: Text('OpenStreetMap contributors'),
          ),
        ],
      ),
    );
  }

  void _onReady() {
    _ready = true;
    final follow = widget.follow;
    if (follow != null) {
      _followed = follow;
      _goTo(follow, zoom: 15);
      return;
    }
    _fit();
  }

  void _fit() {
    if (!_ready) return;
    final points = [for (final stop in widget.stops) _latLng(stop.point)];
    if (points.isEmpty) {
      _map.move(_latLng(_lusaka), 12);
      return;
    }
    if (points.length == 1 || _span(points) < 0.002) {
      _map.move(points.first, 15);
      return;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: EdgeInsets.fromLTRB(
          32 + widget.padding.left,
          32 + widget.padding.top,
          32 + widget.padding.right,
          32 + widget.padding.bottom,
        ),
        maxZoom: 16,
      ),
    );
  }

  void _goTo(GeoPoint point, {required double zoom}) {
    if (!_ready) return;
    _map.move(_latLng(point), zoom, offset: Offset(0, widget.padding.top / 2));
  }

  GeoPoint? _firstPoint() {
    if (widget.stops.isEmpty) return null;
    return widget.stops.first.point;
  }
}

class _Pin extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.white, width: 2),
      ),
    );
  }
}

LatLng _latLng(GeoPoint point) => LatLng(point.lat, point.lng);

Color _color(ErrandStopKind kind) {
  return switch (kind) {
    ErrandStopKind.pickup => AppTheme.teal,
    ErrandStopKind.dropoff => AppTheme.copper,
    ErrandStopKind.runner => const Color(0xFFD4537E),
  };
}

double _span(List<LatLng> points) {
  final bounds = LatLngBounds.fromPoints(points);
  return math.max(
    (bounds.north - bounds.south).abs(),
    (bounds.east - bounds.west).abs(),
  );
}

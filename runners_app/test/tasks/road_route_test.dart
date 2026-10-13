import 'package:flutter_test/flutter_test.dart';
import 'package:runners_app/tasks/data/road_route.dart';

void main() {
  test('reads the driving path from a routing response', () {
    final points = routeFromOsrm({
      'code': 'Ok',
      'routes': [
        {
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              [28.28, -15.41],
              [28.29, -15.42],
              [28.35, -15.43],
            ],
          },
        },
      ],
    });

    expect(points, hasLength(3));
    expect(points.first.lng, 28.28);
    expect(points.first.lat, -15.41);
    expect(points.last.lng, 28.35);
  });

  test('ignores a routing response without a path', () {
    expect(
      routeFromOsrm({'code': 'NoRoute', 'routes': <Object>[]}),
      isEmpty,
    );
  });
}

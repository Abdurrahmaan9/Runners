import 'package:flutter_test/flutter_test.dart';
import 'package:runners_app/models/create_task_draft.dart';
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/models/runner_task.dart';

void main() {
  test('rejects coordinates outside WGS84 bounds', () {
    expect(const GeoPoint(lat: 95, lng: 28).isValid, isFalse);
    expect(const GeoPoint(lat: -15.4, lng: 28.3).isValid, isTrue);
  });

  test('parses a task payload from the API', () {
    final task = RunnerTask.fromJson(const {
      'id': 'task-1',
      'requester_id': 'user-1',
      'runner_id': null,
      'title': 'Pick up groceries',
      'description': 'Milk and bread',
      'task_type': 'store_pickup',
      'status': 'posted',
      'pickup_address': 'Shoprite',
      'pickup_location': {'lat': -15.4167, 'lng': 28.2833},
      'dropoff_address': 'Kabulonga',
      'dropoff_location': {'lat': -15.43, 'lng': 28.35},
      'estimated_cost': '75.00',
    });

    expect(task.runnerAdvance, isNull);
    expect(task.dropoffLocation.lat, -15.43);
    expect(task.pickupLocation?.lng, 28.2833);
  });

  test('serializes a create draft for the API', () {
    const draft = CreateTaskDraft(
      title: '  Medicine  ',
      description: 'From the pharmacy',
      taskType: 'delivery',
      pickupAddress: 'Pharmacy',
      dropoffAddress: 'Home',
      estimatedCost: '40',
      pickup: GeoPoint(lat: -15.4, lng: 28.3),
      dropoff: GeoPoint(lat: -15.41, lng: 28.31),
    );

    expect(draft.toJson()['title'], 'Medicine');
    expect(draft.toJson()['pickup_location'], {'lat': -15.4, 'lng': 28.3});
  });
}

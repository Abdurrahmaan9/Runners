import 'package:runners_app/models/geo_point.dart';

class CreateTaskDraft {
  const new({
    required this.title,
    required this.description,
    required this.taskType,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedCost,
    required this.pickup,
    required this.dropoff,
  });

  final String title;
  final String description;
  final String taskType;
  final String pickupAddress;
  final String dropoffAddress;
  final String estimatedCost;
  final GeoPoint pickup;
  final GeoPoint dropoff;

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'task_type': taskType,
      'pickup_address': pickupAddress.trim(),
      'pickup_location': pickup.toJson(),
      'dropoff_address': dropoffAddress.trim(),
      'dropoff_location': dropoff.toJson(),
      'estimated_cost': estimatedCost.trim(),
    };
  }
}

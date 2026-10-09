import 'package:equatable/equatable.dart';
import 'package:runners_app/models/geo_point.dart';

class TaskParty extends Equatable {
  const new({required this.id, required this.fullName});

  factory fromJson(Map<String, dynamic> json) {
    return TaskParty(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
    );
  }

  final String id;
  final String fullName;

  @override
  List<Object> get props => [id, fullName];
}

class RunnerTask extends Equatable {
  const new({
    required this.id,
    required this.requesterId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedCost,
    required this.dropoffLocation,
    this.runnerId,
    this.requester,
    this.runner,
    this.pickupLocation,
  });

  factory fromJson(Map<String, dynamic> json) {
    return RunnerTask(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      runnerId: json['runner_id'] as String?,
      requester: _party(json['requester']),
      runner: _party(json['runner']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      taskType: json['task_type'] as String? ?? '',
      status: json['status'] as String? ?? 'posted',
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupLocation: GeoPoint.maybe(json['pickup_location']),
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      dropoffLocation:
          GeoPoint.maybe(json['dropoff_location']) ??
          const GeoPoint(lat: -15.3875, lng: 28.3228),
      estimatedCost: json['estimated_cost']?.toString() ?? '0',
    );
  }

  final String id;
  final String requesterId;
  final String? runnerId;
  final TaskParty? requester;
  final TaskParty? runner;
  final String title;
  final String description;
  final String taskType;
  final String status;
  final String pickupAddress;
  final GeoPoint? pickupLocation;
  final String dropoffAddress;
  final GeoPoint dropoffLocation;
  final String estimatedCost;

  bool get isTerminal => status == 'completed' || status == 'cancelled';

  String? get runnerAdvance {
    return switch (status) {
      'assigned' => 'runner_arrived',
      'runner_arrived' => 'in_progress',
      'in_progress' => 'completed',
      _ => null,
    };
  }

  @override
  List<Object?> get props => [
    id,
    requesterId,
    runnerId,
    requester,
    runner,
    title,
    description,
    taskType,
    status,
    pickupAddress,
    pickupLocation,
    dropoffAddress,
    dropoffLocation,
    estimatedCost,
  ];
}

TaskParty? _party(Object? json) {
  if (json is! Map) return null;
  return TaskParty.fromJson(Map<String, dynamic>.from(json));
}

List<RunnerTask> tasksFromBody(Map<String, dynamic> body) {
  final data = body['data'];
  if (data is! List) return const [];
  return [
    for (final item in data)
      if (item is Map) RunnerTask.fromJson(Map<String, dynamic>.from(item)),
  ];
}

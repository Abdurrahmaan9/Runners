import 'package:equatable/equatable.dart';
import 'package:runners_app/models/geo_point.dart';

class RunnerProfile extends Equatable {
  const new({
    required this.id,
    required this.isOnline,
    this.currentLocation,
    this.lastLocationUpdate,
  });

  factory fromJson(Map<String, dynamic> json) {
    return RunnerProfile(
      id: json['id'] as String,
      isOnline: json['is_online'] as bool? ?? false,
      currentLocation: GeoPoint.maybe(json['current_location']),
      lastLocationUpdate: json['last_location_update'] as String?,
    );
  }

  final String id;
  final bool isOnline;
  final GeoPoint? currentLocation;
  final String? lastLocationUpdate;

  @override
  List<Object?> get props => [
    id,
    isOnline,
    currentLocation,
    lastLocationUpdate,
  ];
}

class AppUser extends Equatable {
  const new({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.isVerified,
    this.runnerProfile,
  });

  factory fromJson(Map<String, dynamic> json) {
    final profile = json['runner_profile'];
    return AppUser(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      runnerProfile: profile is Map
          ? RunnerProfile.fromJson(Map<String, dynamic>.from(profile))
          : null,
    );
  }

  final String id;
  final String phoneNumber;
  final String fullName;
  final String role;
  final bool isVerified;
  final RunnerProfile? runnerProfile;

  bool get isRunner => role == 'runner';
  bool get isRequester => role == 'requester';

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    fullName,
    role,
    isVerified,
    runnerProfile,
  ];
}

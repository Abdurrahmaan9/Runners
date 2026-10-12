import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  const new({
    required this.errandsPostedToday,
    required this.runners,
    required this.activeRunners,
    required this.requesters,
    required this.errandsOpen,
    required this.errandsActive,
    required this.errandsCompleted,
  });

  factory fromJson(Map<String, dynamic> json) {
    return AdminStats(
      errandsPostedToday: _count(json['errands_posted_today']),
      runners: _count(json['runners']),
      activeRunners: _count(json['active_runners']),
      requesters: _count(json['requesters']),
      errandsOpen: _count(json['errands_open']),
      errandsActive: _count(json['errands_active']),
      errandsCompleted: _count(json['errands_completed']),
    );
  }

  final int errandsPostedToday;
  final int runners;
  final int activeRunners;
  final int requesters;
  final int errandsOpen;
  final int errandsActive;
  final int errandsCompleted;

  @override
  List<Object> get props => [
    errandsPostedToday,
    runners,
    activeRunners,
    requesters,
    errandsOpen,
    errandsActive,
    errandsCompleted,
  ];
}

int _count(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

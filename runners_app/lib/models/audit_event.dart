import 'package:equatable/equatable.dart';

class AuditEvent extends Equatable {
  const new({
    required this.id,
    required this.action,
    required this.metadata,
    required this.insertedAt,
    this.actorName,
    this.subjectType,
    this.subjectId,
  });

  factory fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return AuditEvent(
      id: json['id'] as String,
      action: json['action'] as String? ?? '',
      actorName: json['actor_name'] as String?,
      subjectType: json['subject_type'] as String?,
      subjectId: json['subject_id'] as String?,
      metadata: metadata is Map
          ? Map<String, dynamic>.from(metadata)
          : const <String, dynamic>{},
      insertedAt: json['inserted_at'] as String? ?? '',
    );
  }

  final String id;
  final String action;
  final String? actorName;
  final String? subjectType;
  final String? subjectId;
  final Map<String, dynamic> metadata;
  final String insertedAt;

  String field(String key) {
    final value = metadata[key];
    if (value == null) return '';
    return '$value';
  }

  @override
  List<Object?> get props => [
    id,
    action,
    actorName,
    subjectType,
    subjectId,
    metadata,
    insertedAt,
  ];
}

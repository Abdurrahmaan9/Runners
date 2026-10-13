import 'package:runners_app/api/api_client.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/models/admin_stats.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/models/audit_event.dart';
import 'package:runners_app/models/create_task_draft.dart';
import 'package:runners_app/models/heatmap.dart';
import 'package:runners_app/models/runner_task.dart';

class TaskRepository {
  new({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<AdminStats> adminStats() async {
    final body = await _api.get('/api/admin/stats');
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unexpected response',
      );
    }
    return AdminStats.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ErrandHeatmap> adminHeatmap() async {
    final body = await _api.get('/api/admin/heatmap');
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unexpected response',
      );
    }
    return ErrandHeatmap.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<RunnerTask>> adminErrands(String scope) async {
    final body = await _api.get('/api/admin/errands?scope=$scope');
    return tasksFromBody(body);
  }

  Future<AppUser> adminCreatePerson({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final body = await _api.post('/api/admin/people', {
      'phone_number': phoneNumber,
      'password': password,
      'full_name': fullName,
      'role': role,
    });
    return _user(body);
  }

  Future<AppUser> adminUpdatePerson({
    required String id,
    required String phoneNumber,
    required String fullName,
    required String role,
    String? password,
  }) async {
    final body = await _api.patch('/api/admin/people/$id', {
      'phone_number': phoneNumber,
      'full_name': fullName,
      'role': role,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return _user(body);
  }

  Future<AppUser> adminSetBlocked({
    required String id,
    required bool blocked,
  }) async {
    final path = blocked
        ? '/api/admin/people/$id/block'
        : '/api/admin/people/$id/unblock';
    final body = await _api.post(path);
    return _user(body);
  }

  Future<List<AuditEvent>> adminAudit() async {
    final body = await _api.get('/api/admin/audit');
    final data = body['data'];
    if (data is! List) return const [];
    return [
      for (final item in data)
        if (item is Map) AuditEvent.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<List<AppUser>> adminPeople(String role) async {
    final body = await _api.get('/api/admin/people?role=$role');
    final data = body['data'];
    if (data is! List) return const [];
    return [
      for (final item in data)
        if (item is Map) AppUser.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<List<RunnerTask>> list({String? status}) async {
    final query = status == null ? '' : '?status=$status';
    final body = await _api.get('/api/tasks$query');
    return tasksFromBody(body);
  }

  Future<RunnerTask> create(CreateTaskDraft draft) async {
    final body = await _api.post('/api/tasks', draft.toJson());
    return _task(body);
  }

  Future<RunnerTask> update(String id, CreateTaskDraft draft) async {
    final body = await _api.patch('/api/tasks/$id', draft.toJson());
    return _task(body);
  }

  Future<RunnerTask> fetch(String id) async {
    final body = await _api.get('/api/tasks/$id');
    return _task(body);
  }

  Future<RunnerTask> accept(String id) async {
    final body = await _api.post('/api/tasks/$id/accept');
    return _task(body);
  }

  Future<RunnerTask> advance(String id, String status) async {
    final body = await _api.post('/api/tasks/$id/status', {'status': status});
    return _task(body);
  }

  Future<RunnerTask> cancel(String id) async {
    final body = await _api.post('/api/tasks/$id/cancel');
    return _task(body);
  }

  Future<void> delete(String id) => _api.delete('/api/tasks/$id');

  RunnerTask _task(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unexpected response',
      );
    }
    return RunnerTask.fromJson(Map<String, dynamic>.from(data));
  }

  AppUser _user(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unexpected response',
      );
    }
    return AppUser.fromJson(Map<String, dynamic>.from(data));
  }
}

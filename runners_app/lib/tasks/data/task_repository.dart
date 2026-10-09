import 'package:runners_app/api/api_client.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/models/create_task_draft.dart';
import 'package:runners_app/models/runner_task.dart';

class TaskRepository {
  new({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<List<RunnerTask>> list({String? status}) async {
    final query = status == null ? '' : '?status=$status';
    final body = await _api.get('/api/tasks$query');
    return tasksFromBody(body);
  }

  Future<RunnerTask> create(CreateTaskDraft draft) async {
    final body = await _api.post('/api/tasks', draft.toJson());
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
}

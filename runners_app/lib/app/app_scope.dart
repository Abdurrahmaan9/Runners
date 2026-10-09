import 'package:runners_app/api/api_client.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/config/app_config.dart';
import 'package:runners_app/runner/data/runner_repository.dart';
import 'package:runners_app/tasks/data/task_repository.dart';

class AppScope {
  const new({
    required this.config,
    required this.authRepository,
    required this.taskRepository,
    required this.runnerRepository,
  });

  factory create(AppConfig config) {
    final api = ApiClient(baseUrl: config.apiBaseUrl);
    return AppScope(
      config: config,
      authRepository: AuthRepository(api: api, tokens: SecureTokenStorage()),
      taskRepository: TaskRepository(api: api),
      runnerRepository: RunnerRepository(api: api),
    );
  }

  final AppConfig config;
  final AuthRepository authRepository;
  final TaskRepository taskRepository;
  final RunnerRepository runnerRepository;
}

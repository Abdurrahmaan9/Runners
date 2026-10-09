import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:runners_app/app/app.dart';
import 'package:runners_app/app/app_scope.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/config/app_config.dart';
import 'package:runners_app/runner/data/runner_repository.dart';
import 'package:runners_app/tasks/data/task_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

class _MockTaskRepository extends Mock implements TaskRepository;

class _MockRunnerRepository extends Mock implements RunnerRepository;

void main() {
  testWidgets('shows sign in when the session is empty', (tester) async {
    final auth = _MockAuthRepository();
    when(auth.restore).thenAnswer((_) async => null);

    await tester.pumpWidget(
      App(
        scope: AppScope(
          config: const AppConfig(
            apiBaseUrl: 'http://127.0.0.1:4000',
            flavor: 'test',
          ),
          authRepository: auth,
          taskRepository: _MockTaskRepository(),
          runnerRepository: _MockRunnerRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.textContaining('Errands done'), findsOneWidget);
  });
}

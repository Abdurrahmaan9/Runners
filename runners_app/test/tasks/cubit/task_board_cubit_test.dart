import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/cubit/task_board_cubit.dart';
import 'package:runners_app/tasks/data/task_repository.dart';

class _MockTaskRepository extends Mock implements TaskRepository;

void main() {
  late _MockTaskRepository repository;

  const task = RunnerTask(
    id: 'task-1',
    requesterId: 'user-1',
    title: 'Pick up groceries',
    description: 'Milk and bread',
    taskType: 'store_pickup',
    status: 'posted',
    pickupAddress: 'Shoprite Cairo Road',
    dropoffAddress: 'Kabulonga',
    estimatedCost: '75.00',
    dropoffLocation: GeoPoint(lat: -15.43, lng: 28.35),
  );

  setUp(() {
    repository = _MockTaskRepository();
  });

  blocTest<TaskBoardCubit, TaskBoardState>(
    'loads the open board',
    setUp: () {
      when(() => repository.list(status: any(named: 'status')))
          .thenAnswer((_) async => [task]);
    },
    build: () => TaskBoardCubit(repository: repository, statusFilter: 'posted'),
    act: (cubit) => cubit.load(),
    expect: () => [
      const TaskBoardState(loading: true, statusFilter: 'posted'),
      const TaskBoardState(tasks: [task], statusFilter: 'posted'),
    ],
  );
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/data/task_repository.dart';

class TaskBoardState extends Equatable {
  const new({
    this.tasks = const [],
    this.loading = false,
    this.message,
    this.statusFilter,
  });

  final List<RunnerTask> tasks;
  final bool loading;
  final String? message;
  final String? statusFilter;

  TaskBoardState copyWith({
    List<RunnerTask>? tasks,
    bool? loading,
    String? message,
    String? statusFilter,
    bool clearMessage = false,
    bool updateFilter = false,
  }) {
    return TaskBoardState(
      tasks: tasks ?? this.tasks,
      loading: loading ?? this.loading,
      message: clearMessage ? null : message ?? this.message,
      statusFilter: updateFilter ? statusFilter : this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [tasks, loading, message, statusFilter];
}

class TaskBoardCubit extends Cubit<TaskBoardState> {
  new({required TaskRepository repository, String? statusFilter})
    : _repository = repository,
      super(TaskBoardState(statusFilter: statusFilter));

  final TaskRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    try {
      final tasks = await _repository.list(status: state.statusFilter);
      if (isClosed) return;
      emit(state.copyWith(loading: false, tasks: tasks));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, message: error.message));
    }
  }

  Future<void> changeFilter(String? status) async {
    emit(
      state.copyWith(
        statusFilter: status,
        updateFilter: true,
        clearMessage: true,
      ),
    );
    await load();
  }
}

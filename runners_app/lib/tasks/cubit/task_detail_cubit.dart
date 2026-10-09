import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/data/task_repository.dart';

class TaskDetailState extends Equatable {
  const new({
    required this.task,
    this.busy = false,
    this.deleted = false,
    this.message,
  });

  final RunnerTask task;
  final bool busy;
  final bool deleted;
  final String? message;

  TaskDetailState copyWith({
    RunnerTask? task,
    bool? busy,
    bool? deleted,
    String? message,
    bool clearMessage = false,
  }) {
    return TaskDetailState(
      task: task ?? this.task,
      busy: busy ?? this.busy,
      deleted: deleted ?? this.deleted,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [task, busy, deleted, message];
}

class TaskDetailCubit extends Cubit<TaskDetailState> {
  new({required TaskRepository repository, required RunnerTask task})
    : _repository = repository,
      super(TaskDetailState(task: task));

  final TaskRepository _repository;

  Future<void> accept() => _run(_repository.accept);

  Future<void> advance(String status) {
    return _run((id) => _repository.advance(id, status));
  }

  Future<void> cancel() => _run(_repository.cancel);

  Future<void> delete() async {
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      await _repository.delete(state.task.id);
      if (isClosed) return;
      emit(state.copyWith(busy: false, deleted: true));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, message: error.message));
    }
  }

  Future<void> _run(Future<RunnerTask> Function(String id) action) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      final task = await action(state.task.id);
      if (isClosed) return;
      emit(state.copyWith(busy: false, task: task));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, message: error.message));
    }
  }
}

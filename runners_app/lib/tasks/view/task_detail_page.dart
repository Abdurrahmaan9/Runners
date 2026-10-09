import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/cubit/task_detail_cubit.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/tracking/view/tracking_page.dart';

class TaskDetailPage extends StatelessWidget {
  const new({required this.task, super.key});

  final RunnerTask task;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailCubit(
        repository: context.read<TaskRepository>(),
        task: task,
      ),
      child: const _TaskDetailView(),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<TaskDetailCubit, TaskDetailState>(
      listenWhen: (previous, current) => current.deleted && !previous.deleted,
      listener: (context, state) {
        if (state.deleted) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final task = state.task;
        final user = context.select<AuthCubit, AppUser>(
          (cubit) => cubit.state.user!,
        );
        final cubit = context.read<TaskDetailCubit>();
        final advance = task.runnerAdvance;
        final isRequester = task.requesterId == user.id;
        final isAssigned = task.runnerId == user.id;

        return Scaffold(
          appBar: AppBar(title: Text(task.title)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                taskStatusLabel(l10n, task.status),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(task.description),
              const SizedBox(height: 16),
              _Line(
                label: l10n.taskType,
                value: taskTypeLabel(l10n, task.taskType),
              ),
              _Line(label: l10n.pickupAddress, value: task.pickupAddress),
              _Line(label: l10n.dropoffAddress, value: task.dropoffAddress),
              _Line(label: l10n.estimatedCost, value: task.estimatedCost),
              if (task.runner != null)
                _Line(label: l10n.runner, value: task.runner!.fullName),
              if (state.message != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              if (user.isRunner && task.status == 'posted')
                FilledButton(
                  onPressed: state.busy ? null : cubit.accept,
                  child: Text(l10n.accept),
                ),
              if (isAssigned && advance == 'runner_arrived')
                FilledButton(
                  onPressed: state.busy ? null : () => cubit.advance(advance!),
                  child: Text(l10n.markArrived),
                ),
              if (isAssigned && advance == 'in_progress')
                FilledButton(
                  onPressed: state.busy ? null : () => cubit.advance(advance!),
                  child: Text(l10n.startErrand),
                ),
              if (isAssigned && advance == 'completed')
                FilledButton(
                  onPressed: state.busy ? null : () => cubit.advance(advance!),
                  child: Text(l10n.completeErrand),
                ),
              if (task.status == 'in_progress' &&
                  (isRequester || isAssigned)) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TrackingPage(task: task),
                      ),
                    );
                  },
                  child: Text(l10n.track),
                ),
              ],
              if (!task.isTerminal && (isRequester || isAssigned)) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: state.busy ? null : cubit.cancel,
                  child: Text(l10n.cancelErrand),
                ),
              ],
              if (isRequester && task.status == 'posted')
                TextButton(
                  onPressed: state.busy ? null : cubit.delete,
                  child: Text(l10n.deleteErrand),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value),
        ],
      ),
    );
  }
}

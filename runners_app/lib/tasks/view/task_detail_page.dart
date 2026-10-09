import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/cubit/task_detail_cubit.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';
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
        final user = context.select<AuthCubit, AppUser?>(
          (cubit) => cubit.state.user,
        );
        if (user == null) return const SizedBox.shrink();
        final cubit = context.read<TaskDetailCubit>();
        final advance = task.runnerAdvance;
        final isRequester = task.requesterId == user.id;
        final isAssigned = task.runnerId == user.id;
        final finding = isRequester && task.status == 'posted';

        return Scaffold(
          body: Stack(
            children: [
              ErrandBackdrop(
                pins: [
                  ErrandPin(
                    color: finding ? AppTheme.teal : AppTheme.copper,
                    dx: 0.62,
                    dy: 0.28,
                  ),
                  const ErrandPin(color: AppTheme.teal, dx: 0.42, dy: 0.48),
                ],
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SheetCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      if (finding) ...[
                        Text(
                          l10n.findingTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.findingBody,
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 14),
                        const LinearProgressIndicator(color: AppTheme.teal),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Text(
                              taskStatusLabel(l10n, task.status),
                              style: const TextStyle(
                                color: AppTheme.copper,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                        if (isAssigned) ...[
                          const SizedBox(height: 14),
                          _Steps(status: task.status),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          task.dropoffAddress,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                      if (state.message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.message!,
                          style: const TextStyle(color: Color(0xFFC2413B)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (user.isRunner && task.status == 'posted')
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.copper,
                          ),
                          onPressed: state.busy ? null : cubit.accept,
                          child: Text(l10n.acceptErrand),
                        ),
                      if (isAssigned && advance != null)
                        Row(
                          children: [
                            if (task.status == 'in_progress')
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openTracking(context, task),
                                  child: Text(l10n.navigate),
                                ),
                              ),
                            if (task.status == 'in_progress')
                              const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.copper,
                                ),
                                onPressed: state.busy
                                    ? null
                                    : () => cubit.advance(advance),
                                child: Text(_advanceLabel(l10n, advance)),
                              ),
                            ),
                          ],
                        ),
                      if (task.status == 'in_progress' &&
                          isRequester &&
                          !isAssigned)
                        OutlinedButton(
                          onPressed: () => _openTracking(context, task),
                          child: Text(l10n.track),
                        ),
                      if (!task.isTerminal && (isRequester || isAssigned))
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC2413B),
                              side: const BorderSide(color: Color(0xFFF0C7C4)),
                            ),
                            onPressed: state.busy ? null : cubit.cancel,
                            child: Text(l10n.cancelErrand),
                          ),
                        ),
                      if (isRequester && task.status == 'posted')
                        TextButton(
                          onPressed: state.busy ? null : cubit.delete,
                          child: Text(l10n.deleteErrand),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _advanceLabel(AppLocalizations l10n, String advance) {
    return switch (advance) {
      'runner_arrived' => l10n.arrivedAtPickup,
      'in_progress' => l10n.startErrand,
      _ => l10n.completeErrand,
    };
  }

  void _openTracking(BuildContext context, RunnerTask task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TrackingPage(task: task)));
  }
}

class _Steps extends StatelessWidget {
  const new({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const order = ['assigned', 'runner_arrived', 'in_progress', 'completed'];
    final current = order.indexOf(status);
    final labels = [
      l10n.statusAssigned,
      l10n.arrivedAtPickup,
      l10n.statusInProgress,
      l10n.statusCompleted,
    ];
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: i <= current ? AppTheme.copper : AppTheme.line,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontWeight: i == current
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: i <= current ? AppTheme.ink : AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

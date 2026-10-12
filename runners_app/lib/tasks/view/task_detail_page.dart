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

class _TaskDetailView extends StatefulWidget {
  const new();

  @override
  State<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<_TaskDetailView> {
  bool? _showMap;

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
        final showMap = _showMap ?? _mapFor(user, task);
        final runner = task.runner?.fullName;

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              TextButton(
                onPressed: () => setState(() => _showMap = !showMap),
                child: Text(showMap ? l10n.hideMap : l10n.showMap),
              ),
            ],
          ),
          body: Column(
            children: [
              if (showMap)
                SizedBox(height: 220, child: ErrandBackdrop(pins: _pins(task))),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    if (finding) ...[
                      Text(
                        l10n.findingTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.findingBody,
                        style: TextStyle(color: context.colors.muted),
                      ),
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(color: AppTheme.teal),
                      const SizedBox(height: 18),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            taskTypeLabel(l10n, task.taskType),
                            style: TextStyle(
                              color: context.colors.muted,
                              fontWeight: FontWeight.w700,
                            ),
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
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(task.description),
                    ],
                    const SizedBox(height: 16),
                    _Fact(label: l10n.pickupAddress, value: task.pickupAddress),
                    _Fact(
                      label: l10n.dropoffAddress,
                      value: task.dropoffAddress,
                    ),
                    _Fact(
                      label: l10n.estimatedCost,
                      value: 'K ${task.estimatedCost}',
                    ),
                    if (task.requester != null)
                      _Fact(
                        label: l10n.postedBy,
                        value: task.requester!.fullName,
                      ),
                    _Fact(
                      label: l10n.runner,
                      value: runner ?? l10n.noRunnerYet,
                    ),
                    if (isAssigned) ...[
                      const SizedBox(height: 8),
                      _Steps(status: task.status),
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

bool _mapFor(AppUser user, RunnerTask task) {
  if (task.runnerId == user.id && !task.isTerminal) return true;
  return task.requesterId == user.id &&
      (task.status == 'assigned' ||
          task.status == 'runner_arrived' ||
          task.status == 'in_progress');
}

List<ErrandPin> _pins(RunnerTask task) {
  final pickup = task.pickupLocation;
  return [
    if (pickup != null)
      ErrandPin(
        color: AppTheme.teal,
        dx: _mapX(pickup.lng),
        dy: _mapY(pickup.lat),
      ),
    ErrandPin(
      color: AppTheme.copper,
      dx: _mapX(task.dropoffLocation.lng),
      dy: _mapY(task.dropoffLocation.lat),
    ),
  ];
}

double _mapX(double lng) => ((lng - 28.15) / 0.30).clamp(0.08, 0.92);

double _mapY(double lat) => ((-15.25 - lat) / 0.30).clamp(0.08, 0.92);

class _Fact extends StatelessWidget {
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
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
                    color: i <= current ? AppTheme.copper : context.colors.line,
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
                    color: i <= current
                        ? context.colors.ink
                        : context.colors.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

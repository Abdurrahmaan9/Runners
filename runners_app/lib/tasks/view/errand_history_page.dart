import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/task_detail_page.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';

class ErrandHistoryPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ErrandHistoryPage> createState() => _ErrandHistoryPageState();
}

class _ErrandHistoryPageState extends State<ErrandHistoryPage> {
  var _loading = true;
  String? _error;
  List<RunnerTask> _tasks = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load(initial: true));
  }

  Future<void> _load({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final tasks = await context.read<TaskRepository>().list();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _open(RunnerTask task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => TaskDetailPage(task: task)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthCubit, AppUser?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) return const Scaffold();

    final posted = [
      for (final task in _tasks)
        if (task.requesterId == user.id) task,
    ];
    final accepted = [
      for (final task in _tasks)
        if (task.runnerId == user.id && task.requesterId != user.id) task,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.errandHistory)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFC2413B)),
                  ),
                  TextButton(
                    onPressed: () => unawaited(_load()),
                    child: Text(l10n.tryAgain),
                  ),
                  const SizedBox(height: 12),
                ],
                _Section(
                  title: l10n.postedErrands,
                  empty: l10n.emptyPosted,
                  tasks: posted,
                  onOpen: _open,
                ),
                const SizedBox(height: 28),
                _Section(
                  title: l10n.acceptedErrands,
                  empty: l10n.emptyAccepted,
                  tasks: accepted,
                  onOpen: _open,
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({
    required this.title,
    required this.empty,
    required this.tasks,
    required this.onOpen,
  });

  final String title;
  final String empty;
  final List<RunnerTask> tasks;
  final Future<void> Function(RunnerTask task) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          Text(empty, style: const TextStyle(color: AppTheme.muted))
        else
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppTheme.field,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => unawaited(onOpen(task)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${taskTypeLabel(l10n, task.taskType)} · '
                                '${task.dropoffAddress}',
                                style: const TextStyle(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          taskStatusLabel(l10n, task.status),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

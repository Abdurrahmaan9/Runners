import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/home/view/admin_person_page.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/task_detail_page.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/glass.dart';

enum AdminListKind {
  postedToday,
  runners,
  requesters,
  open,
  underway,
  completed,
}

class AdminListPage extends StatefulWidget {
  const new({required this.kind, super.key});

  final AdminListKind kind;

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  var _loading = true;
  String? _error;
  List<RunnerTask> _tasks = const [];
  List<AppUser> _people = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load(initial: true));
  }

  bool get _peopleList =>
      widget.kind == AdminListKind.runners ||
      widget.kind == AdminListKind.requesters;

  Future<void> _load({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repository = context.read<TaskRepository>();
      if (_peopleList) {
        final role = widget.kind == AdminListKind.runners
            ? 'runner'
            : 'requester';
        final people = await repository.adminPeople(role);
        if (!mounted) return;
        setState(() {
          _people = people;
          _loading = false;
        });
      } else {
        final tasks = await repository.adminErrands(_scope);
        if (!mounted) return;
        setState(() {
          _tasks = tasks;
          _loading = false;
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  String get _scope {
    return switch (widget.kind) {
      AdminListKind.postedToday => 'today',
      AdminListKind.open => 'open',
      AdminListKind.underway => 'underway',
      AdminListKind.completed => 'completed',
      _ => 'open',
    };
  }

  String _title(AppLocalizations l10n) {
    return switch (widget.kind) {
      AdminListKind.postedToday => l10n.postedToday,
      AdminListKind.runners => l10n.runners,
      AdminListKind.requesters => l10n.requesters,
      AdminListKind.open => l10n.openErrands,
      AdminListKind.underway => l10n.errandsUnderway,
      AdminListKind.completed => l10n.completedErrands,
    };
  }

  Future<void> _addPerson() async {
    final role = widget.kind == AdminListKind.runners ? 'runner' : 'requester';
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AdminPersonPage(role: role)),
    );
    if (mounted) await _load();
  }

  Future<void> _openPerson(AppUser person) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AdminPersonPage(person: person)),
    );
    if (mounted) await _load();
  }

  Future<void> _openTask(RunnerTask task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => TaskDetailPage(task: task)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final empty = _peopleList ? _people.isEmpty : _tasks.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(_title(l10n))),
      body: Column(
        children: [
          if (_peopleList)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => unawaited(_addPerson()),
                  child: Text(l10n.addUser),
                ),
              ),
            ),
          Expanded(
            child: _loading
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
                      ] else if (empty)
                        Text(
                          l10n.emptyAdminList,
                          style: TextStyle(color: context.colors.muted),
                        )
                      else if (_peopleList)
                        for (final person in _people)
                          _PersonRow(person: person, onOpen: _openPerson)
                      else
                        for (final task in _tasks)
                          _ErrandRow(task: task, onOpen: _openTask),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const new({required this.person, required this.onOpen});

  final AppUser person;
  final Future<void> Function(AppUser person) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final online = person.runnerProfile?.isOnline ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(14),
        onTap: () => unawaited(onOpen(person)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    person.phoneNumber,
                    style: TextStyle(color: context.colors.muted),
                  ),
                ],
              ),
            ),
            if (person.blocked)
              Text(
                l10n.blockedLabel,
                style: const TextStyle(
                  color: Color(0xFFC2413B),
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (online)
              Text(
                l10n.activeNow,
                style: const TextStyle(
                  color: AppTheme.copper,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrandRow extends StatelessWidget {
  const new({required this.task, required this.onOpen});

  final RunnerTask task;
  final Future<void> Function(RunnerTask task) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(14),
        onTap: () => unawaited(onOpen(task)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${taskTypeLabel(l10n, task.taskType)} · '
                    '${task.dropoffAddress}',
                    style: TextStyle(color: context.colors.muted),
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
    );
  }
}

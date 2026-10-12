import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/audit_event.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_logo.dart';
import 'package:runners_app/theme/glass.dart';

class AdminAuditPage extends StatefulWidget {
  const new({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  var _loading = true;
  String? _error;
  List<AuditEvent> _events = const [];

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
      final events = await context.read<TaskRepository>().adminAudit();
      if (!mounted) return;
      setState(() {
        _events = events;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.teal,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                const ErrandLogo(style: ErrandLogoStyle.mark, height: 32),
                const SizedBox(width: 10),
                Text(
                  l10n.audit,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading && _events.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _events.isEmpty) ...[
              Text(_error!, style: const TextStyle(color: Color(0xFFC2413B))),
              TextButton(
                onPressed: () => unawaited(_load()),
                child: Text(l10n.tryAgain),
              ),
            ] else if (_events.isEmpty)
              Text(
                l10n.auditEmpty,
                style: TextStyle(color: context.colors.muted),
              )
            else
              for (final event in _events) ...[
                Glass(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _summary(l10n, event),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.colors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _when(context, event.insertedAt),
                        style: TextStyle(color: context.colors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

String _summary(AppLocalizations l10n, AuditEvent event) {
  final name = event.field('name');
  final title = event.field('title');
  final actor = event.field('actor');
  final phone = event.field('phone');

  return switch (event.action) {
    'user.registered' => l10n.auditRegistered(name),
    'user.logged_in' => l10n.auditLoggedIn(name),
    'user.login_failed' => l10n.auditLoginFailed(phone),
    'user.login_blocked' => l10n.auditLoginBlocked(name),
    'person.created' => l10n.auditPersonCreated(actor, name),
    'person.updated' => l10n.auditPersonUpdated(actor, name),
    'person.blocked' => l10n.auditPersonBlocked(actor, name),
    'person.unblocked' => l10n.auditPersonUnblocked(actor, name),
    'task.posted' => l10n.auditTaskPosted(name, title),
    'task.updated' => l10n.auditTaskUpdated(name, title),
    'task.deleted' => l10n.auditTaskDeleted(name, title),
    'task.accepted' => l10n.auditTaskAccepted(name, title),
    'task.advanced' => l10n.auditTaskAdvanced(
      name,
      title,
      taskStatusLabel(l10n, event.field('status')),
    ),
    'task.cancelled' => l10n.auditTaskCancelled(name, title),
    'runner.online' => l10n.auditRunnerOnline(name),
    'runner.offline' => l10n.auditRunnerOffline(name),
    _ =>
      event.actorName == null
          ? event.action
          : '${event.actorName} · ${event.action}',
  };
}

String _when(BuildContext context, String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.MMMd(locale).add_jm().format(parsed.toLocal());
}

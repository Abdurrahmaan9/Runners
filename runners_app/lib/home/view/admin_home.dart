import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/home/view/admin_list_page.dart';
import 'package:runners_app/home/view/settings_page.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/admin_stats.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/theme/app_theme.dart';

class AdminHome extends StatefulWidget {
  const new({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthCubit, Object?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _DashboardTab(),
          _HubTab(section: _AdminSection.errands),
          _HubTab(section: _AdminSection.people),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.colors.surface,
        indicatorColor: AppTheme.teal.withValues(alpha: 0.15),
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: l10n.errands,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: l10n.people,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const new();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  var _loading = true;
  String? _error;
  AdminStats? _stats;

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
      final stats = await context.read<TaskRepository>().adminStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  Future<void> _open(AdminListKind kind) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AdminListPage(kind: kind)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = _stats;

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.teal,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              l10n.dashboard,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            if (_loading && stats == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && stats == null) ...[
              Text(_error!, style: const TextStyle(color: Color(0xFFC2413B))),
              TextButton(
                onPressed: () => unawaited(_load()),
                child: Text(l10n.tryAgain),
              ),
            ] else if (stats != null) ...[
              _StatCard(
                label: l10n.postedToday,
                value: '${stats.errandsPostedToday}',
                background: AppTheme.teal,
                foreground: AppTheme.white,
                onTap: () => unawaited(_open(AdminListKind.postedToday)),
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: l10n.runners,
                value: '${stats.runners}',
                detail: l10n.activeRunners(stats.activeRunners),
                background: AppTheme.copper,
                foreground: AppTheme.white,
                onTap: () => unawaited(_open(AdminListKind.runners)),
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: l10n.requesters,
                value: '${stats.requesters}',
                onTap: () => unawaited(_open(AdminListKind.requesters)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: l10n.openErrands,
                      value: '${stats.errandsOpen}',
                      onTap: () => unawaited(_open(AdminListKind.open)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: l10n.errandsUnderway,
                      value: '${stats.errandsActive}',
                      onTap: () => unawaited(_open(AdminListKind.underway)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: l10n.completedErrands,
                value: '${stats.errandsCompleted}',
                onTap: () => unawaited(_open(AdminListKind.completed)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onTap,
    this.detail,
    this.background,
    this.foreground,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? background;
  final Color? foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = this.background ?? context.colors.field;
    final foreground = this.foreground ?? context.colors.ink;
    final muted = foreground == AppTheme.white
        ? const Color(0xFFE7F3F1)
        : context.colors.muted;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: muted, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: foreground,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(
                  detail!,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _AdminSection { errands, people }

class _HubTab extends StatelessWidget {
  const new({required this.section});

  final _AdminSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errands = section == _AdminSection.errands;
    final items = errands
        ? <(String, AdminListKind)>[
            (l10n.postedToday, AdminListKind.postedToday),
            (l10n.openErrands, AdminListKind.open),
            (l10n.errandsUnderway, AdminListKind.underway),
            (l10n.completedErrands, AdminListKind.completed),
          ]
        : <(String, AdminListKind)>[
            (l10n.runners, AdminListKind.runners),
            (l10n.requesters, AdminListKind.requesters),
          ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            errands ? l10n.errands : l10n.people,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.$1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: context.colors.muted),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminListPage(kind: item.$2),
                  ),
                );
              },
            ),
            Divider(height: 1, color: context.colors.line),
          ],
        ],
      ),
    );
  }
}

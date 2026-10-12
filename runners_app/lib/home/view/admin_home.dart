import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/auth/auth.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthCubit, Object?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) return const SizedBox.shrink();
    final stats = _stats;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.teal,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  Text(
                    l10n.dashboard,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.field,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person, color: AppTheme.ink),
                  ),
                ],
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
                ),
                const SizedBox(height: 12),
                _StatCard(
                  label: l10n.runners,
                  value: '${stats.runners}',
                  detail: l10n.activeRunners(stats.activeRunners),
                  background: AppTheme.copper,
                  foreground: AppTheme.white,
                ),
                const SizedBox(height: 12),
                _StatCard(label: l10n.requesters, value: '${stats.requesters}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: l10n.openErrands,
                        value: '${stats.errandsOpen}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: l10n.errandsUnderway,
                        value: '${stats.errandsActive}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  label: l10n.completedErrands,
                  value: '${stats.errandsCompleted}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.detail,
    this.background = AppTheme.field,
    this.foreground = AppTheme.ink,
  });

  final String label;
  final String value;
  final String? detail;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final muted = foreground == AppTheme.white
        ? const Color(0xFFE7F3F1)
        : AppTheme.muted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
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
    );
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/config/app_config.dart';
import 'package:runners_app/home/cubit/dispatch_cubit.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/realtime/phoenix_channel.dart';
import 'package:runners_app/runner/cubit/presence_cubit.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/runner/data/runner_repository.dart';
import 'package:runners_app/tasks/cubit/task_board_cubit.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/create_task_page.dart';
import 'package:runners_app/tasks/view/task_detail_page.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, AppUser>(
      (cubit) => cubit.state.user!,
    );
    final token = context.read<AuthRepository>().token;
    final config = context.read<AppConfig>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = TaskBoardCubit(
              repository: context.read<TaskRepository>(),
              statusFilter: user.isRunner ? 'posted' : null,
            );
            unawaited(cubit.load());
            return cubit;
          },
        ),
        if (user.isRunner)
          BlocProvider(
            create: (_) {
              final cubit = PresenceCubit(
                repository: context.read<RunnerRepository>(),
                locations: const GeolocatorLocationSource(),
                initiallyOnline: user.runnerProfile?.isOnline ?? false,
              );
              unawaited(cubit.resumeIfOnline());
              return cubit;
            },
          ),
        if (token != null)
          BlocProvider(
            create: (_) {
              final cubit = DispatchCubit(
                socket: PhoenixChannel(uri: config.socketUri(token)),
                topic: 'task_dispatch:${user.id}',
              );
              unawaited(cubit.start());
              return cubit;
            },
          ),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthCubit, AppUser>(
      (cubit) => cubit.state.user!,
    );
    final board = context.watch<TaskBoardCubit>().state;

    final page = Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: user.isRequester
          ? FloatingActionButton.extended(
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.newErrand),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<TaskBoardCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(user.phoneNumber),
            if (user.isRunner) ...[
              const SizedBox(height: 16),
              const _PresenceCard(),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'posted', label: Text(l10n.openBoard)),
                  ButtonSegment(value: 'mine', label: Text(l10n.myTasks)),
                ],
                selected: {board.statusFilter ?? 'mine'},
                onSelectionChanged: (selection) {
                  final value = selection.first;
                  unawaited(
                    context.read<TaskBoardCubit>().changeFilter(
                      value == 'mine' ? null : value,
                    ),
                  );
                },
              ),
            ],
            if (board.message != null) ...[
              const SizedBox(height: 12),
              Text(
                board.message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            if (board.loading && board.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (board.tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.emptyTasks,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            else
              ...board.tasks.map(
                (task) => _TaskCard(
                  task: task,
                  onTap: () => _openTask(context, task),
                ),
              ),
          ],
        ),
      ),
    );
    final token = context.read<AuthRepository>().token;
    if (token == null) return page;
    return BlocListener<DispatchCubit, int>(
      listener: (context, _) => context.read<TaskBoardCubit>().load(),
      child: page,
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const CreateTaskPage()));
    if ((created ?? false) && context.mounted) {
      await context.read<TaskBoardCubit>().load();
    }
  }

  Future<void> _openTask(BuildContext context, RunnerTask task) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)));
    if (context.mounted) await context.read<TaskBoardCubit>().load();
  }
}

class _PresenceCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final presence = context.watch<PresenceCubit>().state;
    return Card(
      child: SwitchListTile(
        value: presence.online,
        activeThumbColor: AppTheme.pine,
        title: Text(presence.online ? l10n.goOnline : l10n.goOffline),
        subtitle: Text(
          presence.message ??
              (presence.online ? l10n.onlineBody : l10n.offlineBody),
        ),
        onChanged: presence.busy
            ? null
            : (value) => context.read<PresenceCubit>().setOnline(online: value),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const new({required this.task, required this.onTap});

  final RunnerTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${taskTypeLabel(l10n, task.taskType)}\n${task.dropoffAddress}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(task.estimatedCost),
            const SizedBox(height: 6),
            Text(taskStatusLabel(l10n, task.status)),
          ],
        ),
      ),
    );
  }
}

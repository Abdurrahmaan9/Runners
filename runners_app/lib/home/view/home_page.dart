import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/config/app_config.dart';
import 'package:runners_app/home/cubit/dispatch_cubit.dart';
import 'package:runners_app/home/view/settings_page.dart';
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
import 'package:runners_app/theme/errand_widgets.dart';

class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, AppUser?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) return const SizedBox.shrink();
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
    final user = context.select<AuthCubit, AppUser?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) return const SizedBox.shrink();
    final board = context.watch<TaskBoardCubit>().state;

    final page = user.isRunner
        ? _RunnerHome(
            user: user,
            board: board,
            onOpen: (task) => _openTask(context, task),
            onSettings: () => _openSettings(context),
          )
        : _RequesterHome(
            board: board,
            onCreate: () => _openCreate(context),
            onOpen: (task) => _openTask(context, task),
            onSettings: () => _openSettings(context),
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

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  Future<void> _openTask(BuildContext context, RunnerTask task) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)));
    if (context.mounted) await context.read<TaskBoardCubit>().load();
  }
}

class _RequesterHome extends StatelessWidget {
  const new({
    required this.board,
    required this.onCreate,
    required this.onOpen,
    required this.onSettings,
  });

  final TaskBoardState board;
  final VoidCallback onCreate;
  final void Function(RunnerTask task) onOpen;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = board.tasks.where((task) => !task.isTerminal).toList();
    return Scaffold(
      body: Stack(
        children: [
          const ErrandBackdrop(),
          Positioned(top: 56, left: 20, child: MapChip(l10n.lusaka)),
          Positioned(
            top: 48,
            right: 16,
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppTheme.white),
              onPressed: onSettings,
              icon: const Icon(Icons.person, color: AppTheme.ink),
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
                  Text(
                    l10n.whatNeed,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  if (active.isNotEmpty)
                    ...active
                        .take(2)
                        .map(
                          (task) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(taskStatusLabel(l10n, task.status)),
                            onTap: () => onOpen(task),
                          ),
                        ),
                  TextField(
                    readOnly: true,
                    onTap: onCreate,
                    decoration: InputDecoration(hintText: l10n.describeErrand),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final type in const [
                        'store_pickup',
                        'delivery',
                        'home_chore',
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              color: AppTheme.field,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: onCreate,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppTheme.teal,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        taskTypeLabel(l10n, type),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (board.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        board.message!,
                        style: const TextStyle(color: Color(0xFFC2413B)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunnerHome extends StatefulWidget {
  const new({
    required this.user,
    required this.board,
    required this.onOpen,
    required this.onSettings,
  });

  final AppUser user;
  final TaskBoardState board;
  final void Function(RunnerTask task) onOpen;
  final VoidCallback onSettings;

  @override
  State<_RunnerHome> createState() => _RunnerHomeState();
}

class _RunnerHomeState extends State<_RunnerHome> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = widget.board.statusFilter == 'posted';
    final tasks = widget.board.tasks;
    if (open && tasks.isNotEmpty) {
      final task = tasks[_index.clamp(0, tasks.length - 1)];
      return Scaffold(
        backgroundColor: AppTheme.copper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.newErrandNearby,
                      style: const TextStyle(
                        color: Color(0xFFFFE7D6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onSettings,
                      icon: const Icon(Icons.person, color: AppTheme.white),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: AppTheme.white),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    taskTypeLabel(l10n, task.taskType),
                    style: const TextStyle(color: AppTheme.white),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  task.pickupAddress,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  task.dropoffAddress,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.estimatedCost,
                  style: const TextStyle(color: Color(0xFFFFE7D6)),
                ),
                Text(
                  'K ${task.estimatedCost}',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.copper,
                  ),
                  onPressed: () => widget.onOpen(task),
                  child: Text(l10n.acceptErrand),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _index = (_index + 1) % tasks.length);
                    },
                    child: Text(
                      l10n.skip,
                      style: const TextStyle(color: AppTheme.white),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => unawaited(
                    context.read<TaskBoardCubit>().changeFilter(null),
                  ),
                  child: Text(
                    l10n.myTasks,
                    style: const TextStyle(color: Color(0xFFFFE7D6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final presence = context.watch<PresenceCubit>().state;
    return Scaffold(
      body: Stack(
        children: [
          const ErrandBackdrop(
            pins: [ErrandPin(color: AppTheme.teal, dy: 0.32)],
          ),
          Positioned(
            top: 56,
            left: 20,
            child: MapChip(
              presence.online ? l10n.onlineActive : l10n.goOffline,
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppTheme.white),
              onPressed: widget.onSettings,
              icon: const Icon(Icons.person, color: AppTheme.ink),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SheetCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: presence.online,
                    activeThumbColor: AppTheme.copper,
                    title: Text(
                      presence.online ? l10n.goOnline : l10n.goOffline,
                    ),
                    onChanged: presence.busy
                        ? null
                        : (value) => context.read<PresenceCubit>().setOnline(
                            online: value,
                          ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.copper,
                    ),
                    onPressed: () => unawaited(
                      context.read<TaskBoardCubit>().changeFilter('posted'),
                    ),
                    child: Text(l10n.openBoard),
                  ),
                  const SizedBox(height: 8),
                  if (tasks.isEmpty)
                    Text(l10n.emptyTasks)
                  else
                    ...tasks
                        .take(3)
                        .map(
                          (task) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(task.title),
                            subtitle: Text(taskStatusLabel(l10n, task.status)),
                            onTap: () => widget.onOpen(task),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

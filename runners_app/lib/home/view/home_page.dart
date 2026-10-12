import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/config/app_config.dart';
import 'package:runners_app/home/cubit/dispatch_cubit.dart';
import 'package:runners_app/home/view/admin_home.dart';
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
import 'package:runners_app/tasks/view/errand_card.dart';
import 'package:runners_app/tasks/view/task_detail_page.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_logo.dart';
import 'package:runners_app/theme/errand_widgets.dart';
import 'package:runners_app/theme/glass.dart';

class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, AppUser?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) return const SizedBox.shrink();
    if (user.isAdmin) return const AdminHome();
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
            onCreate: (type) => _openCreate(context, type),
            onSettings: () => _openSettings(context),
          )
        : _RequesterHome(
            board: board,
            onCreate: (type) => _openCreate(context, type),
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

  Future<void> _openCreate(BuildContext context, String? type) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateTaskPage(initialType: type),
      ),
    );
    if ((created ?? false) && context.mounted) {
      final board = context.read<TaskBoardCubit>();
      if (board.state.statusFilter != null) {
        await board.changeFilter(null);
      } else {
        await board.load();
      }
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

class _RequesterHome extends StatefulWidget {
  const new({
    required this.board,
    required this.onCreate,
    required this.onOpen,
    required this.onSettings,
  });

  final TaskBoardState board;
  final void Function(String? type) onCreate;
  final void Function(RunnerTask task) onOpen;
  final VoidCallback onSettings;

  @override
  State<_RequesterHome> createState() => _RequesterHomeState();
}

class _RequesterHomeState extends State<_RequesterHome> {
  var _showMap = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sheet = _sheet(context, l10n);
    if (!_showMap) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _toolbar(showMap: false),
              const SizedBox(height: 16),
              sheet,
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const ErrandBackdrop(),
          Positioned(
            top: 56,
            left: 20,
            child: MapChip(
              l10n.hideMap,
              onTap: () => setState(() => _showMap = false),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: GlassIconButton(
              icon: Icons.person,
              onPressed: widget.onSettings,
              size: 48,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.72,
              ),
              child: SheetCard(child: SingleChildScrollView(child: sheet)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar({required bool showMap}) {
    return Row(
      children: [
        MapChip(
          showMap ? context.l10n.hideMap : context.l10n.showMap,
          onTap: () => setState(() => _showMap = !showMap),
        ),
        const Spacer(),
        GlassIconButton(
          icon: Icons.person,
          onPressed: widget.onSettings,
          size: 48,
        ),
      ],
    );
  }

  Widget _sheet(BuildContext context, AppLocalizations l10n) {
    final active = widget.board.tasks
        .where((task) => !task.isTerminal)
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showMap)
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        const ErrandLogo(style: ErrandLogoStyle.mark, height: 28),
        const SizedBox(height: 10),
        Text(l10n.whatNeed, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final task in active.take(2)) ...[
          ErrandCard(task: task, onTap: () => widget.onOpen(task)),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: () => widget.onCreate(null),
          child: IgnorePointer(
            child: TextField(
              decoration: InputDecoration(hintText: l10n.describeErrand),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final type in const ['store_pickup', 'delivery', 'home_chore'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Glass(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => widget.onCreate(type),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.teal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            taskTypeLabel(l10n, type),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.colors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => widget.onCreate(null),
          child: Text(l10n.postErrand),
        ),
        if (widget.board.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.board.message!,
              style: const TextStyle(color: Color(0xFFC2413B)),
            ),
          ),
      ],
    );
  }
}

class _RunnerHome extends StatefulWidget {
  const new({
    required this.user,
    required this.board,
    required this.onOpen,
    required this.onCreate,
    required this.onSettings,
  });

  final AppUser user;
  final TaskBoardState board;
  final void Function(RunnerTask task) onOpen;
  final void Function(String? type) onCreate;
  final VoidCallback onSettings;

  @override
  State<_RunnerHome> createState() => _RunnerHomeState();
}

class _RunnerHomeState extends State<_RunnerHome> {
  var _index = 0;
  var _showMap = true;

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
                    const ErrandLogo(
                      style: ErrandLogoStyle.mark,
                      onBrand: true,
                      height: 28,
                    ),
                    const SizedBox(width: 10),
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
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    task.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.white, fontSize: 16),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  l10n.pickupAddress,
                  style: const TextStyle(color: Color(0xFFFFE7D6)),
                ),
                Text(
                  task.pickupAddress,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.dropoffAddress,
                  style: const TextStyle(color: Color(0xFFFFE7D6)),
                ),
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
                  onPressed: () => widget.onCreate(null),
                  child: Text(
                    l10n.postErrand,
                    style: const TextStyle(color: AppTheme.white),
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
    final sheet = _idleSheet(context, l10n, presence, tasks);
    if (!_showMap) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              MapChip(
                l10n.showMap,
                onTap: () => setState(() => _showMap = true),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GlassIconButton(
                  icon: Icons.person,
                  onPressed: widget.onSettings,
                  size: 48,
                ),
              ),
              sheet,
            ],
          ),
        ),
      );
    }

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
              l10n.hideMap,
              onTap: () => setState(() => _showMap = false),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: GlassIconButton(
              icon: Icons.person,
              onPressed: widget.onSettings,
              size: 48,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: SheetCard(child: SingleChildScrollView(child: sheet)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _idleSheet(
    BuildContext context,
    AppLocalizations l10n,
    PresenceState presence,
    List<RunnerTask> tasks,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ErrandLogo(style: ErrandLogoStyle.runner, height: 28),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: presence.online,
          activeThumbColor: AppTheme.copper,
          title: Text(presence.online ? l10n.goOffline : l10n.goOnline),
          onChanged: presence.busy
              ? null
              : (value) =>
                    context.read<PresenceCubit>().setOnline(online: value),
        ),
        FilledButton(
          onPressed: () => widget.onCreate(null),
          child: Text(l10n.postErrand),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.copper,
            side: const BorderSide(color: AppTheme.copper, width: 1.4),
          ),
          onPressed: () =>
              unawaited(context.read<TaskBoardCubit>().changeFilter('posted')),
          child: Text(l10n.openBoard),
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Text(l10n.emptyTasks)
        else
          for (final task in tasks.take(3)) ...[
            ErrandCard(task: task, onTap: () => widget.onOpen(task)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

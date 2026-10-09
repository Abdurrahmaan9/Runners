import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/config/app_config.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/realtime/phoenix_channel.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/runner/data/runner_repository.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';
import 'package:runners_app/tracking/cubit/tracking_cubit.dart';

class TrackingPage extends StatelessWidget {
  const new({required this.task, super.key});

  final RunnerTask task;

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthRepository>().token;
    final user = context.read<AuthCubit>().state.user;
    if (token == null || user == null) {
      return Scaffold(body: Center(child: Text(context.l10n.waiting)));
    }

    return BlocProvider(
      create: (_) {
        final cubit = TrackingCubit(
          socket: PhoenixChannel(
            uri: context.read<AppConfig>().socketUri(token),
          ),
          task: task,
          user: user,
          runners: context.read<RunnerRepository>(),
          locations: const GeolocatorLocationSource(),
        );
        unawaited(cubit.start());
        return cubit;
      },
      child: _TrackingView(task: task),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const new({required this.task});

  final RunnerTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (context, state) {
        final runner = state.runnerPoint;
        return Scaffold(
          body: Stack(
            children: [
              ErrandBackdrop(
                pins: [
                  const ErrandPin(color: AppTheme.teal, dx: 0.46, dy: 0.5),
                  if (runner != null)
                    const ErrandPin(color: AppTheme.copper, dx: 0.58, dy: 0.3),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8, right: 16),
                  child: Row(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
                      ),
                      const SizedBox(width: 8),
                      MapChip(
                        runner == null ? l10n.trackingWaiting : l10n.track,
                      ),
                    ],
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
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message ??
                            (runner == null
                                ? l10n.trackingWaiting
                                : '${runner.lat.toStringAsFixed(5)}, '
                                      '${runner.lng.toStringAsFixed(5)}'),
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        task.dropoffAddress,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
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
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/config/app_config.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/realtime/phoenix_channel.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/runner/data/runner_repository.dart';
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
      child: const _TrackingView(),
    );
  }
}

class _TrackingView extends StatefulWidget {
  const new();

  @override
  State<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<_TrackingView> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<TrackingCubit, TrackingState>(
      listenWhen: (previous, current) => previous.camera != current.camera,
      listener: (context, state) {
        final controller = _controller;
        if (controller == null) return;
        unawaited(
          controller.animateCamera(
            CameraUpdate.newLatLng(LatLng(state.camera.lat, state.camera.lng)),
          ),
        );
      },
      builder: (context, state) {
        final runner = state.runnerPoint;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.track)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.message ??
                      (runner == null
                          ? l10n.trackingWaiting
                          : '${runner.lat.toStringAsFixed(5)}, '
                                '${runner.lng.toStringAsFixed(5)}'),
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(state.camera.lat, state.camera.lng),
                    zoom: 14,
                  ),
                  myLocationButtonEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('dropoff'),
                      position: LatLng(
                        context.read<TrackingCubit>().dropoff.lat,
                        context.read<TrackingCubit>().dropoff.lng,
                      ),
                    ),
                    if (runner != null)
                      Marker(
                        markerId: const MarkerId('runner'),
                        position: LatLng(runner.lat, runner.lng),
                      ),
                  },
                  onMapCreated: (controller) => _controller = controller,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

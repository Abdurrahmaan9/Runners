import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/realtime/phoenix_channel.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/runner/data/runner_repository.dart';

enum TrackingPhase { connecting, live, failed }

class TrackingState extends Equatable {
  const new({
    required this.camera,
    this.runnerPoint,
    this.phase = TrackingPhase.connecting,
    this.message,
  });

  final GeoPoint camera;
  final GeoPoint? runnerPoint;
  final TrackingPhase phase;
  final String? message;

  TrackingState copyWith({
    GeoPoint? camera,
    GeoPoint? runnerPoint,
    TrackingPhase? phase,
    String? message,
    bool clearMessage = false,
  }) {
    return TrackingState(
      camera: camera ?? this.camera,
      runnerPoint: runnerPoint ?? this.runnerPoint,
      phase: phase ?? this.phase,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [camera, runnerPoint, phase, message];
}

class TrackingCubit extends Cubit<TrackingState> {
  new({
    required TaskSocket socket,
    required RunnerTask task,
    required AppUser user,
    required RunnerRepository runners,
    required LocationSource locations,
    this.interval = const Duration(seconds: 10),
  }) : _socket = socket,
       _task = task,
       _user = user,
       _runners = runners,
       _locations = locations,
       super(TrackingState(camera: task.dropoffLocation));

  final TaskSocket _socket;
  final RunnerTask _task;
  final AppUser _user;
  final RunnerRepository _runners;
  final LocationSource _locations;
  final Duration interval;
  StreamSubscription<PhoenixMessage>? _subscription;
  Timer? _timer;

  GeoPoint get dropoff => _task.dropoffLocation;

  bool get _shouldStream =>
      _task.status == 'in_progress' && _task.runnerId == _user.id;

  Future<void> start() async {
    try {
      await _socket.connectAndJoin('task_tracking:${_task.id}');
      _subscription = _socket.events.listen(_onMessage);
      if (_shouldStream) {
        await _pushLocation();
        _timer = Timer.periodic(interval, (_) => unawaited(_pushLocation()));
      }
      if (isClosed) return;
      emit(state.copyWith(phase: TrackingPhase.live, clearMessage: true));
    } on Object catch (error) {
      if (isClosed) return;
      emit(state.copyWith(phase: TrackingPhase.failed, message: '$error'));
    }
  }

  void _onMessage(PhoenixMessage message) {
    if (message.event == 'phx_reply') {
      final status = message.payload['status'];
      if (status == 'error' && !isClosed) {
        final response = message.payload['response'];
        final text = response is Map ? response['message']?.toString() : null;
        emit(
          state.copyWith(
            phase: TrackingPhase.failed,
            message: text ?? 'Could not join live tracking',
          ),
        );
      }
      return;
    }
    if (message.event != 'runner_location') return;
    final lat = message.payload['lat'];
    final lng = message.payload['lng'];
    if (lat is! num || lng is! num || isClosed) return;
    final point = GeoPoint(lat: lat.toDouble(), lng: lng.toDouble());
    emit(state.copyWith(camera: point, runnerPoint: point, clearMessage: true));
  }

  Future<void> _pushLocation() async {
    try {
      final point = await _locations.current();
      await _runners.publishLocation(point);
      _socket.push('location', point.toJson());
      if (isClosed) return;
      emit(
        state.copyWith(camera: point, runnerPoint: point, clearMessage: true),
      );
    } on Object catch (error) {
      if (isClosed) return;
      emit(state.copyWith(message: '$error'));
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _subscription?.cancel();
    await _socket.close();
    await super.close();
  }
}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/runner/data/runner_repository.dart';

class PresenceState extends Equatable {
  const new({this.online = false, this.busy = false, this.message});

  final bool online;
  final bool busy;
  final String? message;

  PresenceState copyWith({
    bool? online,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) {
    return PresenceState(
      online: online ?? this.online,
      busy: busy ?? this.busy,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [online, busy, message];
}

class PresenceCubit extends Cubit<PresenceState> {
  new({
    required RunnerRepository repository,
    required LocationSource locations,
    bool initiallyOnline = false,
    this.interval = const Duration(seconds: 10),
  }) : _repository = repository,
       _locations = locations,
       super(PresenceState(online: initiallyOnline));

  final RunnerRepository _repository;
  final LocationSource _locations;
  final Duration interval;
  Timer? _timer;

  Future<void> resumeIfOnline() async {
    if (!state.online) return;
    await _ping();
    _armTimer();
  }

  Future<void> setOnline({required bool online}) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      await _repository.setOnline(isOnline: online);
      _timer?.cancel();
      if (online) {
        await _ping();
        _armTimer();
      }
      if (isClosed) return;
      emit(state.copyWith(online: online, busy: false));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, message: error.message));
    }
  }

  Future<void> _ping() async {
    try {
      final point = await _locations.current();
      await _repository.publishLocation(point);
    } on LocationFailure catch (error) {
      if (isClosed) return;
      emit(state.copyWith(message: error.message));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(message: error.message));
    }
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(_ping()));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

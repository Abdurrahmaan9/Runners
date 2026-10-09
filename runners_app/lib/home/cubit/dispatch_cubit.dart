import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:runners_app/realtime/phoenix_channel.dart';

class DispatchCubit extends Cubit<int> {
  new({required TaskSocket socket, required String topic})
    : _socket = socket,
      _topic = topic,
      super(0);

  final TaskSocket _socket;
  final String _topic;
  StreamSubscription<PhoenixMessage>? _subscription;

  Future<void> start() async {
    try {
      await _socket.connectAndJoin(_topic);
      _subscription = _socket.events.listen((message) {
        if (message.event == 'task_posted' || message.event == 'task_updated') {
          if (!isClosed) emit(state + 1);
        }
      });
    } on Object catch (error, stackTrace) {
      log('dispatch socket failed', error: error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _socket.close();
    await super.close();
  }
}

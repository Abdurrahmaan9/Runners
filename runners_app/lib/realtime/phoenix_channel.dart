import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class PhoenixMessage {
  const new({
    required this.topic,
    required this.event,
    required this.payload,
    this.joinRef,
    this.ref,
  });

  static PhoenixMessage? decode(Object? data) {
    if (data is! String) return null;
    final decoded = jsonDecode(data);
    if (decoded is! List || decoded.length < 5) return null;
    final payload = decoded[4];
    return PhoenixMessage(
      joinRef: decoded[0]?.toString(),
      ref: decoded[1]?.toString(),
      topic: decoded[2].toString(),
      event: decoded[3].toString(),
      payload: payload is Map
          ? Map<String, dynamic>.from(payload)
          : const <String, dynamic>{},
    );
  }

  final String? joinRef;
  final String? ref;
  final String topic;
  final String event;
  final Map<String, dynamic> payload;
}

abstract interface class TaskSocket {
  Stream<PhoenixMessage> get events;

  Future<void> connectAndJoin(String topic);

  void push(String event, Map<String, dynamic> payload);

  Future<void> close();
}

class PhoenixChannel implements TaskSocket {
  new({required this.uri, WebSocketChannel Function(Uri uri)? connect})
    : _connect = connect ?? WebSocketChannel.connect;

  final Uri uri;
  final WebSocketChannel Function(Uri uri) _connect;

  final _events = StreamController<PhoenixMessage>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  String? _joinRef;
  String? _topic;
  var _ref = 0;

  @override
  Stream<PhoenixMessage> get events => _events.stream;

  @override
  Future<void> connectAndJoin(String topic) async {
    _topic = topic;
    final channel = _connect(uri);
    _channel = channel;
    await channel.ready;
    _subscription = channel.stream.listen((data) {
      final message = PhoenixMessage.decode(data);
      if (message != null && !_events.isClosed) {
        _events.add(message);
      }
    }, onError: _events.addError);
    _joinRef = _nextRef();
    _send(
      topic: topic,
      event: 'phx_join',
      payload: const {},
      joinRef: _joinRef,
      ref: _joinRef,
    );
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      _send(topic: 'phoenix', event: 'heartbeat', payload: const {});
    });
  }

  @override
  void push(String event, Map<String, dynamic> payload) {
    final topic = _topic;
    if (topic == null) return;
    _send(topic: topic, event: event, payload: payload, joinRef: _joinRef);
  }

  @override
  Future<void> close() async {
    _heartbeat?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    if (!_events.isClosed) await _events.close();
  }

  void _send({
    required String topic,
    required String event,
    required Map<String, dynamic> payload,
    String? joinRef,
    String? ref,
  }) {
    final frame = jsonEncode([
      joinRef,
      ref ?? _nextRef(),
      topic,
      event,
      payload,
    ]);
    _channel?.sink.add(frame);
  }

  String _nextRef() => '${++_ref}';
}

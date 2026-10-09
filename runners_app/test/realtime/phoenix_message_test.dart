import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_app/realtime/phoenix_channel.dart';

void main() {
  test('decodes a Phoenix V2 runner location frame', () {
    final raw = jsonEncode([
      null,
      null,
      'task_tracking:task-1',
      'runner_location',
      {'lat': -15.39, 'lng': 28.32, 'task_id': 'task-1'},
    ]);

    final message = PhoenixMessage.decode(raw);

    expect(message, isNotNull);
    expect(message!.event, 'runner_location');
    expect(message.payload['lat'], -15.39);
    expect(message.payload['lng'], 28.32);
  });
}

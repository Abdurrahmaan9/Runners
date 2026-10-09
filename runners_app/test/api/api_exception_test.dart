import 'package:flutter_test/flutter_test.dart';
import 'package:runners_app/api/api_exception.dart';

void main() {
  test('reads the API error envelope', () {
    final error = ApiException.parse({
      'error': {'code': 'NOT_FOUND', 'message': 'Task does not exist'},
    });

    expect(error.code, 'NOT_FOUND');
    expect(error.message, 'Task does not exist');
  });
}

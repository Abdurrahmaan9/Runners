import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runners_app/api/api_client.dart';
import 'package:runners_app/auth/auth.dart';

class _MemoryTokens implements TokenStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;
}

void main() {
  test('login stores the token and parses the user', () async {
    final httpClient = MockClient((request) async {
      expect(request.url.path, '/api/auth/login');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {
        'phone_number': '971000001',
        'password': 'password123',
      });
      return http.Response(
        jsonEncode({
          'data': {
            'token': 'token-1',
            'user': {
              'id': 'user-1',
              'phone_number': '+260971000001',
              'full_name': 'Amina Banda',
              'role': 'requester',
              'is_verified': false,
              'runner_profile': null,
            },
          },
        }),
        200,
      );
    });
    final api = ApiClient(
      baseUrl: 'http://127.0.0.1:4000',
      httpClient: httpClient,
    );
    final tokens = _MemoryTokens();
    final repository = AuthRepository(api: api, tokens: tokens);

    final user = await repository.login(
      phoneNumber: '971000001',
      password: 'password123',
    );

    expect(user.fullName, 'Amina Banda');
    expect(api.token, 'token-1');
    expect(await tokens.read(), 'token-1');
  });
}

import 'package:runners_app/api/api_client.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/auth/data/token_storage.dart';
import 'package:runners_app/models/app_user.dart';

class AuthRepository {
  new({required ApiClient api, required TokenStorage tokens})
    : _api = api,
      _tokens = tokens;

  final ApiClient _api;
  final TokenStorage _tokens;

  String? get token => _api.token;

  Future<AppUser?> restore() async {
    final saved = await _tokens.read();
    if (saved == null || saved.isEmpty) return null;
    _api.token = saved;
    try {
      return await me();
    } on ApiException catch (error) {
      if (error.code == 'UNAUTHORIZED') {
        await logout();
        return null;
      }
      rethrow;
    }
  }

  Future<AppUser> login(String phoneNumber) async {
    final body = await _api.post('/api/auth/login', {
      'phone_number': phoneNumber,
    });
    return await _persist(body);
  }

  Future<AppUser> register({
    required String phoneNumber,
    required String fullName,
    required String role,
  }) async {
    final body = await _api.post('/api/auth/register', {
      'phone_number': phoneNumber,
      'full_name': fullName,
      'role': role,
    });
    return await _persist(body);
  }

  Future<AppUser> me() async {
    final body = await _api.get('/api/auth/me');
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unexpected response',
      );
    }
    return AppUser.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> logout() async {
    _api.token = null;
    await _tokens.clear();
  }

  Future<AppUser> _persist(Map<String, dynamic> body) async {
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unexpected response',
      );
    }
    final json = Map<String, dynamic>.from(data);
    final token = json['token'];
    final user = json['user'];
    if (token is! String || user is! Map) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unexpected response',
      );
    }
    _api.token = token;
    await _tokens.write(token);
    return AppUser.fromJson(Map<String, dynamic>.from(user));
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:runners_app/api/api_exception.dart';

class ApiClient {
  new({required this.baseUrl, http.Client? httpClient, this.token})
    : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? token;

  Future<Map<String, dynamic>> get(String path) {
    return _complete(_http.get(_uri(path), headers: _headers));
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) {
    return _complete(
      _http.post(_uri(path), headers: _headers, body: _encode(body)),
    );
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) {
    return _complete(
      _http.patch(_uri(path), headers: _headers, body: _encode(body)),
    );
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _complete(_http.delete(_uri(path), headers: _headers));
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
    'accept': 'application/json',
    'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  String? _encode(Map<String, dynamic>? body) {
    if (body == null) return null;
    return jsonEncode(body);
  }

  Future<Map<String, dynamic>> _complete(Future<http.Response> future) async {
    final http.Response response;
    try {
      response = await future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException(
        code: 'TIMEOUT',
        message: 'The request timed out',
      );
    } on http.ClientException {
      throw const ApiException(
        code: 'NETWORK',
        message: 'Could not reach the Runners API',
      );
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 400) {
        throw ApiException(
          code: 'HTTP_${response.statusCode}',
          message: 'Request failed',
        );
      }
      return <String, dynamic>{};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server returned an unreadable response',
      );
    }

    if (response.statusCode >= 400) {
      throw ApiException.parse(decoded);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const ApiException(
      code: 'INVALID_RESPONSE',
      message: 'The server returned an unexpected response',
    );
  }
}

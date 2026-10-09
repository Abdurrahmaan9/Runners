class ApiException implements Exception {
  const new({required this.code, required this.message});

  factory parse(Object? body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        return ApiException(
          code: error['code']?.toString() ?? 'UNKNOWN',
          message: error['message']?.toString() ?? 'Request failed',
        );
      }
    }
    return const ApiException(code: 'UNKNOWN', message: 'Request failed');
  }

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

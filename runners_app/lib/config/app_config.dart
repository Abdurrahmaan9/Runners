class AppConfig {
  const new({required this.apiBaseUrl, required this.flavor});

  final String apiBaseUrl;
  final String flavor;

  Uri socketUri(String token) {
    final api = Uri.parse(apiBaseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: '/socket/websocket',
      queryParameters: {'token': token, 'vsn': '2.0.0'},
    );
  }
}

import 'dart:io';

import 'package:runners_app/app/app.dart';
import 'package:runners_app/app/app_scope.dart';
import 'package:runners_app/bootstrap.dart';
import 'package:runners_app/config/app_config.dart';

Future<void> main() async {
  const override = String.fromEnvironment('API_BASE_URL');
  final baseUrl = override.isNotEmpty
      ? override
      : Platform.isAndroid
      ? 'http://10.0.2.2:4000'
      : 'http://127.0.0.1:4000';
  final scope = AppScope.create(
    AppConfig(apiBaseUrl: baseUrl, flavor: 'development'),
  );
  await bootstrap(() => App(scope: scope));
}

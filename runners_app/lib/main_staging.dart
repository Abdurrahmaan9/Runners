import 'package:runners_app/app/app.dart';
import 'package:runners_app/app/app_scope.dart';
import 'package:runners_app/bootstrap.dart';
import 'package:runners_app/config/app_config.dart';

Future<void> main() async {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://staging.runners.example',
  );
  final scope = AppScope.create(
    const AppConfig(apiBaseUrl: baseUrl, flavor: 'staging'),
  );
  await bootstrap(() => App(scope: scope));
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/app/app_scope.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/auth/view/auth_gate.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/theme_cubit.dart';

class App extends StatelessWidget {
  const new({required this.scope, super.key});

  final AppScope scope;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: scope.config),
        RepositoryProvider.value(value: scope.authRepository),
        RepositoryProvider.value(value: scope.taskRepository),
        RepositoryProvider.value(value: scope.runnerRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) {
              final cubit = ThemeCubit(const FlutterSecureStorage());
              unawaited(cubit.restore());
              return cubit;
            },
          ),
          BlocProvider(
            create: (_) {
              final cubit = AuthCubit(scope.authRepository);
              unawaited(cubit.restore());
              return cubit;
            },
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    return MaterialApp(
      title: 'Runners',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
    );
  }
}

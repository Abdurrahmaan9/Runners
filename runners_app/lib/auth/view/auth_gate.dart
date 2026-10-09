import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/auth/view/welcome_page.dart';
import 'package:runners_app/home/view/home_page.dart';
import 'package:runners_app/l10n/l10n.dart';

class AuthGate extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthCubit, AuthStatus>(
      (cubit) => cubit.state.status,
    );
    return switch (status) {
      AuthStatus.unknown => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.l10n.waiting),
            ],
          ),
        ),
      ),
      AuthStatus.unauthenticated => const WelcomePage(),
      AuthStatus.authenticated => const HomePage(),
    };
  }
}

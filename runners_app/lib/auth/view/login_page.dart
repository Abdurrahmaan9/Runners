import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/auth/view/register_page.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  var _creatingAccount = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_creatingAccount) {
      return RegisterPage(
        onCancel: () => setState(() => _creatingAccount = false),
      );
    }

    final l10n = context.l10n;
    final submitting = context.select<AuthCubit, bool>(
      (cubit) => cubit.state.submitting,
    );
    final message = context.select<AuthCubit, String?>(
      (cubit) => cubit.state.message,
    );

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          const _BrandHeader(),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneNumber,
              hintText: l10n.phoneHint,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: submitting
                ? null
                : () => context.read<AuthCubit>().login(_phone.text),
            child: submitting
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.signIn),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _creatingAccount = true),
            child: Text(l10n.needAccount),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.fromLTRB(0, 72, 0, 28),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 42, height: 6, color: AppTheme.amber),
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(color: AppTheme.ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(l10n.tagline, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

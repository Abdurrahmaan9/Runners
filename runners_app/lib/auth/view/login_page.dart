import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/auth/view/forgot_password_page.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';

class LoginPage extends StatefulWidget {
  const new({required this.onCreate, required this.onBack, super.key});

  final VoidCallback onCreate;
  final VoidCallback onBack;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;
  var _forgot = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_forgot) {
      return ForgotPasswordPage(onBack: () => setState(() => _forgot = false));
    }
    final l10n = context.l10n;
    final submitting = context.select<AuthCubit, bool>(
      (cubit) => cubit.state.submitting,
    );
    final message = context.select<AuthCubit, String?>(
      (cubit) => cubit.state.message,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackDot(onPressed: widget.onBack),
              const SizedBox(height: 28),
              Text(
                l10n.welcomeBack,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.loginLead),
              const SizedBox(height: 28),
              FieldCaption(l10n.phoneNumber),
              PhoneNumberField(controller: _phone),
              const SizedBox(height: 18),
              FieldCaption(l10n.password),
              TextField(
                controller: _password,
                obscureText: _obscure,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
                decoration: InputDecoration(
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    child: Text(
                      _obscure ? l10n.showPassword : l10n.hidePassword,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _forgot = true),
                  child: Text(l10n.forgotPassword),
                ),
              ),
              if (message != null)
                Text(message, style: const TextStyle(color: Color(0xFFC2413B))),
              const Spacer(),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () => context.read<AuthCubit>().login(
                        phoneNumber: _phone.text,
                        password: _password.text,
                      ),
                child: Text(l10n.signIn),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: widget.onCreate,
                  child: Text('${l10n.newHere} ${l10n.createAccount}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackDot extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.mist,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.arrow_back, color: AppTheme.ink),
        ),
      ),
    );
  }
}

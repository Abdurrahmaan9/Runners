import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';

class RegisterPage extends StatefulWidget {
  const new({
    required this.onCancel,
    required this.onLogin,
    super.key,
  });

  final VoidCallback onCancel;
  final VoidCallback onLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  var _step = 0;
  var _role = 'requester';
  var _obscure = true;
  String? _localError;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _longEnough => _password.text.trim().length >= 8;

  bool get _mixed {
    final value = _password.text;
    return RegExp('[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);
  }

  void _next() {
    final l10n = context.l10n;
    if (_step == 1) {
      if (!_longEnough || !_mixed) return;
      if (_password.text != _confirm.text) {
        setState(() => _localError = l10n.passwordMismatch);
        return;
      }
    }
    setState(() {
      _localError = null;
      _step += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = _role == 'runner' ? AppTheme.copper : AppTheme.teal;
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
              _dot(
                onTap: _step == 0
                    ? widget.onCancel
                    : () => setState(() => _step -= 1),
              ),
              const SizedBox(height: 24),
              Expanded(child: _body(l10n, accent, message)),
              if (_step < 2)
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: _step == 0 ? _next : _next,
                  child: Text(l10n.continueAction),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: submitting || _name.text.trim().length < 2
                      ? null
                      : () => context.read<AuthCubit>().register(
                          phoneNumber: _phone.text,
                          password: _password.text,
                          fullName: _name.text,
                          role: _role,
                        ),
                  child: Text(l10n.createAccount),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, Color accent, String? message) {
    return switch (_step) {
      0 => _roleStep(l10n),
      1 => _passwordStep(l10n, accent),
      _ => _profileStep(l10n, accent, message),
    };
  }

  Widget _roleStep(AppLocalizations l10n) {
    return ListView(
      children: [
        Text(
          l10n.appTitle,
          style: const TextStyle(
            color: AppTheme.teal,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.chooseRoleTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.chooseRoleLead),
        const SizedBox(height: 24),
        _RoleCard(
          selected: _role == 'requester',
          color: AppTheme.teal,
          title: l10n.needErrand,
          body: l10n.needErrandBody,
          onTap: () => setState(() => _role = 'requester'),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          selected: _role == 'runner',
          color: AppTheme.copper,
          title: l10n.earnRunner,
          body: l10n.earnRunnerBody,
          onTap: () => setState(() => _role = 'runner'),
        ),
      ],
    );
  }

  Widget _passwordStep(AppLocalizations l10n, Color accent) {
    return ListView(
      children: [
        Text(
          l10n.signupTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.signupLead),
        const SizedBox(height: 24),
        FieldCaption(l10n.phoneNumber),
        PhoneNumberField(controller: _phone, accent: accent),
        const SizedBox(height: 18),
        FieldCaption(l10n.createPassword),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            suffixIcon: TextButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              child: Text(_obscure ? l10n.showPassword : l10n.hidePassword),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _Rule(met: _longEnough, label: l10n.ruleLength),
        _Rule(met: _mixed, label: l10n.ruleMix),
        const SizedBox(height: 12),
        FieldCaption(l10n.confirmPassword),
        TextField(
          controller: _confirm,
          obscureText: _obscure,
          onChanged: (_) => setState(() => _localError = null),
        ),
        if (_localError != null) ...[
          const SizedBox(height: 8),
          Text(_localError!, style: const TextStyle(color: Color(0xFFC2413B))),
        ],
      ],
    );
  }

  Widget _profileStep(AppLocalizations l10n, Color accent, String? message) {
    return ListView(
      children: [
        Text(
          l10n.profileTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.profileLead),
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 18),
        FieldCaption(l10n.fullName),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _role == 'runner' ? l10n.runner : l10n.requesterAccount,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFFC2413B))),
        ],
        const SizedBox(height: 12),
        TextButton(onPressed: widget.onLogin, child: Text(l10n.signIn)),
      ],
    );
  }

  Widget _dot({required VoidCallback onTap}) {
    return Material(
      color: AppTheme.mist,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.arrow_back, color: AppTheme.ink),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const new({
    required this.selected,
    required this.color,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final Color color;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.field,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(body, style: const TextStyle(color: AppTheme.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const new({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: met ? AppTheme.teal : AppTheme.line,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.ink)),
        ],
      ),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/l10n/l10n.dart';

class RegisterPage extends StatefulWidget {
  const new({required this.onCancel, super.key});

  final VoidCallback onCancel;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  var _role = 'requester';

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submitting = context.select<AuthCubit, bool>(
      (cubit) => cubit.state.submitting,
    );
    final message = context.select<AuthCubit, String?>(
      (cubit) => cubit.state.message,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createAccount),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.fullName),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneNumber,
              hintText: l10n.phoneHint,
              prefixText: '+260 ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.password),
          ),
          const SizedBox(height: 16),
          Text(l10n.role, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'requester', label: Text(l10n.requester)),
              ButtonSegment(value: 'runner', label: Text(l10n.runner)),
            ],
            selected: {_role},
            onSelectionChanged: (selection) {
              setState(() => _role = selection.first);
            },
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
                : () => context.read<AuthCubit>().register(
                    phoneNumber: _phone.text,
                    password: _password.text,
                    fullName: _name.text,
                    role: _role,
                  ),
            child: Text(submitting ? l10n.waiting : l10n.createAccount),
          ),
        ],
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/errand_widgets.dart';
import 'package:runners_app/theme/glass.dart';

class ForgotPasswordPage extends StatefulWidget {
  const new({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phone = TextEditingController();
  String? _note;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassIconButton(icon: Icons.arrow_back, onPressed: widget.onBack),
              const SizedBox(height: 28),
              Text(
                l10n.resetTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.resetLead),
              const SizedBox(height: 28),
              FieldCaption(l10n.phoneNumber),
              PhoneNumberField(controller: _phone),
              if (_note != null) ...[
                const SizedBox(height: 16),
                Text(_note!, style: const TextStyle(color: Color(0xFFC2413B))),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () => setState(() => _note = l10n.resetUnavailable),
                child: Text(l10n.sendReset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

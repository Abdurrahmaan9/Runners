import 'package:material_ui/material_ui.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/glass.dart';

class PhoneNumberField extends StatelessWidget {
  const new({required this.controller, super.key, this.accent = AppTheme.teal});

  final TextEditingController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Glass(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 58,
            child: Center(
              child: Text(
                '+260',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: context.colors.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: context.colors.ink,
            ),
            decoration: InputDecoration(
              hintText: '97 123 4567',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accent, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FieldCaption extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: context.colors.muted,
        ),
      ),
    );
  }
}

class SheetCard extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class MapChip extends StatelessWidget {
  const new(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.colors.ink,
        ),
      ),
    );
  }
}

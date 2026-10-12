import 'package:material_ui/material_ui.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/glass.dart';

class SupportPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.support)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l10n.supportLead,
            style: TextStyle(color: context.colors.muted, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _Topic(title: l10n.supportPostTitle, body: l10n.supportPostBody),
          _Topic(title: l10n.supportRunTitle, body: l10n.supportRunBody),
          _Topic(title: l10n.supportSafetyTitle, body: l10n.supportSafetyBody),
          _Topic(title: l10n.supportPayTitle, body: l10n.supportPayBody),
        ],
      ),
    );
  }
}

class _Topic extends StatelessWidget {
  const new({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glass(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: context.colors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(color: context.colors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

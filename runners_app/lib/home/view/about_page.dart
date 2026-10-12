import 'package:material_ui/material_ui.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';

class AboutPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutUs)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              color: AppTheme.teal,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.aboutLead,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: AppTheme.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.aboutBody,
            style: TextStyle(
              color: context.colors.ink,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.aboutHow,
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerLeft, child: MapChip(l10n.lusaka)),
        ],
      ),
    );
  }
}

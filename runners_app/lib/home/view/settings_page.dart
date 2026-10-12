import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/home/view/about_page.dart';
import 'package:runners_app/home/view/support_page.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/tasks/view/errand_history_page.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_logo.dart';
import 'package:runners_app/theme/glass.dart';
import 'package:runners_app/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthCubit, AppUser?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
      return const Scaffold();
    }
    final accent = switch (user.role) {
      'runner' => AppTheme.copper,
      'admin' => AppTheme.tealDeep,
      _ => AppTheme.teal,
    };
    final roleLabel = switch (user.role) {
      'runner' => l10n.verifiedRunner,
      'admin' => l10n.admin,
      _ => l10n.requester,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Glass(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accent,
                  child: const ErrandLogo(
                    style: ErrandLogoStyle.mark,
                    onBrand: true,
                    height: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: context.colors.ink,
                        ),
                      ),
                      Text(
                        user.phoneNumber,
                        style: TextStyle(color: context.colors.muted),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _SettingsLink(
                  label: l10n.errandHistory,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ErrandHistoryPage(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: context.colors.line),
                _SettingsLink(
                  label: l10n.support,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SupportPage(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: context.colors.line),
                _SettingsLink(
                  label: l10n.aboutUs,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutPage(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: context.colors.line),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.darkMode,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.colors.ink,
                    ),
                  ),
                  value: context.watch<ThemeCubit>().state == ThemeMode.dark,
                  activeThumbColor: AppTheme.teal,
                  onChanged: (enabled) {
                    unawaited(
                      context.read<ThemeCubit>().setDark(enabled: enabled),
                    );
                  },
                ),
                Divider(height: 1, color: context.colors.line),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.signOut,
                    style: const TextStyle(
                      color: Color(0xFFC2413B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFC2413B),
                  ),
                  onTap: () {
                    final cubit = context.read<AuthCubit>();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    unawaited(cubit.logout());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.colors.ink,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: context.colors.muted),
      onTap: onTap,
    );
  }
}

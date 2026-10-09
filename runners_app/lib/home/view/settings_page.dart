import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthCubit, AppUser?>(
      (cubit) => cubit.state.user,
    );
    if (user == null) return const SizedBox.shrink();
    final accent = user.isRunner ? AppTheme.copper : AppTheme.teal;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.mist,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 26, backgroundColor: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        user.phoneNumber,
                        style: const TextStyle(color: AppTheme.muted),
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
                          user.isRunner ? l10n.verifiedRunner : l10n.requester,
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.signOut,
              style: const TextStyle(
                color: Color(0xFFC2413B),
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFC2413B)),
            onTap: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
    );
  }
}

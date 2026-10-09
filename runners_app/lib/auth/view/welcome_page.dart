import 'package:material_ui/material_ui.dart';
import 'package:runners_app/auth/view/login_page.dart';
import 'package:runners_app/auth/view/register_page.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/theme/app_theme.dart';

class WelcomePage extends StatefulWidget {
  const new({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  _Screen _screen = _Screen.landing;

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      _Screen.landing => _Landing(
        onCreate: () => setState(() => _screen = _Screen.register),
        onLogin: () => setState(() => _screen = _Screen.login),
      ),
      _Screen.login => LoginPage(
        onCreate: () => setState(() => _screen = _Screen.register),
        onBack: () => setState(() => _screen = _Screen.landing),
      ),
      _Screen.register => RegisterPage(
        onCancel: () => setState(() => _screen = _Screen.landing),
        onLogin: () => setState(() => _screen = _Screen.login),
      ),
    };
  }
}

enum _Screen { landing, login, register }

class _Landing extends StatelessWidget {
  const new({required this.onCreate, required this.onLogin});

  final VoidCallback onCreate;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Column(
        children: [
          const _Hero(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              children: [
                _Feature(
                  color: AppTheme.teal,
                  title: l10n.postFast,
                  body: l10n.postFastBody,
                ),
                _Feature(
                  color: AppTheme.teal,
                  title: l10n.trackLive,
                  body: l10n.trackLiveBody,
                ),
                _Feature(
                  color: AppTheme.copper,
                  title: l10n.earnTitle,
                  body: l10n.earnBody,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              children: [
                FilledButton(
                  onPressed: onCreate,
                  child: Text(l10n.createAccount),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onLogin, child: Text(l10n.signIn)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      decoration: const BoxDecoration(
        color: AppTheme.teal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: 10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                l10n.tagline,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: AppTheme.white),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.welcomeBody,
                style: const TextStyle(
                  color: Color(0xFFD7EBE7),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const new({
    required this.color,
    required this.title,
    required this.body,
  });

  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.ink,
                  ),
                ),
                Text(body, style: const TextStyle(color: AppTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

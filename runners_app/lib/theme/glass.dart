import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class LiquidWash extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _WashPainter(dark: dark),
      child: const SizedBox.expand(),
    );
  }
}

class _WashPainter extends CustomPainter {
  const new({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0xFF0B1210) : const Color(0xFFD7E8E2),
    );
    _blob(
      canvas,
      Offset(size.width * 0.12, size.height * 0.06),
      size.width * 0.72,
      (dark ? const Color(0xFF1FA79C) : const Color(0xFF7ED4CB)).withValues(
        alpha: dark ? 0.42 : 0.62,
      ),
    );
    _blob(
      canvas,
      Offset(size.width * 0.92, size.height * 0.38),
      size.width * 0.58,
      (dark ? const Color(0xFFC4622A) : const Color(0xFFF3B48A)).withValues(
        alpha: dark ? 0.3 : 0.48,
      ),
    );
    _blob(
      canvas,
      Offset(size.width * 0.35, size.height * 0.96),
      size.width * 0.85,
      (dark ? const Color(0xFF16302B) : const Color(0xFFFFFFFF)).withValues(
        alpha: dark ? 0.7 : 0.75,
      ),
    );
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _WashPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class Glass extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xB315211C) : const Color(0xC7FFFFFF);
    final edge =
        borderColor ??
        (dark ? const Color(0x40FFFFFF) : const Color(0xF2FFFFFF));
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Color(dark ? 0x59000000 : 0x1A0C1F1A),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: dark ? 0.12 : 0.34),
                    fill,
                  ),
                  fill,
                ],
              ),
              border: Border.all(color: edge),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Stack(
                  children: [
                    const Positioned(top: -36, left: -24, child: _Sheen()),
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: dark ? 0.5 : 0.95),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    content,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sheen extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Container(
        width: 140,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: dark ? 0.16 : 0.5),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: BorderRadius.circular(size / 2),
      onTap: onPressed,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

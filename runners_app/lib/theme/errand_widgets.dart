import 'package:material_ui/material_ui.dart';
import 'package:runners_app/theme/app_theme.dart';

class ErrandPin {
  const new({required this.color, this.dx = 0.5, this.dy = 0.42});

  final Color color;
  final double dx;
  final double dy;
}

class ErrandBackdrop extends StatelessWidget {
  const new({super.key, this.pins = const [ErrandPin(color: AppTheme.teal)]});

  final List<ErrandPin> pins;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(pins),
      child: const SizedBox.expand(),
    );
  }
}

class _MapPainter extends CustomPainter {
  const new(this.pins);

  final List<ErrandPin> pins;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE7EEEA),
    );
    final block = Paint()..color = const Color(0xFFD5E3DC);
    final road = Paint()
      ..color = const Color(0xFFF7FBF8)
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.square;
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.58, size.height * 0.46),
          width: size.width * 0.34,
          height: size.height * 0.28,
        ),
        const Radius.circular(18),
      ),
      block,
    );
    for (final pin in pins) {
      final center = Offset(size.width * pin.dx, size.height * pin.dy);
      canvas
        ..drawCircle(center, 16, Paint()..color = AppTheme.white)
        ..drawCircle(center, 11, Paint()..color = pin.color);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.pins != pins;
}

class PhoneNumberField extends StatelessWidget {
  const new({required this.controller, super.key, this.accent = AppTheme.teal});

  final TextEditingController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.field,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '+260',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.ink,
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
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: AppTheme.muted,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MapChip extends StatelessWidget {
  const new(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

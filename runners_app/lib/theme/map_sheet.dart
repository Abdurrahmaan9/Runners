import 'package:material_ui/material_ui.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/glass.dart';

class MapSheet extends StatefulWidget {
  const new({required this.map, required this.child, super.key});

  final Widget map;
  final Widget child;

  @override
  State<MapSheet> createState() => _MapSheetState();
}

class _MapSheetState extends State<MapSheet> {
  double _sheet = 1 / 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final sheetHeight = _sheetHeight(height);
        return Column(
          children: [
            Expanded(child: widget.map),
            SizedBox(
              height: sheetHeight,
              child: Glass(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) =>
                          _drag(details.delta.dy, height),
                      child: SizedBox(
                        height: 28,
                        width: double.infinity,
                        child: Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.colors.line,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        children: [widget.child],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _drag(double delta, double height) {
    if (height <= 0) return;
    setState(() {
      _sheet = (_sheet - delta / height).clamp(0.14, 0.78);
    });
  }

  double _sheetHeight(double height) {
    if (height <= 0) return 0;
    final maxSheet = height * 0.78;
    final minSheet = height * 0.14;
    final wanted = height * _sheet;
    if (wanted < minSheet) return minSheet;
    if (wanted > maxSheet) return maxSheet;
    return wanted;
  }
}

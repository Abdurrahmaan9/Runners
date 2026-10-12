import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:runners_app/home/view/admin_list_page.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/heatmap.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/glass.dart';

class ActivityHeatmap extends StatelessWidget {
  const new({required this.heatmap, super.key});

  final ErrandHeatmap heatmap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final peak = heatmap.cells.fold<int>(
      0,
      (max, cell) => cell.count > max ? cell.count : max,
    );

    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activityMap,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(l10n.lusaka, style: TextStyle(color: context.colors.muted)),
          const SizedBox(height: 14),
          SizedBox(
            height: 168,
            width: double.infinity,
            child: CustomPaint(
              painter: _HeatPainter(
                rows: heatmap.rows,
                cols: heatmap.cols,
                cells: heatmap.cells,
                empty: context.colors.field,
                hot: AppTheme.copper,
                warm: AppTheme.teal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (peak == 0)
            Text(l10n.heatEmpty, style: TextStyle(color: context.colors.muted))
          else
            Row(
              children: [
                Text(
                  l10n.quiet,
                  style: TextStyle(color: context.colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [AppTheme.teal, AppTheme.copper],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.busy,
                  style: TextStyle(color: context.colors.muted, fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  const new({
    required this.rows,
    required this.cols,
    required this.cells,
    required this.empty,
    required this.warm,
    required this.hot,
  });

  final int rows;
  final int cols;
  final List<HeatCell> cells;
  final Color empty;
  final Color warm;
  final Color hot;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows < 1 || cols < 1) return;
    final counts = <(int, int), int>{
      for (final cell in cells) (cell.row, cell.col): cell.count,
    };
    final peak = counts.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
    const gap = 4.0;
    final cellWidth = (size.width - gap * (cols - 1)) / cols;
    final cellHeight = (size.height - gap * (rows - 1)) / rows;

    for (var row = 1; row <= rows; row++) {
      for (var col = 1; col <= cols; col++) {
        final count = counts[(row, col)] ?? 0;
        final t = peak == 0 ? 0.0 : count / peak;
        final color = count == 0
            ? empty
            : Color.lerp(warm, hot, t)!.withValues(alpha: 0.45 + (0.55 * t));
        final top = (rows - row) * (cellHeight + gap);
        final left = (col - 1) * (cellWidth + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, cellWidth, cellHeight),
            const Radius.circular(6),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatPainter oldDelegate) =>
      oldDelegate.cells != cells ||
      oldDelegate.empty != empty ||
      oldDelegate.rows != rows ||
      oldDelegate.cols != cols;
}

class ErrandStatusChart extends StatelessWidget {
  const new({
    required this.open,
    required this.underway,
    required this.completed,
    required this.onOpen,
    super.key,
  });

  final int open;
  final int underway;
  final int completed;
  final ValueChanged<AdminListKind> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slices = [
      (l10n.openErrands, open, AppTheme.teal, AdminListKind.open),
      (l10n.errandsUnderway, underway, AppTheme.copper, AdminListKind.underway),
      (
        l10n.completedErrands,
        completed,
        AppTheme.tealDeep,
        AdminListKind.completed,
      ),
    ];

    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statusChart,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: CustomPaint(
                  painter: _PiePainter(
                    counts: [open, underway, completed],
                    colors: const [
                      AppTheme.teal,
                      AppTheme.copper,
                      AppTheme.tealDeep,
                    ],
                    empty: context.colors.field,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final slice in slices)
                      _SliceKey(
                        label: slice.$1,
                        count: slice.$2,
                        color: slice.$3,
                        onTap: () => onOpen(slice.$4),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  const new({required this.counts, required this.colors, required this.empty});

  final List<int> counts;
  final List<Color> colors;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final total = counts.fold<int>(0, (sum, count) => sum + count);
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.shortestSide / 2,
    );
    if (total == 0) {
      canvas.drawCircle(rect.center, rect.width / 2, Paint()..color = empty);
      return;
    }

    var start = -math.pi / 2;
    for (var i = 0; i < counts.length; i++) {
      final sweep = counts[i] / total * math.pi * 2;
      if (sweep == 0) continue;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.counts != counts || oldDelegate.empty != empty;
}

class _SliceKey extends StatelessWidget {
  const new({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: context.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

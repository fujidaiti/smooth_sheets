import 'package:flutter/material.dart';

import 'model.dart';
import 'model_owner.dart';

/// An animated drag handle for a `Sheet`.
///
/// The handle morphs continuously between a downward chevron (hinting the sheet
/// can be pulled down) and a flat horizontal bar, driven by the sheet position:
/// it renders a chevron when the sheet sits at [from] and a bar when it reaches
/// [to], interpolating in between.
///
/// When placed inside a `Sheet` it reads the sheet position automatically. If
/// no sheet is found in the ancestry it falls back to rendering a static bar.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({
    super.key,
    this.from,
    this.to,
    this.width = 42,
    this.height = 18,
    this.color = const Color(0xFFD6D6D6),
    this.strokeWidth = 4,
  });

  /// The sheet position at which the handle renders a downward chevron
  /// (progress `0.0`). Defaults to the sheet's minimum (collapsed) position.
  final SheetOffset? from;

  /// The sheet position at which the handle renders a flat bar (progress
  /// `1.0`). Defaults to the sheet's maximum (expanded) position.
  final SheetOffset? to;

  /// The width of the handle's paint box, in logical pixels.
  final double width;

  /// The height of the handle's paint box, in logical pixels.
  final double height;

  /// The stroke color of the handle.
  final Color color;

  /// The thickness of the drawn line, in logical pixels.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final model = SheetModelOwner.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        // The progress is read from the model at paint time (after layout, when
        // the metrics are ready) and repainting is driven by the model's rect
        // notifier — the model does not notify its main listeners on offset
        // changes, so a ListenableBuilder would never update.
        painter: _SheetDragHandlePainter(
          model: model,
          from: from,
          to: to,
          color: color,
          strokeWidth: strokeWidth,
          repaint: model == null ? null : _SheetRectListenable(model),
        ),
      ),
    );
  }
}

/// Adapts a [SheetModel]'s rect notifications into a [Listenable] that a
/// [CustomPainter] can repaint from.
class _SheetRectListenable extends Listenable {
  _SheetRectListenable(this.model);

  final SheetModel model;

  @override
  void addListener(VoidCallback listener) => model.addRectListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      model.removeRectListener(listener);
}

class _SheetDragHandlePainter extends CustomPainter {
  _SheetDragHandlePainter({
    required this.model,
    required this.from,
    required this.to,
    required this.color,
    required this.strokeWidth,
    required super.repaint,
  });

  final SheetModel? model;
  final SheetOffset? from;
  final SheetOffset? to;
  final Color color;
  final double strokeWidth;

  /// The morph amount in `0.0..1.0` (chevron..bar), computed from the current
  /// sheet position. Exposed for testing.
  @visibleForTesting
  double get progress {
    final model = this.model;
    if (model == null || !model.hasMetrics) return 1;
    final fromPx = from?.resolve(model) ?? model.minOffset;
    final toPx = to?.resolve(model) ?? model.maxOffset;
    if (toPx <= fromPx) return 1;
    return ((model.offset - fromPx) / (toPx - fromPx)).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final progress = this.progress;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final centerX = size.width / 2;
    final half = size.width * 0.28;

    // The outer points drop below the center at progress 0 (chevron) and align
    // with it at progress 1 (flat bar).
    final arrowDepth = size.height * 0.12 * (1 - progress);

    final leftStart = Offset(centerX - half, centerY + arrowDepth);
    final center = Offset(centerX, centerY - arrowDepth);
    final rightEnd = Offset(centerX + half, centerY + arrowDepth);

    canvas.drawLine(leftStart, center, paint);
    canvas.drawLine(center, rightEnd, paint);
  }

  @override
  bool shouldRepaint(covariant _SheetDragHandlePainter oldDelegate) {
    return oldDelegate.model != model ||
        oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

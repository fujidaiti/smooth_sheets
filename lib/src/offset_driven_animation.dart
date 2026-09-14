import 'package:flutter/animation.dart';

import 'controller.dart';
import 'model.dart';

/// An [Animation] whose value tracks the position of a sheet.
///
/// The animation value is `0.0` when the sheet is at [startOffset] and `1.0`
/// when it is at [endOffset]. When the sheet is between these two offsets, the
/// value is interpolated linearly.
///
/// If [startOffset] is `null`, [SheetMetrics.minOffset] is used as the start.
/// If [endOffset] is `null`, [SheetMetrics.maxOffset] is used as the end.
///
/// [initialValue] is returned before the [SheetController] has a client (i.e.,
/// before the sheet is laid out).
///
/// ```dart
/// final animation = SheetOffsetDrivenAnimation(
///   controller: sheetController,
///   initialValue: 0.0,
///   startOffset: SheetOffset(0.5),
///   endOffset: SheetOffset(1.0),
/// );
/// // Use `animation` with FadeTransition, AnimatedBuilder, etc.
/// ```
class SheetOffsetDrivenAnimation extends Animation<double> {
  SheetOffsetDrivenAnimation({
    required SheetController controller,
    required this.initialValue,
    this.startOffset,
    this.endOffset,
  }) : _controller = controller,
       assert(initialValue >= 0.0 && initialValue <= 1.0);

  final SheetController _controller;

  /// The animation value returned before the sheet is laid out.
  final double initialValue;

  /// The sheet offset that corresponds to animation value `0.0`.
  ///
  /// Defaults to [SheetMetrics.minOffset] when `null`.
  final SheetOffset? startOffset;

  /// The sheet offset that corresponds to animation value `1.0`.
  ///
  /// Defaults to [SheetMetrics.maxOffset] when `null`.
  final SheetOffset? endOffset;

  @override
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    // The status will never change.
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    // The status will never change.
  }

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  double get value {
    final metrics = _controller.metrics;
    if (metrics == null) {
      return initialValue;
    }

    final startOffset = this.startOffset?.resolve(metrics) ?? metrics.minOffset;
    final endOffset = this.endOffset?.resolve(metrics) ?? metrics.maxOffset;
    final distance = endOffset - startOffset;

    if (distance.isFinite && distance > 0) {
      return ((metrics.offset - startOffset) / distance).clamp(0, 1);
    }

    return 1;
  }
}

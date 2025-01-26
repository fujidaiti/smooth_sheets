import 'package:flutter/animation.dart';

import 'sheet_controller.dart';
import 'sheet_position.dart';

class SheetPositionDrivenAnimation extends Animation<double> {
  SheetPositionDrivenAnimation({
    required SheetController controller,
    required this.initialValue,
    this.startPosition,
    this.endPosition,
  })  : _controller = controller,
        assert(initialValue >= 0.0 && initialValue <= 1.0);

  final SheetController _controller;
  final double initialValue;
  final SheetOffset? startPosition;
  final SheetOffset? endPosition;

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

    final startPixels =
        startPosition?.resolve(metrics.measurements) ?? metrics.minOffset;
    final endPixels =
        endPosition?.resolve(metrics.measurements) ?? metrics.maxOffset;
    final distance = endPixels - startPixels;

    if (distance.isFinite && distance > 0) {
      return ((metrics.offset - startPixels) / distance).clamp(0, 1);
    }

    return 1;
  }
}

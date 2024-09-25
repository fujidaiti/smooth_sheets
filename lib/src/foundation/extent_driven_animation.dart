import 'package:flutter/animation.dart';

import 'sheet_controller.dart';
import 'sheet_position.dart';

class ExtentDrivenAnimation extends Animation<double> {
  ExtentDrivenAnimation({
    required SheetController controller,
    required this.initialValue,
    this.startExtent,
    this.endExtent,
  })  : _controller = controller,
        assert(initialValue >= 0.0 && initialValue <= 1.0);

  final SheetController _controller;
  final double initialValue;
  final Extent? startExtent;
  final Extent? endExtent;

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
    if (!metrics.hasDimensions) {
      return initialValue;
    }

    final startPixels =
        startExtent?.resolve(metrics.contentSize) ?? metrics.minPixels;
    final endPixels =
        endExtent?.resolve(metrics.contentSize) ?? metrics.maxPixels;
    final distance = endPixels - startPixels;

    if (distance.isFinite && distance > 0) {
      return ((metrics.pixels - startPixels) / distance).clamp(0, 1);
    }

    return 1;
  }
}

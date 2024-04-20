import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../internal/double_utils.dart';
import 'sheet_extent.dart';

/// The default [SpringDescription] used by [SheetPhysics] subclasses.
///
/// This spring has the same configuration as the resulting spring
/// from the [SpringDescription.withDampingRatio] constructor with
/// a ratio of `1.1`, a mass of `0.5`, and a stiffness of `100.0`.
const kDefaultSheetSpring = SpringDescription(
  mass: 0.5,
  stiffness: 100.0,
  // Use a pre-calculated value to define the spring as a const variable.
  // See the implementation of withDampingRatio() for the formula.
  damping: 15.5563491861,
);

const _minSettlingDuration = Duration(milliseconds: 160);
const _defaultSettlingSpeed = 600.0; // logical pixels per second

abstract class SheetPhysics {
  const SheetPhysics({this.parent});

  final SheetPhysics? parent;

  /// Create a copy of this object appending the [ancestor] to
  /// the physics chain, much like [ScrollPhysics.applyTo].
  ///
  /// Can be used to dynamically create an inheritance relationship
  /// between [SheetPhysics] objects. For example, [SheetPhysics] `x`
  /// and `y` in the following code will have the same behavior.
  /// ```dart
  /// final x = FooSheetPhysics().applyTo(BarSheetPhysics());
  /// final y = FooSheetPhysics(parent: BarSheetPhysics());
  /// ```
  SheetPhysics applyTo(SheetPhysics ancestor) {
    return copyWith(parent: parent?.applyTo(ancestor) ?? ancestor);
  }

  /// Create a copy of this object with the given fields replaced
  /// by the new values.
  SheetPhysics copyWith({SheetPhysics? parent, SpringDescription? spring});

  double computeOverflow(double offset, SheetMetrics metrics);

  double applyPhysicsToOffset(double offset, SheetMetrics metrics);

  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics);

  Simulation? createSettlingSimulation(SheetMetrics metrics);
}

mixin SheetPhysicsMixin on SheetPhysics {
  SpringDescription get spring => kDefaultSheetSpring;

  @override
  double computeOverflow(double offset, SheetMetrics metrics) {
    if (parent case final parent?) {
      return parent.computeOverflow(offset, metrics);
    }

    final newPixels = metrics.pixels + offset;
    if (newPixels > metrics.maxPixels) {
      return min(newPixels - metrics.maxPixels, offset);
    } else if (newPixels < metrics.minPixels) {
      return max(newPixels - metrics.minPixels, offset);
    } else {
      return 0;
    }
  }

  @override
  double applyPhysicsToOffset(double offset, SheetMetrics metrics) {
    if (parent case final parent?) {
      return parent.applyPhysicsToOffset(offset, metrics);
    } else if (offset > 0 && metrics.pixels < metrics.maxPixels) {
      // Prevent the pixels from going beyond the maximum value.
      return min(metrics.maxPixels, metrics.pixels + offset) - metrics.pixels;
    } else if (offset < 0 && metrics.pixels > metrics.minPixels) {
      // Prevent the pixels from going beyond the minimum value.
      return max(metrics.minPixels, metrics.pixels + offset) - metrics.pixels;
    } else {
      return 0;
    }
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics) {
    if (parent case final parent?) {
      return parent.createBallisticSimulation(velocity, metrics);
    } else if (metrics.isPixelsInBounds) {
      return null;
    }

    final destination =
        metrics.pixels.nearest(metrics.minPixels, metrics.maxPixels);
    final direction = (destination - metrics.pixels).sign;

    return ScrollSpringSimulation(
      spring,
      metrics.pixels,
      destination,
      // The simulation velocity is intentionally set to 0 if the velocity is
      // is in the opposite direction of the destination, as flinging up an
      // over-dragged sheet or flinging down an under-dragged sheet tends to
      // cause unstable motion.
      velocity.sign == direction ? velocity : 0.0,
    );
  }

  @override
  Simulation? createSettlingSimulation(SheetMetrics metrics) {
    if (parent case final parent?) {
      return parent.createSettlingSimulation(metrics);
    } else if (metrics.isPixelsInBounds) {
      return null;
    }
    final settleTo =
        metrics.pixels.nearest(metrics.minPixels, metrics.maxPixels);

    return InterpolationSimulation(
      start: metrics.pixels,
      end: settleTo,
      curve: Curves.easeInOut,
      durationInSeconds: max(
        (metrics.pixels - settleTo).abs() / _defaultSettlingSpeed,
        _minSettlingDuration.inMicroseconds / Duration.microsecondsPerSecond,
      ),
    );
  }
}

/// A [Simulation] that interpolates between two values over a given duration.
class InterpolationSimulation extends Simulation {
  /// Creates a [Simulation] that interpolates between two values
  /// over a given duration.
  ///
  /// Make sure that [start] and [end] are not equal, and the
  /// [durationInSeconds] must be greater than 0.
  InterpolationSimulation({
    required this.start,
    required this.end,
    required this.curve,
    required this.durationInSeconds,
  })  : assert(start != end),
        assert(durationInSeconds > 0);

  /// The start value of the interpolation.
  final double start;

  /// The end value of the interpolation.
  final double end;

  /// The curve to use for the interpolation.
  final Curve curve;

  /// The duration of the interpolation in seconds.
  late final double durationInSeconds;

  @override
  double dx(double time) {
    final epsilon = tolerance.time;
    return (x(time + epsilon) - x(time - epsilon)) / (2 * epsilon);
  }

  @override
  double x(double time) {
    final t = curve.transform((time / durationInSeconds).clamp(0, 1));
    return lerpDouble(start, end, t)!;
  }

  @override
  bool isDone(double time) {
    return x(time).isApprox(end);
  }
}

abstract interface class SnappingSheetBehavior {
  double? findSnapPixels(double velocity, SheetMetrics metrics);
}

mixin _SnapToNearestMixin implements SnappingSheetBehavior {
  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  double get minFlingSpeed;

  @protected
  (double, double) _getSnapBoundsContains(SheetMetrics metrics);

  @override
  double? findSnapPixels(double velocity, SheetMetrics metrics) {
    assert(minFlingSpeed >= 0);

    if (metrics.pixels.isOutOfBounds(metrics.minPixels, metrics.maxPixels)) {
      return null;
    }

    final (nearestSmaller, nearestGreater) = _getSnapBoundsContains(metrics);
    if (velocity.abs() < minFlingSpeed) {
      return metrics.pixels.nearest(nearestSmaller, nearestGreater);
    } else if (velocity < 0) {
      return nearestSmaller;
    } else {
      return nearestGreater;
    }
  }
}

/// A [SnappingSheetBehavior] that snaps to either [SheetExtent.minPixels]
/// or [SheetExtent.maxPixels] based on the current sheet position and
/// the gesture velocity.
///
/// If the absolute value of the gesture velocity is less than
/// [minFlingSpeed], the sheet will snap to the nearest of
/// [SheetExtent.minPixels] and [SheetExtent.maxPixels].
/// Otherwise, the gesture is considered to be a fling, and the sheet will snap
/// towards the direction of the fling. For example, if the sheet is flung up,
/// it will snap to [SheetExtent.maxPixels].
///
/// Using this behavior is functionally identical to using [SnapToNearest]
/// with the snap positions of [SheetExtent.minExtent] and
/// [SheetExtent.maxExtent], but more simplified and efficient.
class SnapToNearestEdge with _SnapToNearestMixin {
  /// Creates a [SnappingSheetBehavior] that snaps to either
  /// [SheetExtent.minPixels] or [SheetExtent.maxPixels].
  ///
  /// The [minFlingSpeed] defaults to [kMinFlingVelocity],
  /// and must be non-negative.
  const SnapToNearestEdge({
    this.minFlingSpeed = kMinFlingVelocity,
  }) : assert(minFlingSpeed >= 0);

  @override
  final double minFlingSpeed;

  @override
  (double, double) _getSnapBoundsContains(SheetMetrics metrics) {
    assert(metrics.pixels.isInBounds(metrics.minPixels, metrics.maxPixels));
    return (metrics.minPixels, metrics.maxPixels);
  }
}

class SnapToNearest with _SnapToNearestMixin {
  SnapToNearest({
    required this.snapTo,
    this.minFlingSpeed = kMinFlingVelocity,
  })  : assert(snapTo.isNotEmpty),
        assert(minFlingSpeed >= 0);

  final List<Extent> snapTo;

  @override
  final double minFlingSpeed;

  /// Cached results of [Extent.resolve] for each snap position in [snapTo].
  ///
  /// Always call [_ensureCacheIsValid] before accessing this list
  /// to ensure that the cache is up-to-date and sorted in ascending order.
  List<double> _snapTo = const [];
  Size? _cachedContentDimensions;

  void _ensureCacheIsValid(SheetMetrics metrics) {
    if (_cachedContentDimensions != metrics.contentDimensions) {
      _cachedContentDimensions = metrics.contentDimensions;
      _snapTo = snapTo
          .map((e) => e.resolve(metrics.contentDimensions))
          .toList(growable: false)
        ..sort();

      assert(
        _snapTo.first.isGreaterThanOrApprox(metrics.minPixels) &&
            _snapTo.last.isLessThanOrApprox(metrics.maxPixels),
        'The snap positions must be within the range of '
        "'SheetExtent.minPixels' and 'SheetExtent.maxPixels'.",
      );
    }
  }

  @override
  (double, double) _getSnapBoundsContains(SheetMetrics metrics) {
    _ensureCacheIsValid(metrics);
    if (_snapTo.length == 1) {
      return (_snapTo.first, _snapTo.first);
    }

    var nearestSmaller = _snapTo[0];
    var nearestGreater = _snapTo[1];
    for (var index = 0; index < _snapTo.length - 1; index++) {
      if (_snapTo[index].isLessThan(metrics.pixels)) {
        nearestSmaller = _snapTo[index];
        nearestGreater = _snapTo[index + 1];
      } else {
        break;
      }
    }

    return (nearestSmaller, nearestGreater);
  }
}

class SnappingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const SnappingSheetPhysics({
    super.parent,
    this.spring = kDefaultSheetSpring,
    this.snappingBehavior = const SnapToNearestEdge(),
  });

  final SnappingSheetBehavior snappingBehavior;

  @override
  final SpringDescription spring;

  @override
  SheetPhysics copyWith({
    SheetPhysics? parent,
    SpringDescription? spring,
    SnappingSheetBehavior? snappingBehavior,
  }) {
    return SnappingSheetPhysics(
      parent: parent ?? this.parent,
      spring: spring ?? this.spring,
      snappingBehavior: snappingBehavior ?? this.snappingBehavior,
    );
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics) {
    final snapPixels = snappingBehavior.findSnapPixels(velocity, metrics);
    if (snapPixels != null && !metrics.pixels.isApprox(snapPixels)) {
      return ScrollSpringSimulation(
        spring,
        metrics.pixels,
        snapPixels,
        velocity,
      );
    } else {
      return super.createBallisticSimulation(velocity, metrics);
    }
  }
}

class ClampingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const ClampingSheetPhysics({
    super.parent,
    this.spring = kDefaultSheetSpring,
  });

  @override
  final SpringDescription spring;

  @override
  SheetPhysics copyWith({SheetPhysics? parent, SpringDescription? spring}) {
    return ClampingSheetPhysics(parent: parent ?? this.parent);
  }
}

class StretchingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const StretchingSheetPhysics({
    super.parent,
    this.stretchingRange = const Extent.proportional(0.12),
    this.frictionCurve = Curves.easeOutSine,
    this.spring = kDefaultSheetSpring,
  });

  final Extent stretchingRange;
  final Curve frictionCurve;

  @override
  final SpringDescription spring;

  @override
  SheetPhysics copyWith({
    SheetPhysics? parent,
    SpringDescription? spring,
    Extent? stretchingRange,
    Curve? frictionCurve,
  }) {
    return StretchingSheetPhysics(
      parent: parent ?? this.parent,
      stretchingRange: stretchingRange ?? this.stretchingRange,
      frictionCurve: frictionCurve ?? this.frictionCurve,
    );
  }

  @override
  double computeOverflow(double offset, SheetMetrics metrics) {
    final stretchingRange =
        this.stretchingRange.resolve(metrics.contentDimensions);

    if (stretchingRange != 0) {
      return 0;
    }

    return super.computeOverflow(offset, metrics);
  }

  @override
  double applyPhysicsToOffset(double offset, SheetMetrics metrics) {
    final currentPixels = metrics.pixels;
    final minPixels = metrics.minPixels;
    final maxPixels = metrics.maxPixels;

    if (currentPixels.isInBounds(minPixels, maxPixels) ||
        (currentPixels > maxPixels && offset < 0) ||
        (currentPixels < minPixels && offset > 0)) {
      // The friction is not applied if the current 'pixels' is within the range
      // or the motion direction is towards the range.
      return offset;
    }

    final stretchingRange =
        this.stretchingRange.resolve(metrics.contentDimensions);

    if (stretchingRange.isApprox(0)) {
      return 0;
    }

    // We divide the delta into smaller fragments
    // and apply friction to each fragment in sequence.
    // This ensures that the friction is not too small
    // if the delta is too large relative to the overflowing pixels,
    // preventing the sheet from slipping too far.
    const fragmentSize = 18.0;
    var newPixels = currentPixels;
    var consumedOffset = 0.0;
    while (consumedOffset.abs() < offset.abs()) {
      final fragment = (offset - consumedOffset).clampAbs(fragmentSize);
      final overflowPastStart = max(minPixels - currentPixels, 0.0);
      final overflowPastEnd = max(currentPixels - maxPixels, 0.0);
      final overflowPast = max(overflowPastStart, overflowPastEnd);
      final overflowFraction = (overflowPast / stretchingRange).clampAbs(1);
      final frictionFactor = frictionCurve.transform(overflowFraction);

      newPixels += fragment * (1.0 - frictionFactor);
      consumedOffset += fragment;
    }

    return newPixels - currentPixels;
  }
}

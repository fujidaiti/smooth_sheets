import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/internal/double_utils.dart';

// logical pixels per second
const _defaultSettlingSpeed = 1000.0;

abstract class SheetPhysics {
  const SheetPhysics({
    this.parent,
    SpringDescription? spring,
  }) : _spring = spring;

  final SheetPhysics? parent;

  final SpringDescription? _spring;
  SpringDescription get spring {
    return _spring ?? const ScrollPhysics().spring;
  }

  double computeOverflow(double offset, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.computeOverflow(offset, metrics);
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

  double applyPhysicsToOffset(double offset, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.applyPhysicsToOffset(offset, metrics);
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

  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.createBallisticSimulation(velocity, metrics);
    } else if (metrics.pixels.isLessThan(metrics.minPixels)) {
      // The simulation velocity is intentionally set to 0
      // as flinging an over-dragged/under-dragged sheet
      // tends to make unstable motion.
      return ScrollSpringSimulation(
          spring, metrics.pixels, metrics.minPixels, 0);
    } else if (metrics.pixels.isGreaterThan(metrics.maxPixels)) {
      return ScrollSpringSimulation(
          spring, metrics.pixels, metrics.maxPixels, 0);
    } else {
      return null;
    }
  }

  Simulation? createSettlingSimulation(SheetMetrics metrics) {
    if (parent != null) {
      return parent!.createSettlingSimulation(metrics);
    } else if (metrics.pixels.isLessThan(metrics.minPixels)) {
      return UniformLinearSimulation(
        position: metrics.pixels,
        detent: metrics.minPixels,
        speed: _defaultSettlingSpeed,
      );
    } else if (metrics.pixels.isGreaterThan(metrics.maxPixels)) {
      return UniformLinearSimulation(
        position: metrics.pixels,
        detent: metrics.minPixels,
        speed: _defaultSettlingSpeed,
      );
    } else {
      return null;
    }
  }

  bool shouldGoBallistic(double velocity, SheetMetrics metrics) {
    if (parent != null) {
      return parent!.shouldGoBallistic(velocity, metrics);
    }

    return metrics.pixels.isOutOfRange(metrics.minPixels, metrics.maxPixels);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetPhysics &&
          runtimeType == other.runtimeType &&
          parent == other.parent);

  @override
  int get hashCode => Object.hash(runtimeType, parent);
}

class UniformLinearSimulation extends Simulation {
  UniformLinearSimulation({
    required this.position,
    required this.detent,
    required double speed,
  }) : assert(speed > 0) {
    velocity = (detent - position).sign * speed;
    duration = (detent - position) / velocity;
  }

  final double position;
  final double detent;
  late final double velocity;
  late final double duration;

  @override
  double dx(double time) {
    return velocity;
  }

  @override
  double x(double time) {
    return switch (time < duration) {
      true => position + velocity * time,
      false => detent,
    };
  }

  @override
  bool isDone(double time) {
    return x(time).isApprox(detent);
  }
}

typedef SnapPixelsProvider = double? Function(
  Iterable<Extent> snapTo,
  double velocity,
  SheetMetrics metrics,
);

abstract interface class SnappingSheetBehavior {
  double? findSnapPixels(double velocity, SheetMetrics metrics);
}

mixin _SnapToNearestMixin implements SnappingSheetBehavior {
  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  double get minFlingSpeed;

  @protected
  ({double left, double right}) _findSnapRangeContains(SheetMetrics metrics);

  @override
  double? findSnapPixels(double velocity, SheetMetrics metrics) {
    assert(minFlingSpeed >= 0);

    if (metrics.pixels.isOutOfRange(metrics.minPixels, metrics.maxPixels)) {
      return null;
    }

    final snapRange = _findSnapRangeContains(metrics);
    if (velocity.abs() < minFlingSpeed) {
      return metrics.pixels.nearest(snapRange.left, snapRange.right);
    } else if (velocity < 0) {
      return snapRange.left;
    } else {
      return snapRange.right;
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
  ({double left, double right}) _findSnapRangeContains(SheetMetrics metrics) {
    return (left: metrics.minPixels, right: metrics.maxPixels);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapToNearestEdge &&
          runtimeType == other.runtimeType &&
          minFlingSpeed == other.minFlingSpeed);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        minFlingSpeed,
      );
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
    }
  }

  @override
  ({double left, double right}) _findSnapRangeContains(SheetMetrics metrics) {
    _ensureCacheIsValid(metrics);
    if (_snapTo.length == 1) {
      return (left: _snapTo.first, right: _snapTo.first);
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

    return (left: nearestSmaller, right: nearestGreater);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapToNearest &&
          runtimeType == other.runtimeType &&
          minFlingSpeed == other.minFlingSpeed &&
          const DeepCollectionEquality().equals(snapTo, other.snapTo));

  @override
  int get hashCode => Object.hash(
        runtimeType,
        minFlingSpeed,
        snapTo,
      );
}

class SnappingSheetPhysics extends SheetPhysics {
  const SnappingSheetPhysics({
    super.parent,
    super.spring,
    this.snappingBehavior = const SnapToNearestEdge(),
  });

  final SnappingSheetBehavior snappingBehavior;

  @override
  bool shouldGoBallistic(double velocity, SheetMetrics metrics) {
    final snapPixels = snappingBehavior.findSnapPixels(velocity, metrics);
    final currentPixels = metrics.pixels;

    if (snapPixels != null && !currentPixels.isApprox(snapPixels)) {
      return true;
    } else {
      return super.shouldGoBallistic(velocity, metrics);
    }
  }

  @override
  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics) {
    final snapPixels = snappingBehavior.findSnapPixels(velocity, metrics);
    if (snapPixels != null && !metrics.pixels.isApprox(snapPixels)) {
      return ScrollSpringSimulation(
          spring, metrics.pixels, snapPixels, velocity);
    } else {
      return super.createBallisticSimulation(velocity, metrics);
    }
  }

  @override
  Simulation? createSettlingSimulation(SheetMetrics metrics) {
    final snapPixels = snappingBehavior.findSnapPixels(0, metrics);
    if (snapPixels != null && !metrics.pixels.isApprox(snapPixels)) {
      return UniformLinearSimulation(
        position: metrics.pixels,
        detent: snapPixels,
        speed: _defaultSettlingSpeed,
      );
    } else {
      return super.createSettlingSimulation(metrics);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnappingSheetPhysics &&
          snappingBehavior == other.snappingBehavior &&
          super == other);

  @override
  int get hashCode => Object.hash(snappingBehavior, super.hashCode);
}

class ClampingSheetPhysics extends SheetPhysics {
  const ClampingSheetPhysics({
    super.parent,
  });
}

class StretchingSheetPhysics extends SheetPhysics {
  const StretchingSheetPhysics({
    super.parent,
    this.stretchingRange = const Extent.proportional(0.12),
    this.frictionCurve = Curves.easeOutSine,
  });

  final Extent stretchingRange;
  final Curve frictionCurve;

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

    if (currentPixels.isInRange(minPixels, maxPixels) ||
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

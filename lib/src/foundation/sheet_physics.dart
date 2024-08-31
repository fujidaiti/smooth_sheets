import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../internal/double_utils.dart';
import '../internal/float_comp.dart';
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
  damping: 15.5563491861, // 1.1 * 2.0 * sqrt(0.5 * 100.0)
);

const _kMinSettlingDuration = Duration(milliseconds: 160);
const _kDefaultSettlingSpeed = 600.0; // logical pixels per second

/// The default [SheetPhysics] used by sheet widgets.
const kDefaultSheetPhysics =
    BouncingSheetPhysics(parent: SnappingSheetPhysics());

// TODO: Implement `equals` and `hashCode` for SheetPhysics classes.
abstract class SheetPhysics {
  const SheetPhysics({this.parent});

  final SheetPhysics? parent;

  /// The minimum amount of pixel distance drags must move by to start motion
  /// the first time or after each time the drag motion stopped.
  ///
  /// If null, no minimum threshold is enforced.
  double? get dragStartDistanceMotionThreshold {
    return Platform.isIOS
        ? const BouncingScrollPhysics().dragStartDistanceMotionThreshold
        : null;
  }

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

  // TODO: Change to return a tuple of (physicsAppliedOffset, overflow) to avoid recomputation of the overflow.
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
    // TODO: Use computeOverflow() to calculate the overflowed pixels.
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
        (metrics.pixels - settleTo).abs() / _kDefaultSettlingSpeed,
        _kMinSettlingDuration.inMicroseconds / Duration.microsecondsPerSecond,
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
    super.tolerance,
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
    return nearEqual(x(time), end, tolerance.distance);
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

    if (FloatComp.distance(metrics.devicePixelRatio)
        .isOutOfBounds(metrics.pixels, metrics.minPixels, metrics.maxPixels)) {
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

/// A [SnappingSheetBehavior] that snaps to either [SheetMetrics.minPixels]
/// or [SheetMetrics.maxPixels] based on the current sheet position and
/// the gesture velocity.
///
/// If the absolute value of the gesture velocity is less than
/// [minFlingSpeed], the sheet will snap to the nearest of
/// [SheetMetrics.minPixels] and [SheetMetrics.maxPixels].
/// Otherwise, the gesture is considered to be a fling, and the sheet will snap
/// towards the direction of the fling. For example, if the sheet is flung up,
/// it will snap to [SheetMetrics.maxPixels].
///
/// Using this behavior is functionally identical to using [SnapToNearest]
/// with the snap positions of [SheetExtent.minExtent] and
/// [SheetExtent.maxExtent], but more simplified and efficient.
class SnapToNearestEdge with _SnapToNearestMixin {
  /// Creates a [SnappingSheetBehavior] that snaps to either
  /// [SheetMetrics.minPixels] or [SheetMetrics.maxPixels].
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
    assert(FloatComp.distance(metrics.devicePixelRatio)
        .isInBounds(metrics.pixels, metrics.minPixels, metrics.maxPixels));
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
  Size? _cachedContentSize;

  void _ensureCacheIsValid(SheetMetrics metrics) {
    if (_cachedContentSize != metrics.contentSize) {
      _cachedContentSize = metrics.contentSize;
      _snapTo = snapTo
          .map((e) => e.resolve(metrics.contentSize))
          .toList(growable: false)
        ..sort();

      assert(
        FloatComp.distance(metrics.devicePixelRatio)
                .isGreaterThanOrApprox(_snapTo.first, metrics.minPixels) &&
            FloatComp.distance(metrics.devicePixelRatio)
                .isLessThanOrApprox(_snapTo.last, metrics.maxPixels),
        'The snap positions must be within the range of '
        "'SheetMetrics.minPixels' and 'SheetMetrics.maxPixels'.",
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
      if (FloatComp.distance(metrics.devicePixelRatio)
          .isLessThan(_snapTo[index], metrics.pixels)) {
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
    if (snapPixels != null &&
        FloatComp.distance(metrics.devicePixelRatio)
            .isNotApprox(snapPixels, metrics.pixels)) {
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
    return ClampingSheetPhysics(
      parent: parent ?? this.parent,
      spring: spring ?? this.spring,
    );
  }
}

/// {@template BouncingBehavior}
/// An object that determines the behavior of a bounceable sheet
/// when it is out of the content bounds.
/// {@endtemplate}
///
/// See also:
/// - [FixedBouncingBehavior], which allows the sheet position to exceed the
///   content bounds by a fixed amount.
/// - [DirectionAwareBouncingBehavior], which allows the sheet position to
///  exceed the content bounds by different amounts based on the direction
///  of a drag gesture.
abstract class BouncingBehavior {
  /// Returns the number of pixels that the sheet position can go beyond
  /// the content bounds.
  ///
  /// [BouncingSheetPhysics.applyPhysicsToOffset] calls this method to calculate
  /// the amount of friction that should be applied to the given drag [offset].
  ///
  /// The returned value must be non-negative. Since this method may be called
  /// every frame, and even multiple times per frame, it is not recommended to
  /// return different values for each call, as it may cause unstable motion.
  double computeBounceablePixels(double offset, SheetMetrics metrics);
}

/// A [BouncingBehavior] that allows the sheet position to exceed the content
/// bounds by a fixed amount.
///
/// The following is an example of a [BouncingSheetPhysics] that allows the
/// sheet position to go beyond the [SheetMetrics.maxPixels] or
/// [SheetMetrics.minPixels] by 12% of the content size.
///
/// ```dart
/// const physics = BouncingSheetPhysics(
///   behavior: FixedBouncingBehavior(Extent.proportional(0.12)),
/// );
/// ```
class FixedBouncingBehavior implements BouncingBehavior {
  /// Creates a [BouncingBehavior] that allows the sheet to bounce by a fixed
  /// amount.
  const FixedBouncingBehavior(this.range);

  /// How much the sheet can bounce beyond the content bounds.
  final Extent range;

  @override
  double computeBounceablePixels(double offset, SheetMetrics metrics) {
    return range.resolve(metrics.contentSize);
  }
}

/// A [BouncingBehavior] that allows the sheet position to exceed the content
/// bounds by different amounts based on the direction of a drag gesture.
///
/// Different bounceable amounts can be specified for upward and downward
/// directions. For example, the following [BouncingSheetPhysics] allows the
/// sheet to bounce by 12% of the content size when dragged downward, and by
/// 8 pixels when dragged upward.
///
/// ```dart
/// const physics = BouncingSheetPhysics(
///   behavior: DirectionAwareBouncingBehavior(
///     upward: Extent.pixels(8),
///     downward: Extent.proportional(0.12),
///   ),
/// );
/// ```
class DirectionAwareBouncingBehavior implements BouncingBehavior {
  /// Creates a [BouncingBehavior] that allows the sheet to bounce by different
  /// amounts based on the direction of a drag gesture.
  const DirectionAwareBouncingBehavior({
    this.upward = const Extent.pixels(0),
    this.downward = const Extent.pixels(0),
  });

  /// Amount of bounceable pixels when dragged upward.
  final Extent upward;

  /// Amount of bounceable pixels when dragged downward.
  final Extent downward;

  @override
  double computeBounceablePixels(double offset, SheetMetrics metrics) {
    return switch (offset) {
      > 0.0 => upward.resolve(metrics.contentSize),
      < 0.0 => downward.resolve(metrics.contentSize),
      _ => 0.0,
    };
  }
}

class BouncingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const BouncingSheetPhysics({
    super.parent,
    this.behavior = const FixedBouncingBehavior(Extent.proportional(0.12)),
    this.frictionCurve = Curves.easeOutSine,
    this.spring = kDefaultSheetSpring,
  });

  /// {@macro BouncingBehavior}
  final BouncingBehavior behavior;

  final Curve frictionCurve;

  @override
  final SpringDescription spring;

  @override
  SheetPhysics copyWith({
    SheetPhysics? parent,
    SpringDescription? spring,
    BouncingBehavior? behavior,
    Curve? frictionCurve,
  }) {
    return BouncingSheetPhysics(
      parent: parent ?? this.parent,
      spring: spring ?? this.spring,
      behavior: behavior ?? this.behavior,
      frictionCurve: frictionCurve ?? this.frictionCurve,
    );
  }

  @override
  double computeOverflow(double offset, SheetMetrics metrics) {
    final bounceableRange = behavior.computeBounceablePixels(offset, metrics);
    if (bounceableRange != 0) {
      return const ClampingSheetPhysics().applyPhysicsToOffset(offset, metrics);
    }

    return super.computeOverflow(offset, metrics);
  }

  @override
  double applyPhysicsToOffset(double offset, SheetMetrics metrics) {
    final bounceablePixels = behavior.computeBounceablePixels(offset, metrics);
    if (bounceablePixels == 0) {
      return const ClampingSheetPhysics().applyPhysicsToOffset(offset, metrics);
    }

    final currentPixels = metrics.pixels;
    final minPixels = metrics.minPixels;
    final maxPixels = metrics.maxPixels;

    // A part of or the entire offset that is not affected by friction.
    // If the current 'pixels' plus the offset exceeds the content bounds,
    // only the exceeding part is affected by friction. Otherwise, friction
    // is not applied to the offset at all.
    final zeroFrictionOffset = switch (offset) {
      > 0 => max(min(currentPixels + offset, maxPixels) - currentPixels, 0.0),
      < 0 => min(max(currentPixels + offset, minPixels) - currentPixels, 0.0),
      _ => 0.0,
    };

    if (FloatComp.distance(metrics.devicePixelRatio)
            .isApprox(zeroFrictionOffset, offset) ||
        // The friction is also not applied if the motion
        // direction is towards the content bounds.
        (currentPixels > maxPixels && offset < 0) ||
        (currentPixels < minPixels && offset > 0)) {
      return offset;
    }

    // We divide the delta into smaller fragments and apply friction to each
    // fragment in sequence. This ensures that the friction is not too small
    // if the delta is too large relative to the exceeding pixels, preventing
    // the sheet from slipping too far.
    const offsetSlop = 18.0;
    var newPixels = currentPixels;
    var consumedOffset = zeroFrictionOffset;
    while (consumedOffset.abs() < offset.abs()) {
      final fragment = (offset - consumedOffset).clampAbs(offsetSlop);
      final overflowPastStart = max(minPixels - (newPixels + fragment), 0.0);
      final overflowPastEnd = max(newPixels + fragment - maxPixels, 0.0);
      final overflowPast = max(overflowPastStart, overflowPastEnd);
      final overflowFraction = (overflowPast / bounceablePixels).clampAbs(1);
      final frictionFactor = frictionCurve.transform(overflowFraction);

      newPixels += fragment * (1.0 - frictionFactor);
      consumedOffset += fragment;
    }

    return newPixels - currentPixels;
  }
}

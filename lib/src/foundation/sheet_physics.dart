import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../internal/double_utils.dart';
import '../internal/float_comp.dart';
import 'sheet_position.dart';

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

  // TODO: Change to return a tuple of (physicsAppliedOffset, overflow)
  // to avoid recomputation of the overflow.
  double applyPhysicsToOffset(double offset, SheetMetrics metrics);

  Simulation? createBallisticSimulation(double velocity, SheetMetrics metrics);

  /// {@template SheetPhysics.findSettledExtent}
  /// Returns an extent to which a sheet should eventually settle
  /// based on the current [metrics] and the [velocity] of a sheet.
  /// {@endtemplate}
  Extent findSettledExtent(double velocity, SheetMetrics metrics);
}

/// A mixin that provides default implementations for [SheetPhysics] methods.
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
    }

    // Ensure that this method always uses the default implementation
    // of findSettledExtent.
    final detent = _findSettledExtentInternal(velocity, metrics)
        .resolve(metrics.contentSize);
    if (FloatComp.distance(metrics.devicePixelRatio)
        .isNotApprox(detent, metrics.pixels)) {
      final direction = (detent - metrics.pixels).sign;
      return ScrollSpringSimulation(
        spring,
        metrics.pixels,
        detent,
        // The simulation velocity is intentionally set to 0 if the velocity is
        // is in the opposite direction of the destination, as flinging up an
        // over-dragged sheet or flinging down an under-dragged sheet tends to
        // cause unstable motion.
        velocity.sign == direction ? velocity : 0.0,
      );
    }

    return null;
  }

  /// Returns the closer of [SheetMetrics.minExtent] or [SheetMetrics.maxExtent]
  /// to the current sheet position if it is out of bounds, regardless of the
  /// [velocity]. Otherwise, it returns the current position.
  @override
  Extent findSettledExtent(double velocity, SheetMetrics metrics) {
    return _findSettledExtentInternal(velocity, metrics);
  }

  Extent _findSettledExtentInternal(double velocity, SheetMetrics metrics) {
    final pixels = metrics.pixels;
    final minPixels = metrics.minPixels;
    final maxPixels = metrics.maxPixels;
    if (FloatComp.distance(metrics.devicePixelRatio)
        .isInBoundsExclusive(pixels, minPixels, maxPixels)) {
      return Extent.pixels(pixels);
    } else if ((pixels - minPixels).abs() < (pixels - maxPixels).abs()) {
      return metrics.minExtent;
    } else {
      return metrics.maxExtent;
    }
  }
}

abstract interface class SnappingSheetBehavior {
  /// {@macro SheetPhysics.findSettledExtent}
  ///
  /// Returning `null` indicates that this behavior has no preference for
  /// for where the sheet should settle.
  Extent? findSettledExtent(double velocity, SheetMetrics metrics);
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
class SnapToNearestEdge implements SnappingSheetBehavior {
  /// Creates a [SnappingSheetBehavior] that snaps to either
  /// [SheetMetrics.minPixels] or [SheetMetrics.maxPixels].
  ///
  /// The [minFlingSpeed] defaults to [kMinFlingVelocity],
  /// and must be non-negative.
  const SnapToNearestEdge({
    this.minFlingSpeed = kMinFlingVelocity,
  }) : assert(minFlingSpeed >= 0);

  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  final double minFlingSpeed;

  @override
  Extent? findSettledExtent(double velocity, SheetMetrics metrics) {
    assert(minFlingSpeed >= 0);
    final pixels = metrics.pixels;
    final minPixels = metrics.minPixels;
    final maxPixels = metrics.maxPixels;
    final cmp = FloatComp.distance(metrics.devicePixelRatio);
    if (cmp.isOutOfBounds(pixels, minPixels, maxPixels)) {
      return null;
    }
    if (velocity >= minFlingSpeed) {
      return metrics.maxExtent;
    }
    if (velocity <= -minFlingSpeed) {
      return metrics.minExtent;
    }
    if (cmp.isApprox(pixels, minPixels) || cmp.isApprox(pixels, maxPixels)) {
      return null;
    }
    return (pixels - minPixels).abs() < (pixels - maxPixels).abs()
        ? metrics.minExtent
        : metrics.maxExtent;
  }
}

class SnapToNearest implements SnappingSheetBehavior {
  const SnapToNearest({
    required this.snapTo,
    this.minFlingSpeed = kMinFlingVelocity,
  }) : assert(minFlingSpeed >= 0);

  // TODO: Rename to `detents`.
  final List<Extent> snapTo;

  /// The lowest speed (in logical pixels per second)
  /// at which a gesture is considered to be a fling.
  final double minFlingSpeed;

  @override
  Extent? findSettledExtent(double velocity, SheetMetrics metrics) {
    if (snapTo.length <= 1) {
      return snapTo.firstOrNull;
    }

    final (sortedDetents, nearestIndex) =
        sortExtentsAndFindNearest(snapTo, metrics.pixels, metrics.contentSize);
    final cmp = FloatComp.distance(metrics.devicePixelRatio);
    final pixels = metrics.pixels;

    if (cmp.isOutOfBounds(
      pixels,
      sortedDetents.first.resolved,
      sortedDetents.last.resolved,
    )) {
      return null;
    }

    final nearest = sortedDetents[nearestIndex];
    if (velocity.abs() < minFlingSpeed) {
      return cmp.isApprox(pixels, nearest.resolved) ? null : nearest.extent;
    }

    final int floorIndex;
    final int ceilIndex;
    if (cmp.isApprox(pixels, nearest.resolved)) {
      floorIndex = max(nearestIndex - 1, 0);
      ceilIndex = min(nearestIndex + 1, sortedDetents.length - 1);
    } else if (pixels < nearest.resolved) {
      floorIndex = max(nearestIndex - 1, 0);
      ceilIndex = nearestIndex;
    } else {
      assert(pixels > nearest.resolved);
      floorIndex = nearestIndex;
      ceilIndex = min(nearestIndex + 1, sortedDetents.length - 1);
    }

    assert(velocity.abs() >= minFlingSpeed);
    return velocity < 0
        ? sortedDetents[floorIndex].extent
        : sortedDetents[ceilIndex].extent;
  }
}

typedef _SortedExtentList = List<({Extent extent, double resolved})>;

/// Sorts the [extents] based on their resolved values and finds the nearest
/// extent to the [pixels].
///
/// Returns a sorted copy of the [extents] and the index of the nearest extent.
/// Note that the returned list may have a fixed length for better performance.
@visibleForTesting
(_SortedExtentList, int) sortExtentsAndFindNearest(
  List<Extent> extents,
  double pixels,
  Size contentSize,
) {
  assert(extents.isNotEmpty);
  switch (extents) {
    case [final a, final b]:
      return _sortTwoExtentsAndFindNearest(a, b, pixels, contentSize);
    case [final a, final b, final c]:
      return _sortThreeExtentsAndFindNearest(a, b, c, pixels, contentSize);
    case _:
      final sortedExtents = extents
          .map((e) => (extent: e, resolved: e.resolve(contentSize)))
          .sorted((a, b) => a.resolved.compareTo(b.resolved));
      final nearestIndex = sortedExtents
          .mapIndexed((i, e) => (index: i, dist: (pixels - e.resolved).abs()))
          .reduce((a, b) => a.dist < b.dist ? a : b)
          .index;
      return (sortedExtents, nearestIndex);
  }
}

/// Constant time sorting and nearest neighbor search for two [Extent]s.
(_SortedExtentList, int) _sortTwoExtentsAndFindNearest(
  Extent a,
  Extent b,
  double pixels,
  Size contentSize,
) {
  var first = (extent: a, resolved: a.resolve(contentSize));
  var second = (extent: b, resolved: b.resolve(contentSize));

  if (first.resolved > second.resolved) {
    final temp = first;
    first = second;
    second = temp;
  }

  final distToFirst = (pixels - first.resolved).abs();
  final distToSecond = (pixels - second.resolved).abs();
  final nearestIndex = distToFirst < distToSecond ? 0 : 1;

  return (
    // Create a fixed-length list.
    List.filled(2, first)..[1] = second,
    nearestIndex,
  );
}

/// Constant time sorting and nearest neighbor search for three [Extent]s.
(_SortedExtentList, int) _sortThreeExtentsAndFindNearest(
  Extent a,
  Extent b,
  Extent c,
  double pixels,
  Size contentSize,
) {
  var first = (extent: a, resolved: a.resolve(contentSize));
  var second = (extent: b, resolved: b.resolve(contentSize));
  var third = (extent: c, resolved: c.resolve(contentSize));

  if (first.resolved > second.resolved) {
    final temp = first;
    first = second;
    second = temp;
  }
  if (second.resolved > third.resolved) {
    final temp = second;
    second = third;
    third = temp;
  }
  if (first.resolved > second.resolved) {
    final temp = first;
    first = second;
    second = temp;
  }

  final distToFirst = (pixels - first.resolved).abs();
  final distToSecond = (pixels - second.resolved).abs();
  final distToThird = (pixels - third.resolved).abs();

  final int nearestIndex;
  if (distToFirst < distToSecond && distToFirst < distToThird) {
    nearestIndex = 0;
  } else if (distToSecond < distToFirst && distToSecond < distToThird) {
    nearestIndex = 1;
  } else {
    nearestIndex = 2;
  }

  return (
    // Create a fixed-length list.
    List.filled(3, first)
      ..[1] = second
      ..[2] = third,
    nearestIndex,
  );
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
    final detent = snappingBehavior
        .findSettledExtent(velocity, metrics)
        ?.resolve(metrics.contentSize);
    if (detent != null &&
        FloatComp.distance(metrics.devicePixelRatio)
            .isNotApprox(detent, metrics.pixels)) {
      return ScrollSpringSimulation(
        spring,
        metrics.pixels,
        detent,
        velocity,
      );
    } else {
      return super.createBallisticSimulation(velocity, metrics);
    }
  }

  @override
  Extent findSettledExtent(double velocity, SheetMetrics metrics) {
    return snappingBehavior.findSettledExtent(velocity, metrics) ??
        super.findSettledExtent(velocity, metrics);
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

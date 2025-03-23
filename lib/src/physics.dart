import 'dart:math';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';

import 'internal/double_utils.dart';
import 'internal/float_comp.dart';
import 'model.dart';
import 'snap_grid.dart';

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
const kDefaultSheetPhysics = BouncingSheetPhysics();

abstract class SheetPhysics {
  const SheetPhysics();

  /// The minimum amount of pixel distance drags must move by to start motion
  /// the first time or after each time the drag motion stopped.
  ///
  /// If null, no minimum threshold is enforced.
  double? get dragStartDistanceMotionThreshold =>
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS =>
          const BouncingScrollPhysics().dragStartDistanceMotionThreshold,
        _ => null,
      };

  double computeOverflow(double delta, SheetMetrics metrics);

  // TODO: Change to return a tuple of (physicsAppliedOffset, overflow)
  // to avoid recomputation of the overflow.
  double applyPhysicsToOffset(double delta, SheetMetrics metrics);

  Simulation? createBallisticSimulation(
    double velocity,
    SheetMetrics metrics,
    SheetSnapGrid snapGrid,
  );
}

/// A mixin that provides default implementations for [SheetPhysics] methods.
mixin SheetPhysicsMixin on SheetPhysics {
  SpringDescription get spring => kDefaultSheetSpring;

  @override
  double computeOverflow(double delta, SheetMetrics metrics) {
    final newOffset = metrics.offset + delta;
    if (newOffset > metrics.maxOffset) {
      return min(newOffset - metrics.maxOffset, delta);
    } else if (newOffset < metrics.minOffset) {
      return max(newOffset - metrics.minOffset, delta);
    } else {
      return 0;
    }
  }

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    // TODO: Use computeOverflow() to calculate the overflowed offset.
    if (delta > 0 && metrics.offset < metrics.maxOffset) {
      // Prevent the offset from going beyond the maximum value.
      return min(metrics.maxOffset, metrics.offset + delta) - metrics.offset;
    } else if (delta < 0 && metrics.offset > metrics.minOffset) {
      // Prevent the offset from going beyond the minimum value.
      return max(metrics.minOffset, metrics.offset + delta) - metrics.offset;
    } else {
      return 0;
    }
  }

  @override
  Simulation? createBallisticSimulation(
    double velocity,
    SheetMetrics metrics,
    SheetSnapGrid snapGrid,
  ) {
    // Ensure that this method always uses the default implementation
    // of findSettledPosition.
    final snap = snapGrid
        .getSnapOffset(metrics, metrics.offset, velocity)
        .resolve(metrics);

    if (FloatComp.distance(metrics.devicePixelRatio)
        .isNotApprox(snap, metrics.offset)) {
      final direction = (snap - metrics.offset).sign;
      return ScrollSpringSimulation(
        spring,
        metrics.offset,
        snap,
        // The simulation velocity is intentionally set to 0 if the velocity is
        // is in the opposite direction of the destination, as flinging up an
        // over-dragged sheet or flinging down an under-dragged sheet tends to
        // cause unstable motion.
        velocity.sign == direction ? velocity : 0.0,
      );
    }

    return null;
  }
}

class ClampingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const ClampingSheetPhysics({
    this.spring = kDefaultSheetSpring,
  });

  @override
  final SpringDescription spring;
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
// TODO: Remove this API.
abstract class BouncingBehavior {
  /// Returns the number of pixels that the sheet position can go beyond
  /// the content bounds.
  ///
  /// [BouncingSheetPhysics.applyPhysicsToOffset] calls this method to calculate
  /// the amount of friction that should be applied to the given drag [delta].
  ///
  /// The returned value must be non-negative. Since this method may be called
  /// every frame, and even multiple times per frame, it is not recommended to
  /// return different values for each call, as it may cause unstable motion.
  double computeBounceablePixels(double delta, SheetMetrics metrics);
}

/// A [BouncingBehavior] that allows the sheet position to exceed the content
/// bounds by a fixed amount.
///
/// The following is an example of a [BouncingSheetPhysics] that allows the
/// sheet position to go beyond the [SheetMetrics.maxOffset] or
/// [SheetMetrics.minOffset] by 12% of the content size.
///
/// ```dart
/// const physics = BouncingSheetPhysics(
///   behavior: FixedBouncingBehavior(SheetAnchor.proportional(0.12)),
/// );
/// ```
class FixedBouncingBehavior implements BouncingBehavior {
  /// Creates a [BouncingBehavior] that allows the sheet to bounce by a fixed
  /// amount.
  const FixedBouncingBehavior(this.range);

  /// How much the sheet can bounce beyond the content bounds.
  final SheetOffset range;

  @override
  double computeBounceablePixels(double delta, SheetMetrics metrics) {
    return range.resolve(metrics);
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
///     upward: SheetAnchor.pixels(8),
///     downward: SheetAnchor.proportional(0.12),
///   ),
/// );
/// ```
class DirectionAwareBouncingBehavior implements BouncingBehavior {
  /// Creates a [BouncingBehavior] that allows the sheet to bounce by different
  /// amounts based on the direction of a drag gesture.
  const DirectionAwareBouncingBehavior({
    this.upward = const SheetOffset(0),
    this.downward = const SheetOffset(0),
  });

  /// Amount of bounceable pixels when dragged upward.
  final SheetOffset upward;

  /// Amount of bounceable pixels when dragged downward.
  final SheetOffset downward;

  @override
  double computeBounceablePixels(double delta, SheetMetrics metrics) {
    return switch (delta) {
      > 0.0 => upward.resolve(metrics),
      < 0.0 => downward.resolve(metrics),
      _ => 0.0,
    };
  }
}

class BouncingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const BouncingSheetPhysics({
    this.behavior = const FixedBouncingBehavior(SheetOffset(0.12)),
    this.frictionCurve = Curves.easeOutSine,
    this.spring = kDefaultSheetSpring,
  });

  /// {@macro BouncingBehavior}
  final BouncingBehavior behavior;

  final Curve frictionCurve;

  @override
  final SpringDescription spring;

  @override
  double computeOverflow(double delta, SheetMetrics metrics) {
    final bounceableRange = behavior.computeBounceablePixels(delta, metrics);
    if (bounceableRange != 0) {
      return const ClampingSheetPhysics().applyPhysicsToOffset(delta, metrics);
    }

    return super.computeOverflow(delta, metrics);
  }

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    final bounceablePixels = behavior.computeBounceablePixels(delta, metrics);
    if (bounceablePixels == 0) {
      return const ClampingSheetPhysics().applyPhysicsToOffset(delta, metrics);
    }

    final currentOffset = metrics.offset;
    final minOffset = metrics.minOffset;
    final maxOffset = metrics.maxOffset;

    // A part of or the entire offset that is not affected by friction.
    // If the current 'pixels' plus the offset exceeds the content bounds,
    // only the exceeding part is affected by friction. Otherwise, friction
    // is not applied to the offset at all.
    final zeroFrictionOffset = switch (delta) {
      > 0 => max(min(currentOffset + delta, maxOffset) - currentOffset, 0.0),
      < 0 => min(max(currentOffset + delta, minOffset) - currentOffset, 0.0),
      _ => 0.0,
    };

    if (FloatComp.distance(metrics.devicePixelRatio)
            .isApprox(zeroFrictionOffset, delta) ||
        // The friction is also not applied if the motion
        // direction is towards the content bounds.
        (currentOffset > maxOffset && delta < 0) ||
        (currentOffset < minOffset && delta > 0)) {
      return delta;
    }

    // We divide the delta into smaller fragments and apply friction to each
    // fragment in sequence. This ensures that the friction is not too small
    // if the delta is too large relative to the exceeding pixels, preventing
    // the sheet from slipping too far.
    const offsetSlop = 18.0;
    var newOffset = currentOffset;
    var consumedOffset = zeroFrictionOffset;
    while (consumedOffset.abs() < delta.abs()) {
      final fragment = (delta - consumedOffset).clampAbs(offsetSlop);
      final overflowPastStart = max(minOffset - (newOffset + fragment), 0.0);
      final overflowPastEnd = max(newOffset + fragment - maxOffset, 0.0);
      final overflowPast = max(overflowPastStart, overflowPastEnd);
      final overflowFraction = (overflowPast / bounceablePixels).clampAbs(1);
      final frictionFactor = frictionCurve.transform(overflowFraction);

      newOffset += fragment * (1.0 - frictionFactor);
      consumedOffset += fragment;
    }

    return newOffset - currentOffset;
  }
}

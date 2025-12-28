import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

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
      return math.min(newOffset - metrics.maxOffset, delta);
    } else if (newOffset < metrics.minOffset) {
      return math.max(newOffset - metrics.minOffset, delta);
    } else {
      return 0;
    }
  }

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    // TODO: Use computeOverflow() to calculate the overflowed offset.
    if (delta > 0 && metrics.offset < metrics.maxOffset) {
      // Prevent the offset from going beyond the maximum value.
      return math.min(metrics.maxOffset, metrics.offset + delta) -
          metrics.offset;
    } else if (delta < 0 && metrics.offset > metrics.minOffset) {
      // Prevent the offset from going beyond the minimum value.
      return math.max(metrics.minOffset, metrics.offset + delta) -
          metrics.offset;
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

/// A [SheetPhysics] that allows the sheet to go beyond the offset bounds
/// defined by [SheetMetrics.minOffset] and [SheetMetrics.maxOffset].
///
/// See also:
/// - [Physics and SnapGrid example](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/physics_and_snap_grid.dart),
///   which shows how this physics works with a [SheetSnapGrid].
/// - [Tweak bouncing effect example](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/tweak_bouncing_effect.dart),
///   which shows how [bounceExtent] and [resistance] affect the bouncing
///   behavior.
class BouncingSheetPhysics extends SheetPhysics with SheetPhysicsMixin {
  const BouncingSheetPhysics({
    this.spring = kDefaultSheetSpring,
    this.bounceExtent = 120,
    this.resistance = 6,
  }) : assert(bounceExtent >= 0);

  /// Factor that controls how easy/hard it is to overdrag the sheet.
  ///
  /// The higher this value, the harder it is to reach the offset
  /// of [SheetMetrics.maxOffset] plus [bounceExtent] pixels if dragged upwards,
  /// or the offset of [SheetMetrics.minOffset] minus [bounceExtent] pixels
  /// if dragged downwards.
  ///
  /// This value can be negative.
  final double resistance;

  /// The maximum number of pixels that the sheet can be overdragged.
  ///
  /// See also [resistance], which controls how easy/hard it is to overdrag the sheet.
  final double bounceExtent;

  @override
  final SpringDescription spring;

  @override
  double computeOverflow(double delta, SheetMetrics metrics) {
    return 0;
  }

  @override
  double applyPhysicsToOffset(double delta, SheetMetrics metrics) {
    final minOffset = metrics.minOffset;
    final maxOffset = metrics.maxOffset;
    final currentOffset = metrics.offset;
    final unconstrainedNewOffset = currentOffset + delta;

    // A part of or the entire delta that is not affected by friction.
    // If the current offset plus the delta exceeds the content bounds,
    // only the exceeding part is affected by friction. Otherwise, friction
    // is not applied to the offset at all.
    final double zeroFrictionDelta;
    if (delta < 0 &&
        currentOffset > minOffset &&
        unconstrainedNewOffset < minOffset) {
      zeroFrictionDelta = minOffset - currentOffset;
    } else if (delta > 0 &&
        currentOffset < maxOffset &&
        unconstrainedNewOffset > maxOffset) {
      zeroFrictionDelta = maxOffset - currentOffset;
    } else {
      zeroFrictionDelta = 0.0;
    }

    final cmp = FloatComp.distance(metrics.devicePixelRatio);
    if (cmp.isApprox(zeroFrictionDelta, delta) ||
        // The friction is also not applied if the motion
        // direction is towards the content bounds.
        (currentOffset > maxOffset && delta < 0) ||
        (currentOffset < minOffset && delta > 0)) {
      return delta;
    }

    var newOffset = currentOffset + zeroFrictionDelta;
    var consumedDelta = zeroFrictionDelta;
    while (consumedDelta.abs() < delta.abs()) {
      // We divide the delta into smaller fragments and apply friction to each
      // fragment in sequence. This ensures that the friction is not too small
      // if the delta is too large relative to the exceeding pixels, preventing
      // the sheet from slipping too far.
      final fragment = (delta - consumedDelta).clamp(-kTouchSlop, kTouchSlop);
      final overflowPastStart =
          math.max(minOffset - (newOffset + fragment), 0.0);
      final overflowPastEnd = math.max(newOffset + fragment - maxOffset, 0.0);
      final overflowPast = math.max(overflowPastStart, overflowPastEnd);
      assert(overflowPast >= 0);
      final overflowFraction = (overflowPast / bounceExtent).clamp(0.0, 1.0);

      // The more the sheet is overdragged, the harder it is to drag further.
      final double frictionFactor;
      if (cmp.isNotApprox(resistance, 0)) {
        frictionFactor = (1.0 - math.exp(-1 * resistance * overflowFraction)) /
            (1.0 - math.exp(-1 * resistance));
      } else {
        // Linear map
        frictionFactor = overflowFraction;
      }

      newOffset += fragment * (1.0 - frictionFactor);
      consumedDelta += fragment;
    }

    return newOffset - currentOffset;
  }
}

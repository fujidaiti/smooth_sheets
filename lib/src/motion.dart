/// @docImport 'package:flutter/cupertino.dart';
/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'controller.dart';
/// @docImport 'cupertino.dart';
/// @docImport 'modal.dart';
library;

import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// The spring used by [SpringSheetMotion] by default.
///
/// This is the very spring that Flutter uses to drive the transitions of
/// [CupertinoModalPopupRoute] and [CupertinoDialogRoute]. Its stiffness was
/// read from the `CASpringAnimation` that iOS itself uses, and the damping is
/// derived from it as `2 * sqrt(mass * stiffness)`, which makes the spring
/// critically damped (a damping ratio of exactly 1). A critically damped
/// spring settles at its destination as fast as possible without ever
/// overshooting it.
const kDefaultSheetMotionSpring = SpringDescription(
  mass: 1,
  stiffness: 522.35,
  damping: 45.7099552,
);

/// The motion used by [SheetController.animateTo] by default.
///
/// This preserves the curve and duration that `animateTo` used before it
/// accepted a [SheetMotion], which differ from [CurvedSheetMotion]'s own
/// defaults.
const kDefaultSheetAnimationMotion = CurvedSheetMotion(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
);

/// The tolerance used by [SpringSheetMotion] by default.
///
/// The iOS spring animation is considered finished after 0.404 seconds. At
/// that point, the position is already within the default distance tolerance
/// of 1e-3, but the velocity is still around 0.02. The velocity tolerance is
/// therefore relaxed to 0.03, so that the transition does not keep running
/// noticeably longer than its iOS counterpart.
const kDefaultSheetMotionTolerance = Tolerance(velocity: 0.03);

/// Describes how the open and close transitions of a modal sheet route
/// are animated.
///
/// See also:
/// - [CurvedSheetMotion], which interpolates the transition along a
///   [Curve] over a fixed [Duration]. This is the default.
/// - [SpringSheetMotion], which drives the transition with a spring
///   simulation and carries the swipe-to-dismiss release velocity over into
///   the animation.
abstract class SheetMotion {
  /// Creates a description of how a sheet moves.
  const SheetMotion();

  /// Creates a [CurvedSheetMotion].
  const factory SheetMotion.curved({
    Duration duration,
    Curve curve,
  }) = CurvedSheetMotion;

  /// Creates a [SpringSheetMotion].
  const factory SheetMotion.spring({
    SpringDescription spring,
    Tolerance tolerance,
  }) = SpringSheetMotion;

  /// {@template sheet_motion_duration}
  /// How long the motion takes.
  ///
  /// A motion driven by a simulation has no duration of its own — it ends
  /// when the simulation runs out of energy — and reports only a nominal
  /// value, for the sake of the APIs that insist on one, such as
  /// [ModalRoute.transitionDuration].
  /// {@endtemplate}
  Duration get duration;

  /// The curve along which the progress is interpolated.
  ///
  /// Only consulted when [createSimulation] returns null; a simulation
  /// already describes the whole trajectory.
  Curve get curve;

  /// Whether the progress this motion produces always stays within `[0, 1]`.
  ///
  /// A motion that can overshoot its destination must return false, so that
  /// consumers driving an [AnimationController] give it an unbounded one
  /// instead of clamping the overshoot away.
  bool get isBounded => true;

  /// The simulation that carries the progress from [start] to [end],
  /// departing at [velocity], or null to interpolate along [curve] over
  /// [duration] instead.
  ///
  /// {@template sheet_motion_normalized_progress}
  /// All three values are expressed as a **normalized progress** running from
  /// 0 to 1, whatever quantity the consumer maps that progress onto — the
  /// visibility of a modal sheet route, or the offset of a sheet moved by
  /// [SheetController.animateTo]. [velocity] is therefore in units of
  /// progress per second rather than pixels per second, and any [Tolerance]
  /// is in progress units too. That is what lets one motion behave
  /// identically over a 20 pixel move and a 600 pixel one.
  /// {@endtemplate}
  Simulation? createSimulation({
    required double start,
    required double end,
    required double velocity,
  });
}

/// A [SheetMotion] that interpolates the transition progress along
/// [curve] over a fixed [duration].
///
/// This is the default motion of every modal sheet route.
///
/// Because the trajectory of a curve is a pure function of elapsed time, this
/// motion cannot take the velocity of a swipe-to-dismiss gesture into account:
/// a flick and a slow release from the same position produce exactly the same
/// animation. Use [SpringSheetMotion] if that matters.
class CurvedSheetMotion extends SheetMotion {
  /// Creates a curve driven modal sheet route transition.
  const CurvedSheetMotion({
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.fastEaseInToSlowEaseOut,
  });

  /// {@macro sheet_motion_duration}
  @override
  final Duration duration;

  /// The curve along which the transition progress is interpolated.
  @override
  final Curve curve;

  /// Always null: this motion interpolates along [curve] over [duration]
  /// rather than simulating anything.
  @override
  Simulation? createSimulation({
    required double start,
    required double end,
    required double velocity,
  }) => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurvedSheetMotion &&
          other.duration == duration &&
          other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);

  @override
  String toString() => 'CurvedSheetMotion(duration: $duration, curve: $curve)';
}

/// A [SheetMotion] that drives the transition with a
/// [SpringSimulation], the way iOS drives the same interaction.
///
/// Unlike [CurvedSheetMotion], a spring is velocity aware. When the
/// user releases a swipe-to-dismiss gesture, the velocity of their finger is
/// handed to the simulation as its initial velocity, so a flick and a slow
/// release produce different trajectories, and the motion stays continuous
/// across the gesture-to-animation handoff.
///
/// A [spring] with a damping ratio below 1 overshoots its destination before
/// settling onto it, which briefly carries the sheet past the top of its
/// resting position. Routes driven by this motion use an unbounded animation
/// controller so that the overshoot plays out instead of being clamped away.
/// The default [kDefaultSheetMotionSpring] never overshoots.
class SpringSheetMotion extends SheetMotion {
  /// Creates a spring driven modal sheet route transition.
  const SpringSheetMotion({
    this.spring = kDefaultSheetMotionSpring,
    this.tolerance = kDefaultSheetMotionTolerance,
  });

  /// Creates a spring driven transition from the perceptual [duration] and
  /// [bounce] pair used by SwiftUI's `spring(duration:bounce:)`.
  ///
  /// [bounce] is `0` for a critically damped spring that never overshoots its
  /// destination, positive (up to `1`) for a springier one that does, and
  /// negative (down to but excluding `-1`) for an increasingly sluggish,
  /// overdamped one.
  ///
  /// See also [SpringSheetMotion.smooth],
  /// [SpringSheetMotion.snappy],
  /// [SpringSheetMotion.bouncy] and
  /// [SpringSheetMotion.interactive], which are the four
  /// `duration`/`bounce` pairs that iOS itself uses.
  factory SpringSheetMotion.withBounce({
    Duration duration = const Duration(milliseconds: 500),
    double bounce = 0,
    Tolerance tolerance = kDefaultSheetMotionTolerance,
  }) {
    assert(duration > Duration.zero);
    // bounce == 1 would give a damping ratio of 0 — an undamped spring that
    // oscillates forever, so a transition using it would never finish.
    assert(bounce > -1 && bounce < 1);
    const mass = 1.0;
    final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final stiffness = 4 * math.pi * math.pi * mass / (seconds * seconds);
    final dampingRatio = bounce > 0 ? 1 - bounce : 1 / (bounce + 1);
    return SpringSheetMotion(
      spring: SpringDescription(
        mass: mass,
        stiffness: stiffness,
        damping: dampingRatio * 2 * math.sqrt(mass * stiffness),
      ),
      tolerance: tolerance,
    );
  }

  /// The iOS `smooth` spring: no bounce at all.
  ///
  /// [extraBounce] is added on top of the preset's own bounce.
  factory SpringSheetMotion.smooth({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0,
    Tolerance tolerance = kDefaultSheetMotionTolerance,
  }) => SpringSheetMotion.withBounce(
    duration: duration,
    bounce: extraBounce,
    tolerance: tolerance,
  );

  /// The iOS `snappy` spring: a small amount of bounce that reads as
  /// responsive rather than playful.
  ///
  /// [extraBounce] is added on top of the preset's own bounce.
  factory SpringSheetMotion.snappy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0,
    Tolerance tolerance = kDefaultSheetMotionTolerance,
  }) => SpringSheetMotion.withBounce(
    duration: duration,
    bounce: 0.15 + extraBounce,
    tolerance: tolerance,
  );

  /// The iOS `bouncy` spring: overshoots its destination by about 5% before
  /// settling back onto it.
  ///
  /// [extraBounce] is added on top of the preset's own bounce.
  factory SpringSheetMotion.bouncy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0,
    Tolerance tolerance = kDefaultSheetMotionTolerance,
  }) => SpringSheetMotion.withBounce(
    duration: duration,
    bounce: 0.3 + extraBounce,
    tolerance: tolerance,
  );

  /// The iOS `interactiveSpring`: a much shorter response, meant for motion
  /// that follows the user's finger.
  ///
  /// [extraBounce] is added on top of the preset's own bounce.
  factory SpringSheetMotion.interactive({
    Duration duration = const Duration(milliseconds: 150),
    double extraBounce = 0,
    Tolerance tolerance = kDefaultSheetMotionTolerance,
  }) => SpringSheetMotion.withBounce(
    duration: duration,
    bounce: 0.14 + extraBounce,
    tolerance: tolerance,
  );

  /// {@macro sheet_motion_duration}
  ///
  /// A spring settles when it runs out of energy rather than when a clock
  /// runs out, so this is only the value reported to APIs that demand a
  /// duration. It never drives the animation; [spring] does.
  @override
  Duration get duration => const Duration(milliseconds: 300);

  /// Always [Curves.linear]: the simulation already describes the whole
  /// trajectory, and reshaping it with a curve would distort it.
  @override
  Curve get curve => Curves.linear;

  /// Always false: a spring can carry the progress past its destination
  /// before settling back onto it.
  @override
  bool get isBounded => false;

  /// The spring that drives the transition.
  ///
  /// {@macro sheet_motion_normalized_progress}
  final SpringDescription spring;

  /// How close to its destination the [spring] must be, and how slowly it
  /// must be moving, for the motion to be considered finished.
  ///
  /// Measured in normalized progress, not pixels — see [spring].
  final Tolerance tolerance;

  /// {@macro sheet_motion_normalized_progress}
  @override
  Simulation createSimulation({
    required double start,
    required double end,
    required double velocity,
  }) {
    return SpringSimulation(
      spring,
      start,
      end,
      velocity,
      tolerance: tolerance,
      // Guarantees that the animation lands exactly on `end`, since a spring
      // only approaches its destination asymptotically.
      snapToEnd: true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpringSheetMotion &&
          other.spring.mass == spring.mass &&
          other.spring.stiffness == spring.stiffness &&
          other.spring.damping == spring.damping &&
          other.tolerance == tolerance;

  @override
  int get hashCode =>
      Object.hash(spring.mass, spring.stiffness, spring.damping, tolerance);

  @override
  String toString() => 'SpringSheetMotion(spring: $spring)';
}

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_drag.dart';
import 'sheet_physics.dart';
import 'sheet_position.dart';
import 'sheet_status.dart';
import 'snap_grid.dart';

@internal
@optionalTypeArgs
abstract class SheetActivity<T extends SheetPosition> {
  bool _disposed = false;

  bool get disposed {
    assert(!_mounted || !_disposed);
    return _disposed;
  }

  bool _mounted = false;

  bool get mounted {
    assert(!_mounted || !_disposed);
    return _mounted;
  }

  T? _owner;

  T get owner {
    assert(debugAssertMounted());
    return _owner!;
  }

  double get velocity => 0.0;

  SheetStatus get status;

  @mustCallSuper
  void init(T owner) {
    assert(_owner == null);
    assert(!_mounted);
    assert(!_disposed);

    _owner = owner;
    _mounted = true;
  }

  @mustCallSuper
  void updateOwner(T owner) {
    _owner = owner;
  }

  void dispose() {
    _mounted = false;
    _disposed = true;
  }

  /// Whether the sheet should ignore pointer events while performing
  /// this activity.
  bool get shouldIgnorePointer => false;

  bool isCompatibleWith(SheetPosition newOwner) => newOwner is T;

  void didChangeDimensions({
    required Size oldContentSize,
    required Size oldViewportSize,
    required EdgeInsets oldViewportInsets,
  }) {
    if (owner.maybeViewportInsets != oldViewportInsets) {
      absorbBottomViewportInset(owner, oldViewportInsets);
    }
  }

  @protected
  bool debugAssertMounted() {
    assert(() {
      if (!mounted) {
        throw FlutterError(
          'A $runtimeType was used after being disposed, or '
          'before init() was called. Once you have called dispose() '
          'on a $runtimeType, it can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  @protected
  bool debugAssertNotDisposed() {
    assert(() {
      if (disposed) {
        throw FlutterError(
          'A $runtimeType was used after being disposed. Once you have '
          'called dispose() on a $runtimeType, it can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }
}

/// An activity that animates the [SheetPosition]'s `pixels` to a destination
/// position determined by [destination], using the specified [curve] and
/// [duration].
///
/// This activity accepts the destination position as an [SheetAnchor], allowing
/// the concrete end position (in pixels) to be updated during the animation
/// in response to viewport changes, such as the appearance of the on-screen
/// keyboard.
///
/// When the bottom viewport inset changes, typically due to the appearance
/// or disappearance of the on-screen keyboard, this activity updates the
/// sheet position to maintain its visual position unchanged. If the
/// end position changes, it starts a [SettlingSheetActivity] for the
/// remaining duration to ensure the animation duration remains consistent.
@internal
class AnimatedSheetActivity extends SheetActivity
    with ControlledSheetActivityMixin {
  AnimatedSheetActivity({
    required this.destination,
    required this.duration,
    required this.curve,
  }) : assert(duration > Duration.zero);

  final SheetAnchor destination;
  final Duration duration;
  final Curve curve;

  late final double _startPixels;
  late final double _endPixels;

  @override
  void init(SheetPosition delegate) {
    super.init(delegate);
    _startPixels = owner.offset;
    _endPixels = destination.resolve(owner.contentSize);
  }

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(vsync: owner.context.vsync);
  }

  @override
  TickerFuture onAnimationStart() {
    return controller.animateTo(
      1.0,
      duration: duration,
      curve: curve,
    );
  }

  @override
  void onAnimationTick() {
    final progress = curve.transform(controller.value);
    owner
      ..setPixels(lerpDouble(_startPixels, _endPixels, progress)!)
      ..didUpdateMetrics();
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
  }

  @override
  void didChangeDimensions({
    required Size oldContentSize,
    required Size oldViewportSize,
    required EdgeInsets oldViewportInsets,
  }) {
    if (owner.maybeViewportInsets != oldViewportInsets) {
      absorbBottomViewportInset(owner, oldViewportInsets);
    }
    final newEndPixels = destination.resolve(owner.contentSize);
    if (newEndPixels != _endPixels) {
      final remainingDuration =
          duration - (controller.lastElapsedDuration ?? Duration.zero);
      owner.settleTo(destination, remainingDuration);
    }
  }
}

@internal
class BallisticSheetActivity extends SheetActivity
    with ControlledSheetActivityMixin {
  BallisticSheetActivity({
    required this.simulation,
  });

  final Simulation simulation;

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(vsync: owner.context.vsync);
  }

  @override
  TickerFuture onAnimationStart() {
    return controller.animateWith(simulation);
  }

  @override
  void onAnimationTick() {
    if (mounted) {
      owner
        ..setPixels(controller.value)
        ..didUpdateMetrics();
    }
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
  }

  @override
  void didChangeDimensions({
    required Size oldContentSize,
    required Size oldViewportSize,
    required EdgeInsets oldViewportInsets,
  }) {
    final oldMetrics = owner.copyWith(
      contentSize: oldContentSize,
      viewportSize: oldViewportSize,
      viewportInsets: oldViewportInsets,
    );
    final destination = owner.snapGrid.getSnapOffset(oldMetrics, velocity);

    if (oldViewportInsets != owner.viewportInsets) {
      absorbBottomViewportInset(owner, oldViewportInsets);
    }

    final endPixels = destination.resolve(owner.contentSize);
    if (endPixels == owner.offset) {
      return;
    }

    const maxSettlingDuration = 150; // milliseconds
    final distance = (endPixels - owner.offset).abs();
    final velocityNorm = velocity.abs();
    final estimatedSettlingDuration = velocityNorm > 0
        ? distance / velocityNorm * Duration.millisecondsPerSecond
        : double.infinity;

    owner.settleTo(
      destination,
      estimatedSettlingDuration > maxSettlingDuration
          ? const Duration(milliseconds: maxSettlingDuration)
          : Duration(milliseconds: estimatedSettlingDuration.round()),
    );
  }
}

/// A [SheetActivity] that performs a settling motion in response to changes
/// in the viewport dimensions or content size.
///
/// A [SheetPosition] may start this activity when the viewport insets change
/// during an animation, typically due to the appearance or disappearance of
/// the on-screen keyboard, or when the content size changes (e.g., due to
/// entering a new line of text in a text field).
///
/// This activity animates the sheet position to the [destination] with a
/// constant [velocity] until the destination is reached. Optionally, the
/// animation [duration] can be specified to explicitly control the time it
/// takes to reach the [destination]. In this case, the [velocity] is determined
/// based on the distance to the [destination] and the specified [duration].
///
/// When the concrete value of the [destination] changes due to viewport
/// metrics or content size changes, and the [duration] is specified,
/// the [velocity] is recalculated to ensure the animation duration remains
/// consistent.
@internal
class SettlingSheetActivity extends SheetActivity {
  /// Creates a settling activity that animates the sheet position to the
  /// [destination] with a constant [velocity].
  SettlingSheetActivity({
    required this.destination,
    required double velocity,
  })  : assert(velocity > 0),
        _velocity = velocity,
        duration = null;

  /// Creates a settling activity that animates the sheet position to the
  /// [destination] over the specified [duration].
  SettlingSheetActivity.withDuration(
    Duration this.duration, {
    required this.destination,
  }) : assert(duration > Duration.zero);

  /// The amount of time the animation should take to reach the destination.
  ///
  /// If `null`, the animation lasts until the destination is reached
  /// or this activity is disposed.
  final Duration? duration;

  /// The destination position to which the sheet should settle.
  final SheetAnchor destination;

  late final Ticker _ticker;

  /// The amount of time that has passed between the time the animation
  /// started and the most recent tick of the animation.
  var _elapsedDuration = Duration.zero;

  @override
  double get velocity => _velocity;
  late double _velocity;

  @override
  SheetStatus get status => SheetStatus.animating;

  @override
  void init(SheetPosition owner) {
    super.init(owner);
    _ticker = owner.context.vsync.createTicker(_tick)..start();
    _invalidateVelocity();
  }

  /// Updates the sheet position toward the destination based on the current
  /// [_velocity] and the time elapsed since the last frame.
  ///
  /// If the destination is reached, a ballistic activity is started with
  /// zero velocity to ensure consistency between the settled position
  /// and the current [SheetPhysics].
  void _tick(Duration elapsedDuration) {
    final elapsedFrameTime =
        (elapsedDuration - _elapsedDuration).inMicroseconds /
            Duration.microsecondsPerSecond;
    final destination = this.destination.resolve(owner.contentSize);
    final pixels = owner.offset;
    final newPixels = destination > pixels
        ? min(destination, pixels + velocity * elapsedFrameTime)
        : max(destination, pixels - velocity * elapsedFrameTime);
    owner
      ..setPixels(newPixels)
      ..didUpdateMetrics();

    _elapsedDuration = elapsedDuration;

    if (newPixels == destination) {
      owner.goIdle();
    }
  }

  @override
  void didChangeDimensions({
    required Size oldContentSize,
    required Size oldViewportSize,
    required EdgeInsets oldViewportInsets,
  }) {
    if (oldViewportInsets != owner.viewportInsets) {
      absorbBottomViewportInset(owner, oldViewportInsets);
    }

    _invalidateVelocity();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Updates [_velocity] based on the remaining time and distance to the
  /// destination position.
  ///
  /// Make sure to call this method on initialization and whenever the
  /// destination changes due to the viewport size or content size changing.
  ///
  /// If the animation [duration] is not specified, this method preserves the
  /// current velocity.
  void _invalidateVelocity() {
    if (duration case final duration?) {
      final remainingSeconds = (duration - _elapsedDuration).inMicroseconds /
          Duration.microsecondsPerSecond;
      final destination = this.destination.resolve(owner.contentSize);
      final pixels = owner.offset;
      _velocity = remainingSeconds > 0
          ? (destination - pixels).abs() / remainingSeconds
          : (destination - pixels).abs();
    }
  }
}

// TODO: Rename to `StableSheetActivity` or similar.
@internal
class IdleSheetActivity extends SheetActivity with IdleSheetActivityMixin {
  @override
  late final SheetAnchor targetOffset;

  @override
  void init(SheetPosition owner) {
    super.init(owner);
    targetOffset = owner.hasDimensions
        ? owner.snapGrid.getSnapOffset(owner, 0)
        : owner.initialPosition;
  }
}

@internal
class DragSheetActivity extends SheetActivity
    with UserControlledSheetActivityMixin
    implements SheetDragControllerTarget {
  DragSheetActivity();

  @override
  VerticalDirection get dragAxisDirection => VerticalDirection.up;

  @override
  Offset computeMinPotentialDeltaConsumption(Offset delta) {
    switch (delta.dy) {
      case > 0:
        final draggableDistance = max(0.0, owner.maxPixels - owner.offset);
        return Offset(delta.dx, min(draggableDistance, delta.dy));

      case < 0:
        final draggableDistance = max(0.0, owner.offset - owner.minOffset);
        return Offset(delta.dx, max(-1 * draggableDistance, delta.dy));

      case _:
        return delta;
    }
  }

  @override
  void onDragUpdate(SheetDragUpdateDetails details) {
    final physicsAppliedDelta =
        owner.physics.applyPhysicsToOffset(details.deltaY, owner);
    if (physicsAppliedDelta != 0) {
      owner
        ..setPixels(owner.offset + physicsAppliedDelta)
        ..didDragUpdateMetrics(details);
    }

    final overflow = owner.physics.computeOverflow(details.deltaY, owner);
    if (overflow != 0) {
      owner.didOverflowBy(overflow);
    }
  }

  @override
  void onDragEnd(SheetDragEndDetails details) {
    owner
      ..didDragEnd(details)
      ..goBallistic(details.velocityY);
  }

  @override
  void onDragCancel(SheetDragCancelDetails details) {
    owner
      ..didDragCancel()
      ..goBallistic(0);
  }
}

@internal
mixin IdleSheetActivityMixin<T extends SheetPosition> on SheetActivity<T> {
  SheetAnchor get targetOffset;

  @override
  SheetStatus get status => SheetStatus.stable;

  /// Updates [SheetMetrics.offset] to maintain the current [SheetAnchor], which
  /// is determined by [SnapGrid.getSnapOffset] using the metrics of
  /// the previous frame.
  @override
  void didChangeDimensions({
    required Size oldContentSize,
    required Size oldViewportSize,
    required EdgeInsets oldViewportInsets,
  }) {
    final newPixels = targetOffset.resolve(owner.contentSize);
    if (newPixels == owner.offset) {
      return;
    } else if (oldViewportInsets.bottom != owner.viewportInsets.bottom) {
      // TODO: Is it possible to remove this assumption?
      // We currently assume that when the bottom viewport inset changes,
      // it is due to the appearance or disappearance of the keyboard,
      // and that this change will gradually occur over several frames,
      // likely due to animation.
      owner
        ..setPixels(newPixels)
        ..didUpdateMetrics();
      return;
    }

    const minAnimationDuration = Duration(milliseconds: 150);
    const meanAnimationVelocity = 300 / 1000; // pixels per millisecond
    final distance = (newPixels - owner.offset).abs();
    final estimatedDuration = Duration(
      milliseconds: (distance / meanAnimationVelocity).round(),
    );
    if (estimatedDuration >= minAnimationDuration) {
      owner.animateTo(
        targetOffset,
        duration: estimatedDuration,
        curve: Curves.easeInOut,
      );
    } else {
      // The destination is close enough to the current position,
      // so we immediately snap to it without animation.
      owner
        ..setPixels(newPixels)
        ..didUpdateMetrics();
    }
  }
}

@internal
@optionalTypeArgs
mixin ControlledSheetActivityMixin<T extends SheetPosition>
    on SheetActivity<T> {
  late final AnimationController controller;

  final _completer = Completer<void>();

  Future<void> get done => _completer.future;

  @factory
  AnimationController createAnimationController();

  TickerFuture onAnimationStart();

  void onAnimationTick();

  void onAnimationEnd() {}

  @override
  double get velocity => controller.velocity;

  @override
  SheetStatus get status => SheetStatus.animating;

  @override
  void init(T delegate) {
    super.init(delegate);
    controller = createAnimationController()..addListener(onAnimationTick);
    // Won't trigger if we dispose 'animation' first.
    onAnimationStart().whenComplete(onAnimationEnd);
  }

  @override
  void dispose() {
    controller.dispose();
    _completer.complete();
    super.dispose();
  }
}

@internal
@optionalTypeArgs
mixin UserControlledSheetActivityMixin<T extends SheetPosition>
    on SheetActivity<T> {
  @override
  SheetStatus get status => SheetStatus.dragging;

  @override
  void didChangeDimensions({
    required Size oldContentSize,
    required Size oldViewportSize,
    required EdgeInsets oldViewportInsets,
  }) {
    assert(owner.hasDimensions);
    if (oldViewportInsets != owner.viewportInsets) {
      absorbBottomViewportInset(owner, oldViewportInsets);
    }
    // We don't call `goSettling` here because the user is still
    // manually controlling the sheet position.
  }
}

/// Appends the negative delta of the bottom viewport inset, which is typically
/// equal to the height of the on-screen keyboard, to the [activityOwner]'s
/// `pixels` to maintain the visual sheet position.
@internal
void absorbBottomViewportInset(
  SheetPosition activityOwner,
  EdgeInsets oldViewportInsets,
) {
  final newInsets = activityOwner.viewportInsets;
  final oldInsets = oldViewportInsets;
  final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;
  final newPixels = activityOwner.offset - deltaInsetBottom;
  if (newPixels != activityOwner.offset) {
    activityOwner
      ..setPixels(newPixels)
      ..didUpdateMetrics();
  }
}

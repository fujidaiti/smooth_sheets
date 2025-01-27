import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'drag.dart';
import 'model.dart';
import 'physics.dart';
import 'snap_grid.dart';

@internal
@optionalTypeArgs
abstract class SheetActivity<T extends SheetModel> {
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

  bool isCompatibleWith(SheetModel newOwner) => newOwner is T;

  void didChangeMeasurements(SheetMeasurements oldMeasurements) {
    if (owner.measurements.viewportInsets != oldMeasurements.viewportInsets) {
      absorbBottomViewportInset(owner, oldMeasurements.viewportInsets);
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

/// An activity that animates the [SheetModel]'s `offset` to a destination
/// position determined by [destination], using the specified [curve] and
/// [duration].
///
/// This activity accepts the destination position as an [SheetOffset], allowing
/// the concrete end position (in offset) to be updated during the animation
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

  final SheetOffset destination;
  final Duration duration;
  final Curve curve;

  late final double _startOffset;
  late final double _endOffset;

  @override
  void init(SheetModel delegate) {
    super.init(delegate);
    _startOffset = owner.offset;
    _endOffset = destination.resolve(owner.measurements);
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
      ..setOffset(lerpDouble(_startOffset, _endOffset, progress)!)
      ..didUpdateGeometry();
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
  }

  @override
  void didChangeMeasurements(SheetMeasurements oldMeasurements) {
    if (owner.measurements.viewportInsets != oldMeasurements.viewportInsets) {
      absorbBottomViewportInset(owner, oldMeasurements.viewportInsets);
    }
    final newEndOffset = destination.resolve(owner.measurements);
    if (newEndOffset != _endOffset) {
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
        ..setOffset(controller.value)
        ..didUpdateGeometry();
    }
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
  }

  @override
  void didChangeMeasurements(SheetMeasurements oldMeasurements) {
    final oldMetrics = owner.copyWith(measurements: oldMeasurements);
    final destination = owner.snapGrid.getSnapOffset(oldMetrics, velocity);

    if (owner.measurements.viewportInsets != oldMeasurements.viewportInsets) {
      absorbBottomViewportInset(owner, oldMeasurements.viewportInsets);
    }

    final endOffset = destination.resolve(owner.measurements);
    if (endOffset == owner.offset) {
      return;
    }

    const maxSettlingDuration = 150; // milliseconds
    final distance = (endOffset - owner.offset).abs();
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
/// A [SheetModel] may start this activity when the viewport insets change
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
  final SheetOffset destination;

  late final Ticker _ticker;

  /// The amount of time that has passed between the time the animation
  /// started and the most recent tick of the animation.
  var _elapsedDuration = Duration.zero;

  @override
  double get velocity => _velocity;
  late double _velocity;

  @override
  void init(SheetModel owner) {
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
    final destination = this.destination.resolve(owner.measurements);
    final offset = owner.offset;
    final newOffset = destination > offset
        ? min(destination, offset + velocity * elapsedFrameTime)
        : max(destination, offset - velocity * elapsedFrameTime);
    owner
      ..setOffset(newOffset)
      ..didUpdateGeometry();

    _elapsedDuration = elapsedDuration;

    if (newOffset == destination) {
      owner.goIdle();
    }
  }

  @override
  void didChangeMeasurements(SheetMeasurements oldMeasurements) {
    if (owner.measurements.viewportInsets != oldMeasurements.viewportInsets) {
      absorbBottomViewportInset(owner, oldMeasurements.viewportInsets);
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
      final destination = this.destination.resolve(owner.measurements);
      final offset = owner.offset;
      _velocity = remainingSeconds > 0
          ? (destination - offset).abs() / remainingSeconds
          : (destination - offset).abs();
    }
  }
}

// TODO: Rename to `StableSheetActivity` or similar.
@internal
class IdleSheetActivity extends SheetActivity with IdleSheetActivityMixin {
  @override
  late final SheetOffset targetOffset;

  @override
  void init(SheetModel owner) {
    super.init(owner);
    targetOffset = owner.hasMetrics
        ? owner.snapGrid.getSnapOffset(owner, 0)
        : owner.initialOffset;
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
        final draggableDistance = max(0.0, owner.maxOffset - owner.offset);
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
        ..setOffset(owner.offset + physicsAppliedDelta)
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
mixin IdleSheetActivityMixin<T extends SheetModel> on SheetActivity<T> {
  SheetOffset get targetOffset;

  /// Updates [SheetMetrics.offset] to maintain the current [SheetOffset], which
  /// is determined by [SheetSnapGrid.getSnapOffset] using the metrics of
  /// the previous frame.
  @override
  void didChangeMeasurements(SheetMeasurements oldMeasurements) {
    final newOffset = targetOffset.resolve(owner.measurements);
    if (newOffset == owner.offset) {
      return;
    } else if (owner.measurements.viewportInsets.bottom !=
        oldMeasurements.viewportInsets.bottom) {
      // TODO: Is it possible to remove this assumption?
      // We currently assume that when the bottom viewport inset changes,
      // it is due to the appearance or disappearance of the keyboard,
      // and that this change will gradually occur over several frames,
      // likely due to animation.
      owner
        ..setOffset(newOffset)
        ..didUpdateGeometry();
      return;
    }

    const minAnimationDuration = Duration(milliseconds: 150);
    const meanAnimationVelocity = 300 / 1000; // offset per millisecond
    final distance = (newOffset - owner.offset).abs();
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
        ..setOffset(newOffset)
        ..didUpdateGeometry();
    }
  }
}

@internal
@optionalTypeArgs
mixin ControlledSheetActivityMixin<T extends SheetModel> on SheetActivity<T> {
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
mixin UserControlledSheetActivityMixin<T extends SheetModel>
    on SheetActivity<T> {
  @override
  void didChangeMeasurements(SheetMeasurements oldMeasurements) {
    if (owner.measurements.viewportInsets != oldMeasurements.viewportInsets) {
      absorbBottomViewportInset(owner, oldMeasurements.viewportInsets);
    }
    // We don't call `goSettling` here because the user is still
    // manually controlling the sheet position.
  }
}

/// Appends the negative delta of the bottom viewport inset, which is typically
/// equal to the height of the on-screen keyboard, to the [activityOwner]'s
/// `offset` to maintain the visual sheet position.
@internal
void absorbBottomViewportInset(
  SheetModel activityOwner,
  EdgeInsets oldViewportInsets,
) {
  final newInsets = activityOwner.measurements.viewportInsets;
  final oldInsets = oldViewportInsets;
  final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;
  final newOffset = activityOwner.offset - deltaInsetBottom;
  if (newOffset != activityOwner.offset) {
    activityOwner
      ..setOffset(newOffset)
      ..didUpdateGeometry();
  }
}

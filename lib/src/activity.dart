import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'drag.dart';
import 'model.dart';
import 'physics.dart';

@internal
@optionalTypeArgs
abstract class SheetActivity<T extends SheetModel> {
  var _disposed = false;

  bool get disposed {
    assert(!_mounted || !_disposed);
    return _disposed;
  }

  var _mounted = false;

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

  double dryApplyNewLayout(ViewportLayout layout) => owner.offset;

  void applyNewLayout(ViewportLayout oldLayout) {
    owner.offset = dryApplyNewLayout(owner);
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
  // ignore: avoid_renaming_method_parameters
  void init(SheetModel delegate) {
    super.init(delegate);
    _startOffset = owner.offset;
    _endOffset = destination.resolve(owner);
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
      ..offset = lerpDouble(_startOffset, _endOffset, progress)!
      ..didUpdateMetrics();
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
  }

  @override
  void applyNewLayout(ViewportLayout oldLayout) {
    final newEndOffset = destination.resolve(owner);
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
        ..offset = controller.value
        ..didUpdateMetrics();
    }
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
  }

  @override
  void applyNewLayout(ViewportLayout oldLayout) {
    final destination = owner.snapGrid.getSnapOffset(
      oldLayout,
      owner.offset,
      velocity,
    );
    final endOffset = destination.resolve(owner);
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
  Duration _elapsedDuration = Duration.zero;

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
    final destination = this.destination.resolve(owner);
    final offset = owner.offset;
    final newOffset = destination > offset
        ? min(destination, offset + velocity * elapsedFrameTime)
        : max(destination, offset - velocity * elapsedFrameTime);
    owner
      ..offset = newOffset
      ..didUpdateMetrics();

    _elapsedDuration = elapsedDuration;

    if (newOffset == destination) {
      owner.goIdle();
    }
  }

  @override
  void applyNewLayout(ViewportLayout oldLayout) {
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
      final destination = this.destination.resolve(owner);
      final offset = owner.offset;
      _velocity = remainingSeconds > 0
          ? (destination - offset).abs() / remainingSeconds
          : (destination - offset).abs();
    }
  }
}

// TODO: Rename to `StableSheetActivity` or similar.
@internal
class IdleSheetActivity<T extends SheetModel> extends SheetActivity<T> {
  late SheetOffset targetOffset;

  @override
  void init(T owner) {
    super.init(owner);
    targetOffset = owner.hasMetrics
        ? owner.snapGrid.getSnapOffset(owner, owner.offset, 0)
        : owner.initialOffset;
  }

  @override
  double dryApplyNewLayout(ViewportLayout layout) =>
      targetOffset.resolve(layout);

  /// Updates [SheetMetrics.offset] to maintain the [targetOffset].
  @override
  void applyNewLayout(ViewportLayout oldLayout) {
    final newOffset = dryApplyNewLayout(owner);
    if (newOffset != owner.offset) {
      owner
        ..offset = newOffset
        ..didUpdateMetrics();
    }
  }
}

@internal
class DragSheetActivity<T extends SheetModel> extends SheetActivity<T>
    implements SheetDragControllerTarget {
  DragSheetActivity({
    required this.startDetails,
    required this.cancelCallback,
    this.carriedVelocity,
  });

  final DragStartDetails startDetails;
  final VoidCallback cancelCallback;
  final double? carriedVelocity;
  late final SheetDragController drag;

  @override
  VerticalDirection get dragAxisDirection => VerticalDirection.up;

  @override
  void init(T owner) {
    super.init(owner);
    var startDetails = SheetDragStartDetails(
      sourceTimeStamp: this.startDetails.sourceTimeStamp,
      axisDirection: dragAxisDirection,
      localPositionX: this.startDetails.localPosition.dx,
      localPositionY: this.startDetails.localPosition.dy,
      globalPositionX: this.startDetails.globalPosition.dx,
      globalPositionY: this.startDetails.globalPosition.dy,
      kind: this.startDetails.kind,
    );
    if (owner.gestureProxy case final proxy?) {
      startDetails = proxy.onDragStart(startDetails);
    }

    drag = SheetDragController(
      target: this,
      gestureProxy: () => owner.gestureProxy,
      details: startDetails,
      onDragCanceled: cancelCallback,
      carriedVelocity: carriedVelocity,
      motionStartDistanceThreshold:
          owner.physics.dragStartDistanceMotionThreshold,
    );

    owner.didDragStart(startDetails);
  }

  @override
  void dispose() {
    drag.dispose();
    super.dispose();
  }

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
        ..offset = owner.offset + physicsAppliedDelta
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
  void init(T owner) {
    super.init(owner);
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

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_drag.dart';
import 'sheet_extent.dart';
import 'sheet_status.dart';

@internal
@optionalTypeArgs
abstract class SheetActivity<T extends SheetExtent> {
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

  bool isCompatibleWith(SheetExtent newOwner) => newOwner is T;

  void didChangeContentSize(Size? oldSize) {}

  void didChangeViewportDimensions(Size? oldSize, EdgeInsets? oldInsets) {}

  void didChangeBoundaryConstraints(
    double? oldMinPixels,
    double? oldMaxPixels,
  ) {}

  void didFinalizeDimensions(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    if (oldContentSize == null && oldViewportSize == null) {
      // The sheet was laid out, but not changed in size.
      return;
    }

    final metrics = owner.metrics;
    final oldPixels = metrics.pixels;
    final newInsets = metrics.viewportInsets;
    final oldInsets = oldViewportInsets ?? newInsets;
    final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;

    switch (deltaInsetBottom) {
      case > 0:
        // Prevents the sheet from being pushed off the screen by the keyboard.
        final correction = min(0.0, metrics.maxViewPixels - metrics.viewPixels);
        owner.setPixels(oldPixels + correction);

      case < 0:
        // Appends the delta of the bottom inset (typically the keyboard height)
        // to keep the visual sheet position unchanged.
        owner.setPixels(
          min(oldPixels - deltaInsetBottom, owner.metrics.maxPixels),
        );
    }

    owner.settle();
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

@internal
class AnimatedSheetActivity extends SheetActivity
    with ControlledSheetActivityMixin {
  AnimatedSheetActivity({
    required this.destination,
    required this.duration,
    required this.curve,
  }) : assert(duration > Duration.zero);

  final Extent destination;
  final Duration duration;
  final Curve curve;

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(
      value: owner.metrics.pixels,
      vsync: owner.context.vsync,
    );
  }

  @override
  TickerFuture onAnimationStart() {
    return controller.animateTo(
      destination.resolve(owner.metrics.contentSize),
      duration: duration,
      curve: curve,
    );
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
  }

  @override
  void didFinalizeDimensions(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    // 1. Appends the delta of the bottom inset (typically the keyboard height)
    // to keep the visual sheet position unchanged.
    final newInsets = owner.metrics.viewportInsets;
    final oldInsets = oldViewportInsets ?? newInsets;
    final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;
    owner.setPixels(owner.metrics.pixels - deltaInsetBottom);

    // 2. If the animation is still running, we start a new linear animation
    // to bring the sheet position to the recalculated final position in the
    // remaining duration. We use a linear curve here because starting a curved
    // animation in the middle of another curved animation tends to look jerky.
    final newDestination = destination.resolve(owner.metrics.contentSize);
    final elapsedDuration = controller.lastElapsedDuration ?? duration;
    if (newDestination != controller.upperBound && elapsedDuration < duration) {
      final carriedDuration = duration - elapsedDuration;
      owner.animateTo(destination,
          duration: carriedDuration, curve: Curves.linear);
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
  void onAnimationEnd() {
    owner.goBallistic(0);
  }
}

@internal
class IdleSheetActivity extends SheetActivity {
  @override
  SheetStatus get status => SheetStatus.stable;
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
    final metrics = owner.metrics;

    switch (delta.dy) {
      case > 0:
        final draggableDistance = max(0.0, metrics.maxPixels - metrics.pixels);
        return Offset(delta.dx, min(draggableDistance, delta.dy));

      case < 0:
        final draggableDistance = max(0.0, metrics.pixels - metrics.minPixels);
        return Offset(delta.dx, max(-1 * draggableDistance, delta.dy));

      case _:
        return delta;
    }
  }

  @override
  void applyUserDragUpdate(Offset offset) {
    final physicsAppliedDelta =
        owner.physics.applyPhysicsToOffset(offset.dy, owner.metrics);
    if (physicsAppliedDelta != 0) {
      owner.setPixels(owner.metrics.pixels + physicsAppliedDelta);
    }
  }

  @override
  void applyUserDragEnd(Velocity velocity) {
    owner.goBallistic(velocity.pixelsPerSecond.dy);
  }
}

@internal
@optionalTypeArgs
mixin ControlledSheetActivityMixin<T extends SheetExtent> on SheetActivity<T> {
  late final AnimationController controller;
  late double _lastAnimatedValue;

  final _completer = Completer<void>();
  Future<void> get done => _completer.future;

  @factory
  AnimationController createAnimationController();
  TickerFuture onAnimationStart();
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
    _lastAnimatedValue = controller.value;
  }

  void onAnimationTick() {
    if (mounted) {
      final oldPixels = owner.metrics.pixels;
      owner.setPixels(oldPixels + controller.value - _lastAnimatedValue);
      _lastAnimatedValue = controller.value;
    }
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
mixin UserControlledSheetActivityMixin<T extends SheetExtent>
    on SheetActivity<T> {
  @override
  SheetStatus get status => SheetStatus.dragging;

  @override
  void didFinalizeDimensions(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    assert(owner.metrics.hasDimensions);

    final newInsets = owner.metrics.viewportInsets;
    final oldInsets = oldViewportInsets ?? newInsets;
    final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;
    // Appends the delta of the bottom inset (typically the keyboard height)
    // to keep the visual sheet position unchanged.
    owner.setPixels(owner.metrics.pixels - deltaInsetBottom);
    // We don't call `goSettling` here because the user is still
    // manually controlling the sheet position.
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'notifications.dart';
import 'sheet_extent.dart';
import 'sheet_status.dart';

abstract class SheetActivity extends ChangeNotifier {
  bool _mounted = false;
  bool get mounted => _mounted;

  double? _pixels;
  double? get pixels => _pixels;

  SheetExtent? _delegate;
  SheetExtent get delegate {
    assert(
      _delegate != null,
      '$SheetActivity must be initialized with initWith().',
    );
    return _delegate!;
  }

  double get velocity => 0.0;

  SheetStatus get status;

  @mustCallSuper
  void initWith(SheetExtent delegate) {
    assert(
      _delegate == null,
      'initWith() must be called only once.',
    );

    _delegate = delegate;
    _mounted = true;
  }

  @protected
  void correctPixels(double pixels) {
    _pixels = pixels;
  }

  @protected
  void setPixels(double pixels) {
    final oldPixels = _pixels;
    correctPixels(pixels);
    if (_pixels != oldPixels) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void dispatchUpdateNotification() {
    if (delegate.metrics.hasDimensions) {
      dispatchNotification(
        SheetUpdateNotification(
          metrics: delegate.metrics,
          status: delegate.status,
        ),
      );
    }
  }

  void dispatchDragStartNotification(DragStartDetails details) {
    if (delegate.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragStartNotification(
          metrics: delegate.metrics,
          status: delegate.status,
          dragDetails: details,
        ),
      );
    }
  }

  void dispatchDragEndNotification(DragEndDetails details) {
    if (delegate.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragEndNotification(
          metrics: delegate.metrics,
          status: delegate.status,
          dragDetails: details,
        ),
      );
    }
  }

  void dispatchDragUpdateNotification({required double delta}) {
    if (delegate.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragUpdateNotification(
          metrics: delegate.metrics,
          status: delegate.status,
          delta: delta,
        ),
      );
    }
  }

  void dispatchDragCancelNotification() {
    if (delegate.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragCancelNotification(
          metrics: delegate.metrics,
          status: delegate.status,
        ),
      );
    }
  }

  void dispatchOverflowNotification(double overflow) {
    if (delegate.metrics.hasDimensions) {
      dispatchNotification(
        SheetOverflowNotification(
          metrics: delegate.metrics,
          status: delegate.status,
          overflow: overflow,
        ),
      );
    }
  }

  void dispatchNotification(SheetNotification notification) {
    // Avoid dispatching a notification in the middle of a build.
    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.postFrameCallbacks:
        notification.dispatch(delegate.context.notificationContext);
      case SchedulerPhase.idle:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
      case SchedulerPhase.transientCallbacks:
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notification.dispatch(delegate.context.notificationContext);
        });
    }
  }

  void takeOver(SheetActivity other) {
    if (other.pixels != null) {
      correctPixels(other.pixels!);
    }
  }

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
    assert(pixels != null);
    assert(delegate.metrics.hasDimensions);

    if (oldContentSize == null && oldViewportSize == null) {
      // The sheet was laid out, but not changed in size.
      return;
    }

    final oldPixels = pixels!;
    final metrics = delegate.metrics;
    final newInsets = metrics.viewportInsets;
    final oldInsets = oldViewportInsets ?? newInsets;
    final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;

    switch (deltaInsetBottom) {
      case > 0:
        // Prevents the sheet from being pushed off the screen by the keyboard.
        final correction = min(0.0, metrics.maxViewPixels - metrics.viewPixels);
        setPixels(oldPixels + correction);

      case < 0:
        // Appends the delta of the bottom inset (typically the keyboard height)
        // to keep the visual sheet position unchanged.
        setPixels(
          min(oldPixels - deltaInsetBottom, delegate.metrics.maxPixels),
        );
    }

    delegate.settle();
  }
}

class AnimatedSheetActivity extends SheetActivity
    with ControlledSheetActivityMixin {
  AnimatedSheetActivity({
    required this.from,
    required this.to,
    required this.duration,
    required this.curve,
  }) : assert(duration > Duration.zero);

  final double from;
  final double to;
  final Duration duration;
  final Curve curve;

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(
        value: from, vsync: delegate.context.vsync);
  }

  @override
  TickerFuture onAnimationStart() {
    return controller.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void onAnimationEnd() {
    delegate.goBallistic(0);
  }
}

class BallisticSheetActivity extends SheetActivity
    with ControlledSheetActivityMixin {
  BallisticSheetActivity({
    required this.simulation,
  });

  final Simulation simulation;

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(vsync: delegate.context.vsync);
  }

  @override
  TickerFuture onAnimationStart() {
    return controller.animateWith(simulation);
  }

  @override
  void onAnimationEnd() {
    delegate.goBallistic(0);
  }
}

class IdleSheetActivity extends SheetActivity {
  @override
  SheetStatus get status => SheetStatus.stable;
}

class UserDragSheetActivity extends SheetActivity
    with UserControlledSheetActivityMixin {
  UserDragSheetActivity({
    required this.gestureRecognizer,
  });

  final DragGestureRecognizer gestureRecognizer;

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    gestureRecognizer
      ..onUpdate = onDragUpdate
      ..onEnd = onDragEnd
      ..onCancel = onDragCancel;
  }

  @override
  void dispose() {
    super.dispose();
    gestureRecognizer
      ..onUpdate = null
      ..onEnd = null
      ..onCancel = null;
  }

  @protected
  void onDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    final delta = -1 * details.primaryDelta!;
    final physicsAppliedDelta =
        delegate.config.physics.applyPhysicsToOffset(delta, delegate.metrics);
    if (physicsAppliedDelta != 0) {
      setPixels(pixels! + physicsAppliedDelta);
      dispatchDragUpdateNotification(delta: physicsAppliedDelta);
    }
  }

  @protected
  void onDragEnd(DragEndDetails details) {
    if (!mounted) return;
    dispatchDragEndNotification(details);
    delegate.goBallistic(-1 * details.velocity.pixelsPerSecond.dy);
  }

  @protected
  void onDragCancel() {
    if (!mounted) return;
    dispatchDragCancelNotification();
    delegate.goBallistic(0);
  }
}

mixin ControlledSheetActivityMixin on SheetActivity {
  late final AnimationController controller;
  late double _lastAnimatedValue;

  final _completer = Completer<void>();
  Future<void> get done => _completer.future;

  AnimationController createAnimationController();
  TickerFuture onAnimationStart();
  void onAnimationEnd() {}

  @override
  double get velocity => controller.velocity;

  @override
  SheetStatus get status => SheetStatus.controlled;

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    controller = createAnimationController()..addListener(onAnimationTick);
    // Won't trigger if we dispose 'animation' first.
    onAnimationStart().whenComplete(onAnimationEnd);
    _lastAnimatedValue = controller.value;
  }

  void onAnimationTick() {
    if (mounted) {
      final oldPixels = pixels;
      setPixels(pixels! + controller.value - _lastAnimatedValue);
      if (pixels != oldPixels) {
        dispatchUpdateNotification();
      }
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

mixin UserControlledSheetActivityMixin on SheetActivity {
  @override
  SheetStatus get status => SheetStatus.userControlled;

  @override
  void didFinalizeDimensions(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    assert(pixels != null);
    assert(delegate.metrics.hasDimensions);

    final newInsets = delegate.metrics.viewportInsets;
    final oldInsets = oldViewportInsets ?? newInsets;
    final deltaInsetBottom = newInsets.bottom - oldInsets.bottom;
    // Appends the delta of the bottom inset (typically the keyboard height)
    // to keep the visual sheet position unchanged.
    setPixels(pixels! - deltaInsetBottom);
    // We don't call `goSettling` here because the user is still
    // manually controlling the sheet position.
  }
}

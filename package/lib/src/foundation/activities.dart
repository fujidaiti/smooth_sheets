import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'notifications.dart';
import 'sheet_extent.dart';
import 'sheet_status.dart';

abstract class SheetActivity {
  bool _mounted = false;
  bool get mounted => _mounted;

  SheetExtent? _owner;
  SheetExtent get owner {
    assert(
      _owner != null,
      '$SheetActivity must be initialized with init().',
    );
    return _owner!;
  }

  double get velocity => 0.0;

  SheetStatus get status;

  @mustCallSuper
  void init(SheetExtent owner) {
    assert(
      _owner == null,
      'init() must be called only once.',
    );

    _owner = owner;
    _mounted = true;
  }

  @mustCallSuper
  void updateOwner(SheetExtent owner) {
    _owner = owner;
  }

  void dispose() {
    _mounted = false;
  }

  void dispatchUpdateNotification() {
    if (owner.metrics.hasDimensions) {
      dispatchNotification(
        SheetUpdateNotification(
          metrics: owner.metrics,
          status: owner.status,
        ),
      );
    }
  }

  void dispatchDragStartNotification(DragStartDetails details) {
    if (owner.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragStartNotification(
          metrics: owner.metrics,
          status: owner.status,
          dragDetails: details,
        ),
      );
    }
  }

  void dispatchDragEndNotification(DragEndDetails details) {
    if (owner.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragEndNotification(
          metrics: owner.metrics,
          status: owner.status,
          dragDetails: details,
        ),
      );
    }
  }

  void dispatchDragUpdateNotification({required double delta}) {
    if (owner.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragUpdateNotification(
          metrics: owner.metrics,
          status: owner.status,
          delta: delta,
        ),
      );
    }
  }

  void dispatchDragCancelNotification() {
    if (owner.metrics.hasDimensions) {
      dispatchNotification(
        SheetDragCancelNotification(
          metrics: owner.metrics,
          status: owner.status,
        ),
      );
    }
  }

  void dispatchOverflowNotification(double overflow) {
    if (owner.metrics.hasDimensions) {
      dispatchNotification(
        SheetOverflowNotification(
          metrics: owner.metrics,
          status: owner.status,
          overflow: overflow,
        ),
      );
    }
  }

  void dispatchNotification(SheetNotification notification) {
    // Avoid dispatching a notification in the middle of a build.
    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.postFrameCallbacks:
        notification.dispatch(owner.context.notificationContext);
      case SchedulerPhase.idle:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
      case SchedulerPhase.transientCallbacks:
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notification.dispatch(owner.context.notificationContext);
        });
    }
  }

  bool isCompatibleWith(SheetExtent newOwner) => true;

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
        value: from, vsync: owner.context.vsync);
  }

  @override
  TickerFuture onAnimationStart() {
    return controller.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void onAnimationEnd() {
    owner.goBallistic(0);
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
  void init(SheetExtent owner) {
    super.init(owner);
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
        owner.config.physics.applyPhysicsToOffset(delta, owner.metrics);
    if (physicsAppliedDelta != 0) {
      owner.setPixels(owner.metrics.pixels + physicsAppliedDelta);
      dispatchDragUpdateNotification(delta: physicsAppliedDelta);
    }
  }

  @protected
  void onDragEnd(DragEndDetails details) {
    if (!mounted) return;
    dispatchDragEndNotification(details);
    owner.goBallistic(-1 * details.velocity.pixelsPerSecond.dy);
  }

  @protected
  void onDragCancel() {
    if (!mounted) return;
    dispatchDragCancelNotification();
    owner.goBallistic(0);
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
  void init(SheetExtent delegate) {
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
      if (owner.metrics.pixels != oldPixels) {
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

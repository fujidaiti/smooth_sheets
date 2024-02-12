import 'dart:async';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/foundation/notification.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';

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
    if (delegate.hasPixels) {
      dispatchNotification(
        SheetUpdateNotification(metrics: delegate.snapshot),
      );
    }
  }

  void dispatchDragUpdateNotification({required double delta}) {
    if (delegate.hasPixels) {
      dispatchNotification(
        SheetDragUpdateNotification(
          metrics: delegate.snapshot,
          delta: delta,
        ),
      );
    }
  }

  void dispatchOverflowNotification(double overflow) {
    if (delegate.hasPixels) {
      dispatchNotification(
        SheetOverflowNotification(
          metrics: delegate.snapshot,
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
    _oldContentDimensions = other._oldContentDimensions;
    _oldViewportDimensions = other._oldViewportDimensions;
  }

  Size? _oldContentDimensions;
  ViewportDimensions? _oldViewportDimensions;

  @mustCallSuper
  void didChangeContentDimensions(Size? oldDimensions) {
    _oldContentDimensions = oldDimensions;
  }

  @mustCallSuper
  void didChangeViewportDimensions(ViewportDimensions? oldDimensions) {
    _oldViewportDimensions = oldDimensions;
  }

  void didFinalizeDimensions() {
    assert(pixels != null);
    assert(delegate.hasPixels);

    final oldPixels = pixels!;
    final metrics = delegate.metrics;
    final newInsets = metrics.viewportDimensions.insets;
    final oldInsets = _oldViewportDimensions?.insets ?? newInsets;
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

    if (metrics.contentDimensions != _oldContentDimensions ||
        metrics.viewportDimensions != _oldViewportDimensions) {
      // delegate.goBallistic(0.0);

      final parentPhysics = delegate.physics.parent;
      final detent = (parentPhysics! as SnappingSheetPhysics)
          .snappingBehavior
          .findSnapPixels(0, delegate.metrics);
      if (detent != null) {
        delegate.animateTo(Extent.pixels(detent),
            duration: const Duration(milliseconds: 200), curve: Curves.linear);
      }
    }
  }
}

class AnimatedSheetActivity extends SheetActivity
    with DrivenSheetActivityMixin {
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
  TickerFuture startAnimation() {
    return controller.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void onAnimationEnd() {
    delegate.goBallistic(0);
  }
}

class BallisticSheetActivity extends SheetActivity
    with DrivenSheetActivityMixin {
  BallisticSheetActivity({
    required this.simulation,
  });

  final Simulation simulation;

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(vsync: delegate.context.vsync);
  }

  @override
  TickerFuture startAnimation() {
    return controller.animateWith(simulation);
  }

  @override
  void onAnimationEnd() {
    delegate.goIdle();
  }
}

class IdleSheetActivity extends SheetActivity {}

mixin DrivenSheetActivityMixin on SheetActivity {
  late final AnimationController controller;
  late double _lastAnimatedValue;

  final _completer = Completer<void>();
  Future<void> get done => _completer.future;

  AnimationController createAnimationController();
  TickerFuture startAnimation();
  void onAnimationEnd() {}

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    controller = createAnimationController()..addListener(onAnimationTick);
    // Won't trigger if we dispose 'animation' first.
    startAnimation().whenComplete(onAnimationEnd);
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

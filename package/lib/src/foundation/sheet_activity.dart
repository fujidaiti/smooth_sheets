import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:smooth_sheets/src/foundation/notification.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

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
  }

  void didChangeContentDimensions(Size? oldDimensions) {
    if (pixels != null) {
      setPixels(
        delegate.physics
            .adjustPixelsForNewBoundaryConditions(pixels!, delegate.metrics),
      );
      delegate.goBallistic(0);
    }
  }

  void didChangeViewportDimensions(ViewportDimensions? oldDimensions) {}
}

class DrivenSheetActivity extends SheetActivity {
  DrivenSheetActivity({
    required this.from,
    required this.to,
    required this.duration,
    required this.curve,
  }) : assert(duration > Duration.zero);

  final double from;
  final double to;
  final Duration duration;
  final Curve curve;

  late final AnimationController _animation;

  final _completer = Completer<void>();

  Future<void> get done => _completer.future;

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    _animation = AnimationController.unbounded(
      value: from,
      vsync: delegate.context.vsync,
    )
      ..addListener(onAnimationTick)
      ..animateTo(to, duration: duration, curve: curve)
          // Won't trigger if we dispose 'animation' first.
          .whenComplete(onAnimationEnd);
  }

  @protected
  void onAnimationTick() {
    final oldPixels = pixels;
    setPixels(_animation.value);
    if (pixels != oldPixels) {
      dispatchUpdateNotification();
    }
  }

  @protected
  void onAnimationEnd() => delegate.goBallistic(0);

  @override
  void dispose() {
    _completer.complete();
    _animation.dispose();
    super.dispose();
  }
}

class BallisticSheetActivity extends SheetActivity {
  BallisticSheetActivity({
    required this.simulation,
  });

  final Simulation simulation;
  late final AnimationController controller;

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);

    controller = AnimationController.unbounded(vsync: delegate.context.vsync)
      ..addListener(onTick)
      ..animateWith(simulation).whenComplete(onEnd);
  }

  void onTick() {
    final oldPixels = pixels;
    setPixels(controller.value);
    if (pixels != oldPixels) {
      dispatchUpdateNotification();
    }
  }

  void onEnd() {
    delegate.goIdle();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class IdleSheetActivity extends SheetActivity {}

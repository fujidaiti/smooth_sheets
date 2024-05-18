import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import 'drag_controller.dart';
import 'sheet_extent.dart';
import 'sheet_status.dart';

// TODO: Add type parameter T that extends SheetExtent.
abstract class SheetActivity {
  bool _mounted = false;
  bool get mounted => _mounted;

  SheetExtent? _owner;
  SheetExtent get owner {
    assert(debugAssertMounted());
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

class DragSheetActivity extends SheetActivity
    with UserControlledSheetActivityMixin
    implements SheetDragDelegate {
  DragSheetActivity();

  @override
  AxisDirection get dragAxisDirection => AxisDirection.up;

  @override
  void onDragUpdate(double delta) {
    final physicsAppliedDelta =
        owner.config.physics.applyPhysicsToOffset(delta, owner.metrics);
    if (physicsAppliedDelta != 0) {
      owner.setPixels(owner.metrics.pixels + physicsAppliedDelta);
    }
  }

  @override
  void onDragEnd(double velocity) {
    owner.goBallistic(velocity);
  }
}

mixin ControlledSheetActivityMixin on SheetActivity {
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

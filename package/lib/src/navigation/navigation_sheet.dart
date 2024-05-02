import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../foundation/activities.dart';
import '../foundation/framework.dart';
import '../foundation/keyboard_dismissible.dart';
import '../foundation/physics.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_status.dart';
import '../foundation/theme.dart';
import '../internal/transition_observer.dart';

typedef NavigationSheetTransitionObserver = TransitionObserver;

class NavigationSheet extends StatefulWidget with TransitionAwareWidgetMixin {
  const NavigationSheet({
    super.key,
    required this.transitionObserver,
    this.keyboardDismissBehavior,
    this.controller,
    required this.child,
  });

  @override
  final NavigationSheetTransitionObserver transitionObserver;

  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;
  final SheetController? controller;
  final Widget child;

  @override
  State<NavigationSheet> createState() => NavigationSheetState();
}

class NavigationSheetState extends State<NavigationSheet>
    with TransitionAwareStateMixin, TickerProviderStateMixin
    implements SheetContext {
  _NavigationSheetExtentProxy? _extent;

  @override
  TickerProvider get vsync => this;

  @override
  BuildContext? get notificationContext => mounted ? context : null;

  @override
  void didChangeTransitionState(Transition? transition) {
    // TODO: Provide a way to customize animation curves.
    final sheetActivity = switch (transition) {
      NoTransition(
        :final NavigationSheetRoute<dynamic> currentRoute,
      ) =>
        _ProxySheetActivity(
          target: currentRoute.pageExtent,
        ),
      ForwardTransition(
        :final NavigationSheetRoute<dynamic> originRoute,
        :final NavigationSheetRoute<dynamic> destinationRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          originExtent: originRoute.pageExtent,
          destinationExtent: destinationRoute.pageExtent,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ),
      BackwardTransition(
        :final NavigationSheetRoute<dynamic> originRoute,
        :final NavigationSheetRoute<dynamic> destinationRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          originExtent: originRoute.pageExtent,
          destinationExtent: destinationRoute.pageExtent,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ),
      UserGestureTransition(
        :final NavigationSheetRoute<dynamic> currentRoute,
        :final NavigationSheetRoute<dynamic> previousRoute,
        :final animation,
      ) =>
        _TransitionSheetActivity(
          originExtent: currentRoute.pageExtent,
          destinationExtent: previousRoute.pageExtent,
          animation: animation,
          animationCurve: Curves.linear,
        ),
      _ => IdleSheetActivity(),
    };

    _extent?.beginActivity(sheetActivity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        widget.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;

    Widget result = ImplicitSheetControllerScope(
      controller: widget.controller,
      builder: (context, controller) {
        return SheetContainer(
          controller: controller,
          config: const SheetExtentConfig(
            minExtent: Extent.pixels(0),
            maxExtent: Extent.proportional(1),
            // TODO: Use more appropriate physics.
            physics: ClampingSheetPhysics(),
            debugLabel: 'NavigationSheet',
          ),
          initializer: (extent) {
            final proxy = _NavigationSheetExtentProxy(inner: extent);
            _extent = proxy;
            return proxy;
          },
          child: widget.child,
        );
      },
    );

    if (keyboardDismissBehavior != null) {
      result = SheetKeyboardDismissible(
        dismissBehavior: keyboardDismissBehavior,
        child: result,
      );
    }

    return result;
  }
}

abstract class NavigationSheetRoute<T> extends PageRoute<T> {
  NavigationSheetRoute({
    super.settings,
  });

  NavigationSheetExtentDelegate get pageExtent;
}

// TODO: What a ugly interface!
abstract class NavigationSheetExtentDelegate implements Listenable {
  SheetMetrics get metrics;
  void applyNewViewportDimensions(ViewportDimensions viewportDimensions);
  void beginActivity(SheetActivity activity);
}

// class _NavigationSheetExtentConfig extends SheetExtentConfig {
//   const _NavigationSheetExtentConfig();

//   @override
//   bool shouldRebuild(BuildContext context, SheetExtent oldExtent) {
//     return oldExtent is! _NavigationSheetExtent;
//   }

//   @override
//   SheetExtent build(BuildContext context, SheetContext sheetContext) {
//     return _NavigationSheetExtent(
//       context: sheetContext,
//       // TODO: Use more appropriate physics.
//       physics: const ClampingSheetPhysics(),
//     );
//   }
// }

class _NavigationSheetExtentProxy extends _SheetExtentProxy {
  const _NavigationSheetExtentProxy({required super.inner});

  @override
  SheetMetrics get metrics => switch (activity) {
        _ProxySheetActivity(target: final target) => target.metrics,
        _TransitionSheetActivity(:final originExtent) => originExtent.metrics,
        _ => super.metrics,
      };

  @override
  void applyNewViewportDimensions(ViewportDimensions viewportDimensions) {
    super.applyNewViewportDimensions(viewportDimensions);
    _dispatchViewportDimensions();
  }

  @override
  void beginActivity(SheetActivity activity) {
    if (activity is _TransitionSheetActivity ||
        activity is _ProxySheetActivity ||
        activity is IdleSheetActivity) {
      super.beginActivity(activity);
      _dispatchViewportDimensions();
      return;
    }

    assert(
      this.activity is _ProxySheetActivity,
      'Cannot begin ${activity.runtimeType} '
      'while a transition is in progress.',
    );

    (this.activity as _ProxySheetActivity).target.beginActivity(activity);
  }

  void _dispatchViewportDimensions() {
    if (metrics.hasDimensions) {
      switch (activity) {
        case final _ProxySheetActivity activity:
          activity.target
              .applyNewViewportDimensions(metrics.viewportDimensions);

        case final _TransitionSheetActivity activity:
          activity.originExtent
              .applyNewViewportDimensions(metrics.viewportDimensions);
          activity.destinationExtent
              .applyNewViewportDimensions(metrics.viewportDimensions);
      }
    }
  }
}

class _TransitionSheetActivity extends SheetActivity {
  _TransitionSheetActivity({
    required this.originExtent,
    required this.destinationExtent,
    required this.animation,
    required this.animationCurve,
  });

  final NavigationSheetExtentDelegate originExtent;
  final NavigationSheetExtentDelegate destinationExtent;
  final Animation<double> animation;
  final Curve animationCurve;

  late final Animation<double> _curvedAnimation;

  @override
  SheetStatus get status => SheetStatus.controlled;

  @override
  void initWith(SheetExtent target) {
    super.initWith(target);
    _curvedAnimation = animation.drive(
      CurveTween(curve: animationCurve),
    )..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _curvedAnimation.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    if (originExtent.metrics.hasDimensions &&
        destinationExtent.metrics.hasDimensions) {
      final startPixels = originExtent.metrics.pixels;
      final endPixels = destinationExtent.metrics.pixels;
      setPixels(lerpDouble(startPixels, endPixels, _curvedAnimation.value)!);
      dispatchUpdateNotification();
    }
  }
}

class _ProxySheetActivity extends SheetActivity {
  _ProxySheetActivity({
    required this.target,
  });

  final NavigationSheetExtentDelegate target;

  @override
  SheetStatus get status => target.metrics.status;

  @override
  double? get pixels {
    if (target.metrics.hasDimensions) {
      // Sync the pixels to the delegate's pixels.
      correctPixels(target.metrics.pixels);
    }
    return super.pixels;
  }

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    target.addListener(_didChangeTargetExtent);
    _syncPixelsImplicitly();
  }

  @override
  void dispose() {
    target.removeListener(_didChangeTargetExtent);
    super.dispose();
  }

  void _didChangeTargetExtent() {
    setPixels(target.metrics.pixels);
  }

  void _syncPixelsImplicitly() {
    if (target.metrics.hasDimensions) {
      correctPixels(target.metrics.pixels);
    }
  }

  @override
  void didChangeContentSize(Size? oldSize) {
    super.didChangeContentSize(oldSize);
    _syncPixelsImplicitly();
  }
}

class _SheetExtentProxy implements SheetExtent {
  const _SheetExtentProxy({required this.inner});

  final SheetExtent inner;

  @override
  SheetActivity get activity => inner.activity;

  @override
  SheetExtentConfig get config => inner.config;

  @override
  SheetContext get context => inner.context;

  @override
  SheetExtentDelegate get delegate => inner.delegate;

  @override
  bool get hasListeners => inner.hasListeners;

  @override
  SheetMetrics get metrics => inner.metrics;

  @override
  void addListener(VoidCallback listener) => inner.addListener(listener);

  @override
  void notifyListeners() => inner.notifyListeners();

  @override
  void removeListener(VoidCallback listener) => inner.removeListener(listener);

  @override
  Future<void> animateTo(
    Extent newExtent, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      inner.animateTo(newExtent, curve: curve, duration: duration);

  @override
  void applyNewConfig(SheetExtentConfig config) => inner.applyNewConfig(config);

  @override
  void applyNewContentSize(Size contentSize) =>
      inner.applyNewContentSize(contentSize);

  @override
  void applyNewViewportDimensions(ViewportDimensions viewportDimensions) =>
      inner.applyNewViewportDimensions(viewportDimensions);

  @override
  void beginActivity(SheetActivity activity) => inner.beginActivity(activity);

  @override
  void dispose() => inner.dispose();

  @override
  void goBallistic(double velocity) => inner.goBallistic(velocity);

  @override
  void goBallisticWith(Simulation simulation) =>
      inner.goBallisticWith(simulation);

  @override
  void goIdle() => inner.goIdle();

  @override
  void settle() => settle();

  @override
  void takeOver(SheetExtent other) => inner.takeOver(other);

  @override
  void markAsDimensionsChanged() => inner.markAsDimensionsChanged();

  @override
  void markAsDimensionsWillChange() => inner.markAsDimensionsWillChange();

  @override
  void onDimensionsFinalized() => inner.onDimensionsFinalized();

  @override
  SheetMetrics get value => inner.value;
}

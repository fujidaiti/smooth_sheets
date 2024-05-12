import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  State<NavigationSheet> createState() => _NavigationSheetState();
}

class _NavigationSheetState extends State<NavigationSheet>
    with TransitionAwareStateMixin
    implements SheetExtentFactory {
  final _scopeKey = SheetExtentScopeKey<_NavigationSheetExtent>(
    debugLabel: kDebugMode ? 'NavigationSheet' : null,
  );

  @override
  void didChangeTransitionState(Transition? transition) {
    _scopeKey.maybeCurrentExtent?._handleRouteTransition(transition);
  }

  @factory
  @override
  SheetExtent createSheetExtent({
    required SheetContext context,
    required SheetExtentConfig config,
  }) {
    return _NavigationSheetExtent(
      context: context,
      config: config,
    );
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
          factory: this,
          scopeKey: _scopeKey,
          controller: controller,
          config: const SheetExtentConfig(
            minExtent: Extent.pixels(0),
            maxExtent: Extent.proportional(1),
            // TODO: Use more appropriate physics.
            physics: ClampingSheetPhysics(),
            debugLabel: kDebugMode ? 'NavigationSheet' : null,
          ),
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

class _NavigationSheetExtent extends SheetExtent {
  _NavigationSheetExtent({
    required super.context,
    required super.config,
  });

  final _localExtentScopeKeyRegistry = <Route<dynamic>, SheetExtentScopeKey>{};
  Transition? _lastReportedTransition;

  SheetExtentScopeKey createLocalExtentScopeKey(
    Route<dynamic> route,
    String? debugLabel,
  ) {
    assert(!_localExtentScopeKeyRegistry.containsKey(route));
    final key = SheetExtentScopeKey(debugLabel: debugLabel);
    _localExtentScopeKeyRegistry[route] = key;
    // Sync the viewport dimensions when the extent is created.
    key.addOnCreatedListener(() {
      final viewportSize = metrics.maybeViewportSize;
      final viewportInsets = metrics.maybeViewportInsets;
      if (viewportSize != null && viewportInsets != null) {
        key.currentExtent
            .applyNewViewportDimensions(viewportSize, viewportInsets);
      }
    });

    return key;
  }

  void disposeLocalExtentScopeKey(Route<dynamic> route) {
    assert(_localExtentScopeKeyRegistry.containsKey(route));
    final key = _localExtentScopeKeyRegistry.remove(route);
    key!.removeAllOnCreatedListeners();
  }

  SheetExtentScopeKey getLocalExtentScopeKey(Route<dynamic> route) {
    assert(_localExtentScopeKeyRegistry.containsKey(route));
    return _localExtentScopeKeyRegistry[route]!;
  }

  bool containsLocalExtentScopeKey(Route<dynamic> route) {
    return _localExtentScopeKeyRegistry.containsKey(route);
  }

  @override
  void takeOver(SheetExtent other) {
    super.takeOver(other);
    if (other is _NavigationSheetExtent) {
      assert(_localExtentScopeKeyRegistry.isEmpty);
      _lastReportedTransition = other._lastReportedTransition;
      _localExtentScopeKeyRegistry.addAll(other._localExtentScopeKeyRegistry);
      // Prevent the scope keys in `other._localExtentScopeKeyRegistry` from
      // being discarded when `other` is disposed.
      other._localExtentScopeKeyRegistry.clear();
      assert(_debugAssertActivityTypeConsistency());
    }
  }

  @override
  void applyNewViewportDimensions(Size size, EdgeInsets insets) {
    super.applyNewViewportDimensions(size, insets);
    for (final scopeKey in _localExtentScopeKeyRegistry.values) {
      scopeKey.maybeCurrentExtent?.applyNewViewportDimensions(size, insets);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final scopeKey in _localExtentScopeKeyRegistry.values) {
      scopeKey.removeAllOnCreatedListeners();
    }
    _localExtentScopeKeyRegistry.clear();
  }

  void _handleRouteTransition(Transition? transition) {
    _lastReportedTransition = transition;
    // TODO: Provide a way to customize animation curves.
    switch (transition) {
      case NoTransition(:final currentRoute):
        beginActivity(_ProxySheetActivity(route: currentRoute));

      case final ForwardTransition tr:
        beginActivity(_TransitionSheetActivity(
          currentRoute: tr.originRoute,
          nextRoute: tr.destinationRoute,
          animation: tr.animation,
          animationCurve: Curves.easeInOutCubic,
        ));

      case final BackwardTransition tr:
        beginActivity(_TransitionSheetActivity(
          currentRoute: tr.originRoute,
          nextRoute: tr.destinationRoute,
          animation: tr.animation,
          animationCurve: Curves.easeInOutCubic,
        ));

      case final UserGestureTransition tr:
        beginActivity(_TransitionSheetActivity(
          currentRoute: tr.currentRoute,
          nextRoute: tr.previousRoute,
          animation: tr.animation,
          animationCurve: Curves.linear,
        ));

      case _:
        goIdle();
    }

    assert(_debugAssertActivityTypeConsistency());
  }

  @override
  void goIdle() {
    switch (_lastReportedTransition) {
      case NoTransition(:final currentRoute):
        beginActivity(_ProxySheetActivity(route: currentRoute));
      case _:
        super.goIdle();
    }
  }

  bool _debugAssertActivityTypeConsistency() {
    assert(
      () {
        switch ((_lastReportedTransition, activity)) {
          case (NoTransition(), _ProxySheetActivity()):
          case (ForwardTransition(), _TransitionSheetActivity()):
          case (BackwardTransition(), _TransitionSheetActivity()):
          case (UserGestureTransition(), _TransitionSheetActivity()):
          case (null, _):
            return true;
          case _:
            return false;
        }
      }(),
    );
    return true;
  }
}

abstract class _NavigationSheetActivity extends SheetActivity {
  @override
  _NavigationSheetExtent get owner => super.owner as _NavigationSheetExtent;

  @override
  bool isCompatibleWith(SheetExtent newOwner) {
    return newOwner is _NavigationSheetExtent;
  }
}

class _TransitionSheetActivity extends _NavigationSheetActivity {
  _TransitionSheetActivity({
    required this.currentRoute,
    required this.nextRoute,
    required this.animation,
    required this.animationCurve,
  });

  final Route<dynamic> currentRoute;
  final Route<dynamic> nextRoute;
  final Animation<double> animation;
  final Curve animationCurve;
  late final Animation<double> _curvedAnimation;

  @override
  SheetStatus get status => SheetStatus.controlled;

  @override
  void init(SheetExtent target) {
    super.init(target);
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
    final fraction = _curvedAnimation.value;
    final startPixels = owner
        .getLocalExtentScopeKey(currentRoute)
        .maybeCurrentExtent
        ?.metrics
        .maybePixels;
    final endPixels = owner
        .getLocalExtentScopeKey(nextRoute)
        .maybeCurrentExtent
        ?.metrics
        .maybePixels;

    if (startPixels != null && endPixels != null) {
      owner.setPixels(lerpDouble(startPixels, endPixels, fraction)!);
      dispatchUpdateNotification();
    }
  }
}

class _ProxySheetActivity extends _NavigationSheetActivity {
  _ProxySheetActivity({required this.route});

  final Route<dynamic> route;

  SheetExtentScopeKey get _scopeKey => owner.getLocalExtentScopeKey(route);

  @override
  SheetStatus get status =>
      _scopeKey.maybeCurrentExtent?.status ?? SheetStatus.stable;

  @override
  void init(SheetExtent delegate) {
    super.init(delegate);
    _scopeKey.addOnCreatedListener(_init);
  }

  void _init() {
    if (mounted) {
      _scopeKey.currentExtent.addListener(_syncMetrics);
      _syncMetrics(notify: false);
    }
  }

  @override
  void dispose() {
    if (owner.containsLocalExtentScopeKey(route)) {
      _scopeKey
        ..maybeCurrentExtent?.removeListener(_syncMetrics)
        ..removeOnCreatedListener(_init);
    }
    super.dispose();
  }

  void _syncMetrics({bool notify = true}) {
    final metrics = _scopeKey.maybeCurrentExtent?.metrics;
    if (metrics?.maybeContentSize case final contentSize?) {
      owner.applyNewContentSize(contentSize);
    }
    if (metrics?.maybePixels case final pixels?) {
      notify ? owner.setPixels(pixels) : owner.correctPixels(pixels);
    }
  }
}

abstract class NavigationSheetRoute<T> extends PageRoute<T> {
  NavigationSheetRoute({super.settings});

  late _NavigationSheetExtent _globalExtent;

  @override
  void install() {
    super.install();
    assert(_debugAssertDependencies());

    _globalExtent =
        SheetExtentScope.of(navigator!.context) as _NavigationSheetExtent;
    _globalExtent.createLocalExtentScopeKey(this, debugLabel);
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    // Keep the reference to the global extent up-to-date since we need
    // to call disposeLocalExtentScopeKey() in dispose().
    _globalExtent =
        SheetExtentScope.of(navigator!.context) as _NavigationSheetExtent;
  }

  @override
  void dispose() {
    _globalExtent.disposeLocalExtentScopeKey(this);
    super.dispose();
  }

  bool _debugAssertDependencies() {
    assert(
      () {
        final globalExtent = SheetExtentScope.maybeOf(navigator!.context);
        if (globalExtent is _NavigationSheetExtent) {
          return true;
        }
        throw FlutterError(
          'A $SheetExtentScope that hosts a $_NavigationSheetExtent '
          'is not found in the given context. This is likely because '
          'this $NavigationSheetRoute is not a route of the navigator '
          'enclosed by a $NavigationSheet.',
        );
      }(),
    );
    return true;
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  RouteTransitionsBuilder? get transitionsBuilder;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final builder = transitionsBuilder ?? _buildDefaultTransitions;
    return builder(context, animation, secondaryAnimation, child);
  }

  Widget _buildDefaultTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final theme = Theme.of(context).pageTransitionsTheme;
    final platformAdaptiveTransitions = theme.buildTransitions<T>(
        this, context, animation, secondaryAnimation, child);

    final fadeInTween = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 1,
      ),
    ]);

    final fadeOutTween = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
    ]);

    return FadeTransition(
      opacity: animation.drive(fadeInTween),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(fadeOutTween),
        child: platformAdaptiveTransitions,
      ),
    );
  }
}

class NavigationSheetRouteContent extends StatelessWidget {
  const NavigationSheetRouteContent({
    super.key,
    required this.factory,
    required this.config,
    required this.child,
  });

  final SheetExtentFactory factory;
  final SheetExtentConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(_debugAssertDependencies(context));
    final parentRoute = ModalRoute.of(context)!;
    final globalExtent = SheetExtentScope.of(context) as _NavigationSheetExtent;
    final localScopeKey = globalExtent.getLocalExtentScopeKey(parentRoute);

    return SheetExtentScope(
      key: localScopeKey,
      isPrimary: false,
      factory: factory,
      config: config,
      controller: SheetControllerScope.of(context),
      child: SheetContentViewport(child: child),
    );
  }

  bool _debugAssertDependencies(BuildContext context) {
    assert(
      () {
        final parentRoute = ModalRoute.of(context);
        if (parentRoute is NavigationSheetRoute) {
          return true;
        }
        throw FlutterError(
          'The $NavigationSheetRouteContent must be the content of '
          'a $NavigationSheetRoute, but the result of ModalRoute.of(context) '
          'is ${parentRoute?.runtimeType}.',
        );
      }(),
    );
    assert(
      () {
        final globalExtent = SheetExtentScope.maybeOf(context);
        if (globalExtent is _NavigationSheetExtent) {
          return true;
        }
        throw FlutterError(
          'A $SheetExtentScope that hosts a $_NavigationSheetExtent '
          'is not found in the given context. This is likely because '
          'this $NavigationSheetRouteContent is not the content of a '
          '$NavigationSheetRoute.',
        );
      }(),
    );
    return true;
  }
}

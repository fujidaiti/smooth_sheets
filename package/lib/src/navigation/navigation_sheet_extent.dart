import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_extent.dart';
import '../foundation/sheet_extent_scope.dart';
import '../internal/transition_observer.dart';
import 'navigation_sheet_activity.dart';

@internal
class NavigationSheetExtent extends SheetExtent {
  NavigationSheetExtent({
    required super.context,
    required super.minExtent,
    required super.maxExtent,
    required super.physics,
    super.gestureTamperer,
    super.debugLabel,
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
    if (other is NavigationSheetExtent) {
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
  void dispose() {
    super.dispose();
    for (final scopeKey in _localExtentScopeKeyRegistry.values) {
      scopeKey.removeAllOnCreatedListeners();
    }
    _localExtentScopeKeyRegistry.clear();
  }

  void handleRouteTransition(Transition? transition) {
    _lastReportedTransition = transition;
    // TODO: Provide a way to customize animation curves.
    switch (transition) {
      case NoTransition(:final currentRoute):
        beginActivity(ProxySheetActivity(route: currentRoute));

      case final ForwardTransition tr:
        beginActivity(TransitionSheetActivity(
          currentRoute: tr.originRoute,
          nextRoute: tr.destinationRoute,
          animation: tr.animation,
          animationCurve: Curves.easeInOutCubic,
        ));

      case final BackwardTransition tr:
        beginActivity(TransitionSheetActivity(
          currentRoute: tr.originRoute,
          nextRoute: tr.destinationRoute,
          animation: tr.animation,
          animationCurve: Curves.easeInOutCubic,
        ));

      case final UserGestureTransition tr:
        beginActivity(TransitionSheetActivity(
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
        beginActivity(ProxySheetActivity(route: currentRoute));
      case _:
        super.goIdle();
    }
  }

  @override
  void dispatchUpdateNotification() {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchUpdateNotification();
    }
  }

  @override
  void dispatchDragStartNotification() {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchDragStartNotification();
    }
  }

  @override
  void dispatchDragEndNotification() {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchDragEndNotification();
    }
  }

  @override
  void dispatchDragUpdateNotification() {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchDragUpdateNotification();
    }
  }

  @override
  void dispatchOverflowNotification(double overflow) {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchOverflowNotification(overflow);
    }
  }

  bool _debugAssertActivityTypeConsistency() {
    assert(
      () {
        switch ((_lastReportedTransition, activity)) {
          case (NoTransition(), ProxySheetActivity()):
          case (ForwardTransition(), TransitionSheetActivity()):
          case (BackwardTransition(), TransitionSheetActivity()):
          case (UserGestureTransition(), TransitionSheetActivity()):
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

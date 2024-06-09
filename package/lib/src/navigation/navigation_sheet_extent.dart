import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_extent.dart';
import '../internal/transition_observer.dart';
import 'navigation_route.dart';
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

  Transition? _lastReportedTransition;

  @override
  void takeOver(SheetExtent other) {
    super.takeOver(other);
    assert(_debugAssertActivityTypeConsistency());
  }

  void handleRouteTransition(Transition? transition) {
    _lastReportedTransition = transition;
    // TODO: Provide a way to customize animation curves.
    switch (transition) {
      case NoTransition(:final NavigationSheetRoute currentRoute):
        beginActivity(ProxySheetActivity(route: currentRoute));

      case ForwardTransition(
          :final NavigationSheetRoute originRoute,
          :final NavigationSheetRoute destinationRoute,
          :final animation,
        ):
        beginActivity(TransitionSheetActivity(
          currentRoute: originRoute,
          nextRoute: destinationRoute,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ));

      case BackwardTransition(
          :final NavigationSheetRoute originRoute,
          :final NavigationSheetRoute destinationRoute,
          :final animation,
        ):
        beginActivity(TransitionSheetActivity(
          currentRoute: originRoute,
          nextRoute: destinationRoute,
          animation: animation,
          animationCurve: Curves.easeInOutCubic,
        ));

      case UserGestureTransition(
          :final NavigationSheetRoute currentRoute,
          :final NavigationSheetRoute previousRoute,
          :final animation,
        ):
        beginActivity(TransitionSheetActivity(
          currentRoute: currentRoute,
          nextRoute: previousRoute,
          animation: animation,
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
      case NoTransition(:final NavigationSheetRoute currentRoute):
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

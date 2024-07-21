import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_drag.dart';
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

    assert(_debugAssertRouteType());
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
  Future<void> animateTo(
    Extent newExtent, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (activity case ProxySheetActivity(:final route)) {
      return route.scopeKey.currentExtent
          .animateTo(newExtent, curve: curve, duration: duration);
    } else {
      return super.animateTo(newExtent, curve: curve, duration: duration);
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
  void dispatchDragStartNotification({
    required SheetDragStartDetails details,
  }) {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchDragStartNotification(details: details);
    }
  }

  @override
  void dispatchDragEndNotification({
    required SheetDragEndDetails details,
  }) {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchDragEndNotification(details: details);
    }
  }

  @override
  void dispatchDragUpdateNotification({
    required SheetDragUpdateDetails details,
  }) {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchDragUpdateNotification(details: details);
    }
  }

  @override
  void dispatchOverflowNotification({
    required double overflow,
  }) {
    // Do not dispatch a notifications if a local extent is active.
    if (activity is! NavigationSheetActivity) {
      super.dispatchOverflowNotification(overflow: overflow);
    }
  }

  bool _debugAssertRouteType() {
    assert(
      () {
        final lastTransition = _lastReportedTransition;
        if (lastTransition is NoTransition &&
            lastTransition.currentRoute.isFirst &&
            lastTransition.currentRoute is! NavigationSheetRoute) {
          throw FlutterError(
            'The first route in the navigator enclosed by a NavigationSheet '
            'must be a NavigationSheetRoute, but actually it is a '
            '${describeIdentity(lastTransition.currentRoute)}',
          );
        }
        return true;
      }(),
    );
    return true;
  }

  bool _debugAssertActivityTypeConsistency() {
    assert(
      () {
        switch ((_lastReportedTransition, activity)) {
          // Allowed patterns.
          case (
              NoTransition(currentRoute: NavigationSheetRoute()),
              ProxySheetActivity(),
            ):
          case (
              ForwardTransition(
                originRoute: NavigationSheetRoute(),
                destinationRoute: NavigationSheetRoute(),
              ),
              TransitionSheetActivity(),
            ):
          case (
              BackwardTransition(
                originRoute: NavigationSheetRoute(),
                destinationRoute: NavigationSheetRoute(),
              ),
              TransitionSheetActivity(),
            ):
          case (
              UserGestureTransition(
                currentRoute: NavigationSheetRoute(),
                previousRoute: NavigationSheetRoute(),
              ),
              TransitionSheetActivity(),
            ):
          case (_, final activity) when activity is! NavigationSheetActivity:
            return true;

          // Other patterns are not allowed.
          case (final transition, final activity):
            throw FlutterError(
              'There is an inconsistency between the current transition state '
              'and the current sheet activity type.\n'
              '  Transition: $transition\n'
              '  Activity: ${describeIdentity(activity)}',
            );
        }
      }(),
    );
    return true;
  }
}

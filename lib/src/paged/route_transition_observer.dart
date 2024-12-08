import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

final class RouteTransitionObserver extends NavigatorObserver {
  final Set<RouteTransitionAwareStateMixin> _listeners = {};

  void _mount(RouteTransitionAwareStateMixin transitionAware) {
    assert(!_listeners.contains(transitionAware));
    _listeners.add(transitionAware);
  }

  void _unmount(RouteTransitionAwareStateMixin transitionAware) {
    assert(_listeners.contains(transitionAware));
    _listeners.remove(transitionAware);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware._didPop(route, previousRoute);
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware._didPush(route, previousRoute);
      }
    }
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware._didStartUserGesture(route, previousRoute);
      }
    }
  }

  @override
  void didStopUserGesture() {
    for (final transitionAware in _listeners) {
      transitionAware._didStopUserGesture();
    }
  }
}

@internal
mixin RouteTransitionAwareWidgetMixin on StatefulWidget {
  RouteTransitionObserver get transitionObserver;
}

@internal
mixin RouteTransitionAwareStateMixin<T extends RouteTransitionAwareWidgetMixin>
    on State<T> {
  RouteTransition? _lastReportedTransition;
  RouteTransition? get currentTransition => _lastReportedTransition;

  void _notify(RouteTransition? transition) {
    if (_lastReportedTransition != transition) {
      _lastReportedTransition = transition;
      didChangeTransitionState(transition);
    }
  }

  void didChangeTransitionState(RouteTransition? transition);

  void _didPush(ModalRoute<dynamic> route, ModalRoute<dynamic>? previousRoute) {
    final currentState = currentTransition;

    if (previousRoute == null || route.animation!.isCompleted) {
      // There is only one roue in the history stack, or multiple routes
      // are pushed at the same time without transition animation.
      _notify(NoRouteTransition(currentRoute: route));
    } else if (route.isCurrent && currentState is NoRouteTransition) {
      // A new route is pushed on top of the stack with transition animation.
      // Then, notify the listener of the beginning of the transition.
      _notify(ForwardRouteTransition(
        originRoute: currentState.currentRoute,
        destinationRoute: route,
        animation: route.animation!,
      ));

      // Notify the listener again when the transition is completed.
      void transitionStatusListener(AnimationStatus status) {
        if (status == AnimationStatus.completed && !route.offstage) {
          route.animation!.removeStatusListener(transitionStatusListener);
          if (currentTransition is ForwardRouteTransition) {
            _notify(NoRouteTransition(currentRoute: route));
          }
        }
      }

      route.animation!.addStatusListener(transitionStatusListener);
    }
  }

  void _didPop(ModalRoute<dynamic> route, ModalRoute<dynamic>? previousRoute) {
    if (previousRoute == null) {
      _notify(null);
    } else {
      _notify(BackwardRouteTransition(
        originRoute: route,
        destinationRoute: previousRoute,
        animation: route.animation!.drive(Tween(begin: 1, end: 0)),
      ));
      route.completed.whenComplete(() {
        if (currentTransition is BackwardRouteTransition) {
          _notify(NoRouteTransition(currentRoute: previousRoute));
        }
      });
    }
  }

  void _didStartUserGesture(
    ModalRoute<dynamic> route,
    ModalRoute<dynamic>? previousRoute,
  ) {
    _notify(UserGestureRouteTransition(
      currentRoute: route,
      previousRoute: previousRoute!,
      animation: route.animation!.drive(Tween(begin: 1, end: 0)),
    ));
  }

  void _didStopUserGesture() {
    if (currentTransition case final UserGestureRouteTransition state) {
      _notify(NoRouteTransition(
        currentRoute: state.currentRoute,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.transitionObserver._mount(this);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transitionObserver != oldWidget.transitionObserver) {
      oldWidget.transitionObserver._unmount(this);
      widget.transitionObserver._mount(this);
      _notify(null);
    }
  }

  @override
  void dispose() {
    widget.transitionObserver._unmount(this);
    _notify(null);
    super.dispose();
  }
}

@internal
sealed class RouteTransition {}

/// Event when the navigation settles to a route.
///
/// This event is dispatched when:
/// - The initial route is added to the page stack, or
/// - A transition animation is completed. This includes the case
///   when the transition is controlled by a user gesture, typically
///   the swipe-from-right-to-left-to-go-back gesture on iOS.
@internal
class NoRouteTransition extends RouteTransition {
  NoRouteTransition({required this.currentRoute});

  final ModalRoute<dynamic> currentRoute;

  @override
  String toString() =>
      '$NoRouteTransition${(currentRoute: describeIdentity(currentRoute))}';
}

@internal
class ForwardRouteTransition extends RouteTransition {
  ForwardRouteTransition({
    required this.originRoute,
    required this.destinationRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> originRoute;
  final ModalRoute<dynamic> destinationRoute;
  final Animation<double> animation;

  @override
  String toString() => '$ForwardRouteTransition${(
        originRoute: describeIdentity(originRoute),
        destinationRoute: describeIdentity(destinationRoute),
      )}';
}

@internal
class BackwardRouteTransition extends RouteTransition {
  BackwardRouteTransition({
    required this.originRoute,
    required this.destinationRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> originRoute;
  final ModalRoute<dynamic> destinationRoute;
  final Animation<double> animation;

  @override
  String toString() => '$BackwardRouteTransition${(
        originRoute: describeIdentity(originRoute),
        destinationRoute: describeIdentity(destinationRoute),
      )}';
}

@internal
class UserGestureRouteTransition extends RouteTransition {
  UserGestureRouteTransition({
    required this.currentRoute,
    required this.previousRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> currentRoute;
  final ModalRoute<dynamic> previousRoute;
  final Animation<double> animation;

  @override
  String toString() => '$UserGestureRouteTransition${(
        currentRoute: describeIdentity(currentRoute),
        previousRoute: describeIdentity(previousRoute),
      )}';
}

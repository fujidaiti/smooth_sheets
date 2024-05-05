import 'package:flutter/widgets.dart';

class TransitionObserver extends NavigatorObserver {
  final Set<TransitionAwareStateMixin> _listeners = {};

  void mount(TransitionAwareStateMixin transitionAware) {
    assert(!_listeners.contains(transitionAware));
    _listeners.add(transitionAware);
  }

  void unmount(TransitionAwareStateMixin transitionAware) {
    assert(_listeners.contains(transitionAware));
    _listeners.remove(transitionAware);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware.didPop(route, previousRoute);
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware.didPush(route, previousRoute);
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
        transitionAware.didStartUserGesture(route, previousRoute);
      }
    }
  }

  @override
  void didStopUserGesture() {
    for (final transitionAware in _listeners) {
      transitionAware.didStopUserGesture();
    }
  }
}

mixin TransitionAwareWidgetMixin on StatefulWidget {
  TransitionObserver get transitionObserver;
}

mixin TransitionAwareStateMixin<T extends TransitionAwareWidgetMixin>
    on State<T> {
  Transition? _lastReportedTransition;
  Transition? get currentTransition => _lastReportedTransition;

  void _notify(Transition? transition) {
    if (_lastReportedTransition != transition) {
      _lastReportedTransition = transition;
      didChangeTransitionState(transition);
    }
  }

  void didChangeTransitionState(Transition? transition);

  void didPush(ModalRoute<dynamic> route, ModalRoute<dynamic>? previousRoute) {
    final currentState = currentTransition;

    if (previousRoute == null || route.animation!.isCompleted) {
      // There is only one roue in the history stack, or multiple routes
      // are pushed at the same time without transition animation.
      _notify(NoTransition(currentRoute: route));
    } else if (route.isCurrent && currentState is NoTransition) {
      // A new route is pushed on top of the stack with transition animation.
      // Then, notify the listener of the beginning of the transition.
      _notify(ForwardTransition(
        originRoute: currentState.currentRoute,
        destinationRoute: route,
        animation: route.animation!,
      ));

      // Notify the listener again when the transition is completed.
      void transitionStatusListener(AnimationStatus status) {
        if (status == AnimationStatus.completed && !route.offstage) {
          route.animation!.removeStatusListener(transitionStatusListener);
          if (currentTransition is ForwardTransition) {
            _notify(NoTransition(currentRoute: route));
          }
        }
      }
      route.animation!.addStatusListener(transitionStatusListener);
    }
  }

  void didPop(ModalRoute<dynamic> route, ModalRoute<dynamic>? previousRoute) {
    if (previousRoute == null) {
      _notify(null);
    } else {
      _notify(BackwardTransition(
        originRoute: route,
        destinationRoute: previousRoute,
        animation: route.animation!.drive(Tween(begin: 1, end: 0)),
      ));
      route.completed.whenComplete(() {
        if (currentTransition is BackwardTransition) {
          _notify(NoTransition(currentRoute: previousRoute));
        }
      });
    }
  }

  void didStartUserGesture(
    ModalRoute<dynamic> route,
    ModalRoute<dynamic>? previousRoute,
  ) {
    _notify(UserGestureTransition(
      currentRoute: route,
      previousRoute: previousRoute!,
      animation: route.animation!.drive(Tween(begin: 1, end: 0)),
    ));
  }

  void didStopUserGesture() {
    if (currentTransition case final UserGestureTransition state) {
      _notify(NoTransition(
        currentRoute: state.currentRoute,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.transitionObserver.mount(this);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transitionObserver != oldWidget.transitionObserver) {
      oldWidget.transitionObserver.unmount(this);
      widget.transitionObserver.mount(this);
      _notify(null);
    }
  }

  @override
  void dispose() {
    widget.transitionObserver.unmount(this);
    _notify(null);
    super.dispose();
  }
}

sealed class Transition {}

class NoTransition extends Transition {
  NoTransition({required this.currentRoute});

  final ModalRoute<dynamic> currentRoute;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NoTransition &&
            runtimeType == other.runtimeType &&
            currentRoute == other.currentRoute);
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentRoute);
}

class ForwardTransition extends Transition {
  ForwardTransition({
    required this.originRoute,
    required this.destinationRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> originRoute;
  final ModalRoute<dynamic> destinationRoute;
  final Animation<double> animation;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForwardTransition &&
            runtimeType == other.runtimeType &&
            originRoute == other.originRoute &&
            destinationRoute == other.destinationRoute &&
            animation == other.animation);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        originRoute,
        destinationRoute,
        animation,
      );
}

class BackwardTransition extends Transition {
  BackwardTransition({
    required this.originRoute,
    required this.destinationRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> originRoute;
  final ModalRoute<dynamic> destinationRoute;
  final Animation<double> animation;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BackwardTransition &&
            runtimeType == other.runtimeType &&
            originRoute == other.originRoute &&
            destinationRoute == other.destinationRoute &&
            animation == other.animation);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        originRoute,
        destinationRoute,
        animation,
      );
}

class UserGestureTransition extends Transition {
  UserGestureTransition({
    required this.currentRoute,
    required this.previousRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> currentRoute;
  final ModalRoute<dynamic> previousRoute;
  final Animation<double> animation;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserGestureTransition &&
            runtimeType == other.runtimeType &&
            currentRoute == other.currentRoute &&
            previousRoute == other.previousRoute &&
            animation == other.animation);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        currentRoute,
        previousRoute,
        animation,
      );
}

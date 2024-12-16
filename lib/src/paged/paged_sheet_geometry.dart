import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../smooth_sheets.dart';
import '../foundation/sheet_activity.dart';
import '../scrollable/scrollable_sheet_position.dart';
import 'paged_sheet_route.dart';
import 'route_transition_observer.dart';

@internal
const kDefaultPagedSheetPhysics = ClampingSheetPhysics();

@internal
const kDefaultPagedSheetInitialOffset = SheetAnchor.proportional(1);

@internal
const kDefaultPagedSheetMinOffset = SheetAnchor.proportional(1);

@internal
const kDefaultPagedSheetMaxOffset = SheetAnchor.proportional(1);

@internal
const kDefaultPagedSheetTransitionCurve = Curves.easeInOutCubic;

class _RouteGeometry {
  Size? oldContentSize;
  Size? contentSize;
  double? offset;
}

@internal
class PagedSheetGeometry extends DraggableScrollableSheetPosition {
  PagedSheetGeometry({
    required super.context,
    super.gestureTamperer,
    super.debugLabel,
  }) : super(
          initialPosition: kDefaultPagedSheetInitialOffset,
          minPosition: kDefaultPagedSheetMinOffset,
          maxPosition: kDefaultPagedSheetMaxOffset,
          physics: kDefaultPagedSheetPhysics,
        );

  final Map<BasePagedSheetRoute, _RouteGeometry> _routeGeometries = {};

  BasePagedSheetRoute? _currentRoute;

  void _setCurrentRoute(BasePagedSheetRoute? route) {
    assert(route == null || _routeGeometries.containsKey(route));
    if (route != null) {
      _currentRoute = route;
      updatePhysics(route.physics);
      applyNewBoundaryConstraints(route.minOffset, route.maxOffset);
      final routeGeometry = _routeGeometries[route];
      if (routeGeometry?.contentSize case final contentSize?) {
        applyNewContentSize(contentSize);
      }
      if (routeGeometry?.offset case final offset?) {
        setPixels(offset);
      }
    } else {
      _currentRoute = null;
      updatePhysics(kDefaultPagedSheetPhysics);
      applyNewBoundaryConstraints(
        kDefaultPagedSheetMinOffset,
        kDefaultPagedSheetMaxOffset,
      );
    }
  }

  void addRoute(BasePagedSheetRoute route) {
    assert(!_routeGeometries.containsKey(route));
    _routeGeometries[route] = _RouteGeometry();
  }

  void removeRoute(BasePagedSheetRoute route) {
    assert(_routeGeometries.containsKey(route));
    _routeGeometries.remove(route);
    if (route == _currentRoute) {
      _setCurrentRoute(null);
      goIdle();
    }
  }

  void applyNewRouteContentSize(BasePagedSheetRoute route, Size contentSize) {
    assert(_routeGeometries.containsKey(route));
    _routeGeometries[route]?.contentSize = contentSize;
    if (route == _currentRoute) {
      applyNewContentSize(contentSize);
    }
  }

  @override
  void onFinalizePosition(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    for (final entry in _routeGeometries.entries) {
      final route = entry.key;
      final routeGeometry = entry.value;

      assert(
        routeGeometry.contentSize != null,
        'Route content size must be set before finalizing the offset.',
      );
      final currentContentSize = routeGeometry.contentSize!;
      final oldContentSize = routeGeometry.oldContentSize;

      final currentOffset = routeGeometry.offset ??=
          route.initialOffset.resolve(currentContentSize);

      if (oldContentSize != null && oldContentSize != currentContentSize) {
        _routeGeometries[route]?.offset = physics
            .findSettledPosition(
              0,
              SheetMetricsSnapshot(
                pixels: currentOffset,
                minPosition: route.minOffset,
                maxPosition: route.maxOffset,
                contentSize: oldContentSize,
                viewportSize: oldViewportSize,
                viewportInsets: oldViewportInsets,
              ),
            )
            .resolve(currentContentSize);
      }

      _routeGeometries[route]?.oldContentSize = null;
    }

    if (maybePixels == null) {
      setPixels(
        _currentRoute?.initialOffset.resolve(contentSize) ??
            initialPosition.resolve(contentSize),
      );
    }
  }

  @override
  void setPixels(double pixels) {
    super.setPixels(pixels);
    _routeGeometries[_currentRoute]?.offset = pixels;
  }

  void _goIdleWithRoute(BasePagedSheetRoute route) {
    assert(_routeGeometries.containsKey(route));
    _setCurrentRoute(route);
    goIdle();
  }

  void _goTransition({
    required BasePagedSheetRoute originRoute,
    required BasePagedSheetRoute destinationRoute,
    required Animation<double> animation,
    required Curve animationCurve,
  }) {
    assert(_routeGeometries.containsKey(originRoute));
    assert(_routeGeometries.containsKey(destinationRoute));
    _setCurrentRoute(null);
    beginActivity(RouteTransitionSheetActivity(
      originRouteOffset: () => _routeGeometries[originRoute]?.offset,
      destinationRouteOffset: () => _routeGeometries[destinationRoute]?.offset,
      animation: animation,
      animationCurve: animationCurve,
    ));
  }

  void onTransition(RouteTransition? transition) {
    switch (transition) {
      case NoRouteTransition(:final BasePagedSheetRoute currentRoute):
        _goIdleWithRoute(currentRoute);

      case ForwardRouteTransition(
          :final BasePagedSheetRoute originRoute,
          :final BasePagedSheetRoute destinationRoute,
          :final animation,
        ):
        _goTransition(
          originRoute: originRoute,
          destinationRoute: destinationRoute,
          animation: animation,
          animationCurve: kDefaultPagedSheetTransitionCurve,
        );

      case BackwardRouteTransition(
          :final BasePagedSheetRoute originRoute,
          :final BasePagedSheetRoute destinationRoute,
          :final animation,
        ):
        _goTransition(
          originRoute: originRoute,
          destinationRoute: destinationRoute,
          animation: animation,
          animationCurve: kDefaultPagedSheetTransitionCurve,
        );

      case UserGestureRouteTransition(
          :final BasePagedSheetRoute currentRoute,
          :final BasePagedSheetRoute previousRoute,
          :final animation,
        ):
        _goTransition(
          originRoute: currentRoute,
          destinationRoute: previousRoute,
          animation: animation,
          animationCurve: Curves.linear,
        );

      case _:
        _setCurrentRoute(null);
        goIdle();
    }
  }
}

@visibleForTesting
class RouteTransitionSheetActivity extends SheetActivity<PagedSheetGeometry> {
  RouteTransitionSheetActivity({
    required this.originRouteOffset,
    required this.destinationRouteOffset,
    required this.animation,
    required this.animationCurve,
  });

  final ValueGetter<double?> originRouteOffset;
  final ValueGetter<double?> destinationRouteOffset;
  final Animation<double> animation;
  final Curve animationCurve;
  late final Animation<double> _effectiveAnimation;

  @override
  SheetStatus get status => SheetStatus.animating;

  @override
  bool get shouldIgnorePointer => true;

  @override
  void init(PagedSheetGeometry owner) {
    super.init(owner);
    _effectiveAnimation = animation.drive(
      CurveTween(curve: animationCurve),
    )..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _effectiveAnimation.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    final fraction = _effectiveAnimation.value;
    final originOffset = originRouteOffset();
    final destOffset = destinationRouteOffset();

    if (originOffset != null && destOffset != null) {
      owner.setPixels(lerpDouble(originOffset, destOffset, fraction)!);
    }
  }

  @override
  void finalizePosition(
    Size? oldContentSize,
    Size? oldViewportSize,
    EdgeInsets? oldViewportInsets,
  ) {
    if (oldViewportInsets != null) {
      absorbBottomViewportInset(owner, oldViewportInsets);
    }
  }
}

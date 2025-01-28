import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/activity.dart';
import '../foundation/model.dart';
import '../foundation/physics.dart';
import '../foundation/scrollable.dart';
import '../foundation/snap_grid.dart';
import 'paged_sheet_route.dart';

@internal
const kDefaultPagedSheetPhysics = ClampingSheetPhysics();

@internal
const kDefaultPagedSheetInitialOffset = SheetOffset.relative(1);

@internal
const kDefaultPagedSheetMinOffset = SheetOffset.relative(1);

@internal
const kDefaultPagedSheetMaxOffset = SheetOffset.relative(1);

const _kDefaultSnapGrid = SteplessSnapGrid(
  minOffset: SheetOffset.absolute(0),
  maxOffset: SheetOffset.relative(1),
);

@internal
const kDefaultPagedSheetTransitionCurve = Curves.easeInOutCubic;

class _RouteGeometry {
  _RouteGeometry({
    required this.targetOffset,
  });

  Size? contentSize;
  SheetOffset targetOffset;
}

@internal
class PagedSheetGeometry extends ScrollAwareSheetModel {
  PagedSheetGeometry({
    required super.context,
    super.gestureProxy,
    super.debugLabel,
  }) : super(
          initialOffset: kDefaultPagedSheetInitialOffset,
          physics: kDefaultPagedSheetPhysics,
          snapGrid: _kDefaultSnapGrid,
        );

  final Map<BasePagedSheetRoute, _RouteGeometry> _routeGeometries = {};

  BasePagedSheetRoute? _currentRoute;

  void _setCurrentRoute(BasePagedSheetRoute? route) {
    assert(route == null || _routeGeometries.containsKey(route));
    if (route != null) {
      _currentRoute = route;
      physics = route.physics;
    } else {
      _currentRoute = null;
      physics = kDefaultPagedSheetPhysics;
    }
  }

  void addRoute(BasePagedSheetRoute route) {
    assert(!_routeGeometries.containsKey(route));
    _routeGeometries[route] = _RouteGeometry(
      targetOffset: route.initialOffset,
    );
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
  }

  double _resolveTargetOffset(BasePagedSheetRoute route) {
    final geometry = _routeGeometries[route]!;
    return geometry.targetOffset.resolve(
      measurements.copyWith(
        contentSize: geometry.contentSize,
      ),
    );
  }

  @override
  set measurements(SheetMeasurements value) {
    final needInitialisation = !hasMetrics;
    super.measurements = value;
    if (needInitialisation) {
      setOffset(
        switch (_currentRoute) {
          null => initialOffset.resolve(value),
          final it => _resolveTargetOffset(it),
        },
      );
    }
  }

  @override
  void goIdle() {
    if (_currentRoute case final route?) {
      beginActivity(
        _IdleSheetActivity(
          targetOffset:
              _routeGeometries[route]?.targetOffset ?? route.initialOffset,
        ),
      );
    } else {
      super.goIdle();
    }
  }

  void didStartTransition(
    BasePagedSheetRoute currentRoute,
    BasePagedSheetRoute nextRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {
    final Curve effectiveCurve;
    final Animation<double> effectiveAnimation;
    if (isUserGestureInProgress) {
      effectiveCurve = Curves.linear;
      effectiveAnimation = animation.drive(Tween(begin: 1.0, end: 0.0));
    } else if (animation.status == AnimationStatus.reverse) {
      effectiveCurve = kDefaultPagedSheetTransitionCurve;
      effectiveAnimation = animation.drive(Tween(begin: 1.0, end: 0.0));
    } else {
      effectiveCurve = kDefaultPagedSheetTransitionCurve;
      effectiveAnimation = animation;
    }

    assert(_routeGeometries.containsKey(currentRoute));
    assert(_routeGeometries.containsKey(nextRoute));
    _setCurrentRoute(null);
    beginActivity(RouteTransitionSheetActivity(
      originRouteOffset: () => _resolveTargetOffset(currentRoute),
      destinationRouteOffset: () => _resolveTargetOffset(nextRoute),
      animation: effectiveAnimation,
      animationCurve: effectiveCurve,
    ));
  }

  void didEndTransition(BasePagedSheetRoute route) {
    assert(_routeGeometries.containsKey(route));
    _setCurrentRoute(route);
    goIdle();
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
      owner.setOffset(lerpDouble(originOffset, destOffset, fraction)!);
    }
  }

  @override
  void didChangeMeasurements(SheetMeasurements oldMeasurements) {
    if (owner.measurements.viewportInsets != oldMeasurements.viewportInsets) {
      absorbBottomViewportInset(owner, oldMeasurements.viewportInsets);
    }
  }
}

class _IdleSheetActivity extends SheetActivity<PagedSheetGeometry>
    with IdleSheetActivityMixin<PagedSheetGeometry> {
  _IdleSheetActivity({
    required this.targetOffset,
  });

  @override
  late final SheetOffset targetOffset;
}

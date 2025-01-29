import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

import 'activity.dart';
import 'controller.dart';
import 'foundation.dart';
import 'gesture_proxy.dart';
import 'model_owner.dart';
import 'scrollable.dart';
import 'sheet.dart';
import 'snap_grid.dart';

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
class PagedSheetModel extends ScrollAwareSheetModel {
  PagedSheetModel({
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
class RouteTransitionSheetActivity extends SheetActivity<PagedSheetModel> {
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
  void init(PagedSheetModel owner) {
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

class _IdleSheetActivity extends SheetActivity<PagedSheetModel>
    with IdleSheetActivityMixin<PagedSheetModel> {
  _IdleSheetActivity({
    required this.targetOffset,
  });

  @override
  late final SheetOffset targetOffset;
}

class PagedSheet extends StatefulWidget {
  const PagedSheet({
    super.key,
    this.controller,
    required this.child,
  });

  final SheetController? controller;

  final Widget child;

  @override
  State<PagedSheet> createState() => _PagedSheetState();
}

class _PagedSheetState extends State<PagedSheet> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final gestureProxy = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return _PagedSheetModelOwner(
      physics: kDefaultPagedSheetPhysics,
      controller: controller,
      gestureProxy: gestureProxy,
      debugLabel: kDebugMode ? 'NavigationSheet' : null,
      child: NavigatorResizable(
        child: widget.child,
      ),
    );
  }
}

class _PagedSheetModelOwner extends SheetModelOwner<PagedSheetModel> {
  const _PagedSheetModelOwner({
    super.controller,
    super.gestureProxy,
    required super.physics,
    this.debugLabel,
    required super.child,
  }) : super(
          snapGrid: const SteplessSnapGrid(
            minOffset: SheetOffset.absolute(0),
            maxOffset: SheetOffset.relative(1),
          ),
        );

  /// {@macro SheetPosition.debugLabel}
  final String? debugLabel;

  @override
  _PagedSheetModelOwnerState createState() {
    return _PagedSheetModelOwnerState();
  }
}

class _PagedSheetModelOwnerState
    extends SheetModelOwnerState<PagedSheetModel, _PagedSheetModelOwner>
    with NavigatorEventListener {
  NavigatorEventObserverState? _navigatorEventObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = NavigatorEventObserver.of(context)!;
    if (observer != _navigatorEventObserver) {
      _navigatorEventObserver?.removeListener(this);
      _navigatorEventObserver = observer..addListener(this);
    }
  }

  @override
  void dispose() {
    _navigatorEventObserver?.removeListener(this);
    _navigatorEventObserver = null;
    super.dispose();
  }

  @override
  bool shouldRefreshModel() {
    return widget.debugLabel != model.debugLabel || super.shouldRefreshModel();
  }

  @override
  PagedSheetModel createModel() {
    return PagedSheetModel(
      context: this,
      gestureProxy: widget.gestureProxy,
      debugLabel: widget.debugLabel,
    );
  }

  @override
  VoidCallback? didInstall(Route<dynamic> route) {
    if (route is BasePagedSheetRoute) {
      model.addRoute(route);
      return () => model.removeRoute(route);
    }
    return null;
  }

  @override
  void didStartTransition(
    Route<dynamic> currentRoute,
    Route<dynamic> nextRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {
    if (currentRoute is BasePagedSheetRoute &&
        nextRoute is BasePagedSheetRoute) {
      model.didStartTransition(
        currentRoute,
        nextRoute,
        animation,
        isUserGestureInProgress: isUserGestureInProgress,
      );
    }
  }

  @override
  void didEndTransition(Route<dynamic> route) {
    if (route is BasePagedSheetRoute) {
      model.didEndTransition(route);
    }
  }
}

// TODO: DRY this widget across the library.
class _RouteContentLayoutObserver extends SingleChildRenderObjectWidget {
  const _RouteContentLayoutObserver({
    required this.parentRoute,
    required super.child,
  });

  final BasePagedSheetRoute parentRoute;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRouteContentLayoutObserver(
      parentRoute: parentRoute,
      model: SheetModelOwner.of(context)! as PagedSheetModel,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRouteContentLayoutObserver renderObject,
  ) {
    assert(parentRoute == renderObject.parentRoute);
    renderObject.model = SheetModelOwner.of(context)! as PagedSheetModel;
  }
}

class _RenderRouteContentLayoutObserver extends RenderProxyBox {
  _RenderRouteContentLayoutObserver({
    required this.parentRoute,
    required PagedSheetModel model,
  }) : _model = model;

  final BasePagedSheetRoute parentRoute;

  PagedSheetModel _model;

  // ignore: avoid_setters_without_getters
  set model(PagedSheetModel value) {
    if (_model != value) {
      _model = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    if (child?.size case final childSize?) {
      _model.applyNewRouteContentSize(parentRoute, childSize);
    }
  }
}

@internal
@optionalTypeArgs
abstract class BasePagedSheetRoute<T> extends PageRoute<T>
    with ObservableRouteMixin<T> {
  BasePagedSheetRoute({super.settings});

  SheetOffset get initialOffset;

  SheetOffset get minOffset;

  SheetOffset get maxOffset;

  SheetPhysics get physics;

  RouteTransitionsBuilder? get transitionsBuilder;

  SheetDragConfiguration? get dragConfiguration;

  // TODO: Apply new configuration when the current route changes.
  SheetScrollConfiguration? get scrollConfiguration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is BasePagedSheetRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is BasePagedSheetRoute;
  }

  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  );

  @override
  @nonVirtual
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ResizableNavigatorRouteContentBoundary(
      child: _RouteContentLayoutObserver(
        parentRoute: this,
        child: DraggableScrollableSheetContent(
          scrollConfiguration: scrollConfiguration,
          dragConfiguration: dragConfiguration,
          child: buildContent(
            context,
            animation,
            secondaryAnimation,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionsBuilder case final builder?) {
      return builder(context, animation, secondaryAnimation, child);
    }
    final theme = Theme.of(context).pageTransitionsTheme;
    return theme.buildTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class PagedSheetRoute<T> extends BasePagedSheetRoute<T> {
  PagedSheetRoute({
    super.settings,
    this.maintainState = true,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset.relative(1),
    this.minOffset = const SheetOffset.relative(1),
    this.maxOffset = const SheetOffset.relative(1),
    this.physics = kDefaultSheetPhysics,
    this.transitionsBuilder,
    required this.builder,
  });

  @override
  final SheetOffset initialOffset;

  @override
  final SheetOffset minOffset;

  @override
  final SheetOffset maxOffset;

  @override
  final SheetPhysics physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  @override
  final SheetDragConfiguration? dragConfiguration;

  @override
  final SheetScrollConfiguration? scrollConfiguration;

  final WidgetBuilder builder;

  @override
  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }
}

class PagedSheetPage<T> extends Page<T> {
  const PagedSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset.relative(1),
    this.minOffset = const SheetOffset.relative(1),
    this.maxOffset = const SheetOffset.relative(1),
    this.physics = kDefaultSheetPhysics,
    this.transitionsBuilder,
    required this.child,
  });

  final SheetOffset initialOffset;

  final SheetOffset minOffset;

  final SheetOffset maxOffset;

  final SheetPhysics physics;

  final bool maintainState;

  final Duration transitionDuration;

  final RouteTransitionsBuilder? transitionsBuilder;

  final SheetDragConfiguration? dragConfiguration;

  final SheetScrollConfiguration? scrollConfiguration;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedNavigationSheetRoute(page: this);
  }
}

class _PageBasedNavigationSheetRoute<T> extends BasePagedSheetRoute<T> {
  _PageBasedNavigationSheetRoute({
    required PagedSheetPage<T> page,
  }) : super(settings: page);

  PagedSheetPage<T> get page => settings as PagedSheetPage<T>;

  @override
  bool get maintainState => page.maintainState;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  RouteTransitionsBuilder? get transitionsBuilder => page.transitionsBuilder;

  @override
  SheetDragConfiguration? get dragConfiguration => page.dragConfiguration;

  @override
  SheetScrollConfiguration? get scrollConfiguration => page.scrollConfiguration;

  @override
  SheetOffset get initialOffset => page.initialOffset;

  @override
  SheetOffset get maxOffset => page.maxOffset;

  @override
  SheetOffset get minOffset => page.minOffset;

  @override
  SheetPhysics get physics => page.physics;

  @override
  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page.child;
  }
}

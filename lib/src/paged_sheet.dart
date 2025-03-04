import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

import 'activity.dart';
import 'controller.dart';
import 'gesture_proxy.dart';
import 'model.dart';
import 'model_owner.dart';
import 'physics.dart';
import 'scrollable.dart';
import 'sheet.dart';
import 'snap_grid.dart';
import 'viewport.dart';

const _kDefaultSnapGrid = SteplessSnapGrid(
  minOffset: SheetOffset.absolute(0),
  maxOffset: SheetOffset.relative(1),
);

mixin _PagedSheetEntry {
  SheetSnapGrid get snapGrid;

  SheetOffset get initialOffset;

  SheetOffset? _targetOffset;

  Size? _contentSize;
}

class _PagedSheetModelConfig extends SheetModelConfig {
  const _PagedSheetModelConfig({
    required super.physics,
    required super.gestureProxy,
    super.snapGrid = _kDefaultSnapGrid,
    required this.offsetInterpolationCurve,
  });

  final Curve offsetInterpolationCurve;

  @override
  _PagedSheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
    Curve? offsetInterpolationCurve,
  }) {
    return _PagedSheetModelConfig(
      physics: physics ?? this.physics,
      snapGrid: snapGrid ?? this.snapGrid,
      gestureProxy: gestureProxy ?? this.gestureProxy,
      offsetInterpolationCurve:
          offsetInterpolationCurve ?? this.offsetInterpolationCurve,
    );
  }
}

class _PagedSheetModel extends SheetModel<_PagedSheetModelConfig>
    with ScrollAwareSheetModelMixin<_PagedSheetModelConfig> {
  _PagedSheetModel(super.context, super.config);

  _PagedSheetEntry? _currentEntry;

  @override
  SheetOffset get initialOffset =>
      _currentEntry?.initialOffset ?? const SheetOffset.relative(1);

  @override
  set config(_PagedSheetModelConfig value) {
    if (_currentEntry case final entry? when entry.snapGrid != value.snapGrid) {
      // Always respects the snap grid of the current entry if exists.
      super.config = value.copyWith(snapGrid: entry.snapGrid);
    } else {
      super.config = value;
    }
  }

  @override
  void dispose() {
    _currentEntry = null;
    super.dispose();
  }

  @override
  void beginActivity(SheetActivity activity) {
    super.beginActivity(activity);
    if (activity is IdleSheetActivity) {
      _currentEntry?._targetOffset = activity.targetOffset;
    }
  }

  void didChangeInternalStateOfEntry(_PagedSheetEntry entry) {
    if (_currentEntry == entry) {
      config = config.copyWith(snapGrid: entry.snapGrid);
    }
  }

  void didStartTransition(
    _PagedSheetEntry currentEntry,
    _PagedSheetEntry nextEntry,
    Animation<double> animation,
    bool isUserGestureInProgress,
  ) {
    _currentEntry = null;

    final Curve effectiveCurve;
    final Animation<double> effectiveAnimation;
    if (isUserGestureInProgress) {
      effectiveCurve = Curves.linear;
      effectiveAnimation = animation.drive(Tween(begin: 1.0, end: 0.0));
    } else if (animation.status == AnimationStatus.reverse) {
      effectiveCurve = config.offsetInterpolationCurve;
      effectiveAnimation = animation.drive(Tween(begin: 1.0, end: 0.0));
    } else {
      effectiveCurve = config.offsetInterpolationCurve;
      effectiveAnimation = animation;
    }

    ValueGetter<double?> targetOffsetResolver(_PagedSheetEntry entry) {
      return () {
        if (entry._contentSize case final contentSize?) {
          return (entry._targetOffset ?? entry.initialOffset)
              .resolve(copyWith(contentSize: contentSize));
        }
        return null;
      };
    }

    beginActivity(
      _RouteTransitionSheetActivity(
        originRouteOffset: targetOffsetResolver(currentEntry),
        destinationRouteOffset: targetOffsetResolver(nextEntry),
        animation: effectiveAnimation,
        animationCurve: effectiveCurve,
      ),
    );
  }

  void didEndTransition(_PagedSheetEntry entry) {
    _currentEntry = entry;
    didChangeInternalStateOfEntry(entry);
    goIdle();
  }
}

class _RouteTransitionSheetActivity extends SheetActivity<_PagedSheetModel> {
  _RouteTransitionSheetActivity({
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
  void init(_PagedSheetModel owner) {
    super.init(owner);
    owner.config = owner.config.copyWith(snapGrid: _kDefaultSnapGrid);
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
      owner.offset = lerpDouble(originOffset, destOffset, fraction)!;
    }
  }
}

class PagedSheet extends StatelessWidget {
  const PagedSheet({
    super.key,
    this.controller,
    this.physics = kDefaultSheetPhysics,
    this.offsetInterpolationCurve = Curves.easeInOutCubic,
    this.resizeChildToAvoidViewInsets = true,
    required this.child,
  });

  final SheetController? controller;

  final SheetPhysics physics;

  final Curve offsetInterpolationCurve;

  final bool resizeChildToAvoidViewInsets;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetModelOwner(
      factory: _PagedSheetModel.new,
      controller: controller ?? SheetControllerScope.maybeOf(context),
      config: _PagedSheetModelConfig(
        physics: physics,
        gestureProxy: SheetGestureProxy.maybeOf(context),
        offsetInterpolationCurve: offsetInterpolationCurve,
      ),
      child: BareSheet(
        resizeChildToAvoidBottomOverlap: resizeChildToAvoidViewInsets,
        child: NavigatorResizable(
          interpolationCurve: Curves.linear,
          child: _NavigatorEventDispatcher(
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NavigatorEventDispatcher extends StatefulWidget {
  const _NavigatorEventDispatcher({
    required this.child,
  });

  final Widget child;

  @override
  State<_NavigatorEventDispatcher> createState() =>
      _NavigatorEventDispatcherState();
}

class _NavigatorEventDispatcherState extends State<_NavigatorEventDispatcher>
    with NavigatorEventListener {
  _PagedSheetModel? _model;
  NavigatorEventObserverState? _navigatorEventObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _model = SheetModelOwner.of(context)! as _PagedSheetModel;
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
    _model = null;
    super.dispose();
  }

  @override
  void didStartTransition(
    Route<dynamic> currentRoute,
    Route<dynamic> nextRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {
    if ((currentRoute, nextRoute)
        case (
          final _PagedSheetEntry currentEntry,
          final _PagedSheetEntry nextEntry
        )) {
      _model!.didStartTransition(
        currentEntry,
        nextEntry,
        animation,
        isUserGestureInProgress,
      );
    }
  }

  @override
  void didEndTransition(Route<dynamic> route) {
    if (route case final _PagedSheetEntry entry) {
      _model!.didEndTransition(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _RouteContentLayoutObserver extends SingleChildRenderObjectWidget {
  const _RouteContentLayoutObserver({
    required this.onContentSizeChanged,
    required super.child,
  });

  final ValueChanged<Size> onContentSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRouteContentLayoutObserver(onContentSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRouteContentLayoutObserver renderObject,
  ) {}
}

class _RenderRouteContentLayoutObserver extends RenderProxyBox {
  _RenderRouteContentLayoutObserver(this.onContentSizeChanged);

  final ValueChanged<Size> onContentSizeChanged;

  @override
  void performLayout() {
    super.performLayout();
    if (child?.size case final childSize?) {
      onContentSizeChanged(childSize);
    }
  }
}

@optionalTypeArgs
abstract class _BasePagedSheetRoute<T> extends PageRoute<T>
    with ObservableRouteMixin<T>, _PagedSheetEntry {
  _BasePagedSheetRoute({super.settings});

  _PagedSheetModel? _model;

  @override
  SheetOffset get initialOffset;

  @override
  SheetSnapGrid get snapGrid;

  RouteTransitionsBuilder? get transitionsBuilder;

  SheetDragConfiguration? get dragConfiguration;

  // TODO: Apply new configuration when the current route changes.
  SheetScrollConfiguration? get scrollConfiguration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  void install() {
    super.install();
    _model = SheetModelOwner.of(navigator!.context)! as _PagedSheetModel;
  }

  @override
  void dispose() {
    _model = null;
    super.dispose();
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    _model = SheetModelOwner.of(navigator!.context)! as _PagedSheetModel;
  }

  @override
  void changedInternalState() {
    super.changedInternalState();
    _model!.didChangeInternalStateOfEntry(this);
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is _BasePagedSheetRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is _BasePagedSheetRoute;
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
        onContentSizeChanged: (size) => _contentSize = size,
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

class PagedSheetRoute<T> extends _BasePagedSheetRoute<T> {
  PagedSheetRoute({
    super.settings,
    this.maintainState = true,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset.relative(1),
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset.relative(1)),
    this.transitionsBuilder,
    required this.builder,
  });

  @override
  final SheetOffset initialOffset;

  @override
  final SheetSnapGrid snapGrid;

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
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset.relative(1)),
    this.physics = kDefaultSheetPhysics,
    this.transitionsBuilder,
    required this.child,
  });

  final SheetOffset initialOffset;

  final SheetSnapGrid snapGrid;

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

class _PageBasedNavigationSheetRoute<T> extends _BasePagedSheetRoute<T> {
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
  SheetSnapGrid get snapGrid => page.snapGrid;

  @override
  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page.child;
  }
}

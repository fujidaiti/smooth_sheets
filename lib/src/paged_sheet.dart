/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'draggable.dart';
library;

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

import 'activity.dart';
import 'controller.dart';
import 'draggable.dart';
import 'gesture_proxy.dart';
import 'model.dart';
import 'model_owner.dart';
import 'physics.dart';
import 'scrollable.dart';
import 'sheet.dart';
import 'snap_grid.dart';
import 'viewport.dart';

const _kDefaultSnapGrid = SteplessSnapGrid(
  minOffset: SheetOffset(0),
  maxOffset: SheetOffset(1),
);

mixin _PagedSheetEntry {
  SheetSnapGrid get snapGrid;

  SheetOffset get initialOffset;

  SheetScrollConfiguration? get scrollConfiguration;

  SheetDragConfiguration? get dragConfiguration;

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
      _currentEntry?.initialOffset ?? const SheetOffset(1);

  @override
  SheetScrollConfiguration get scrollConfiguration =>
      _currentEntry?.scrollConfiguration ?? const SheetScrollConfiguration();

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

  @override
  void applyNewLayout(SheetLayout layout) {
    // Workaround for https://github.com/fujidaiti/smooth_sheets/issues/315:
    //
    // When using auto_route and the sheet is fullscreen, the initialOffset is
    // ignored on the first build. The root cause is that AutoRouter,
    // which internally builds a Navigator, does not construct the Navigator
    // during the first frame in which the sheet is built.
    //
    // In that first frame, the initialOffset is ignored because _currentEntry
    // is not yet set. However, AutoRouter sizes itself to match the viewport,
    // so the 'layout' argument's contentSize equals the viewportSize.
    // In the following frame, AutoRouter builds the internal Navigator.
    // If the first route in the Navigator is fullscreen, the 'layout' will
    // have the exact same values as in the previous frame.
    // As a result, super.applyNewLayout() returns immediately,
    // and the initialOffset is not applied.
    //
    // This workaround applies a zero-sized layout to the sheet when it is first
    // built and _currentEntry is still null (implying that the Navigator has
    // not yet been built). This ensures that super.applyNewLayout updates the
    // offset to respect the initialOffset once the Navigator is built in the
    // next frame.
    if (!hasMetrics && _currentEntry == null) {
      super.applyNewLayout(
        ImmutableSheetLayout(
          contentBaseline: 0,
          size: Size.zero,
          contentSize: Size.zero,
          contentMargin: EdgeInsets.zero,
          viewportPadding: layout.viewportPadding,
          viewportSize: layout.viewportSize,
        ),
      );
    } else {
      super.applyNewLayout(layout);
    }
  }

  void didChangeInternalStateOfEntry(_PagedSheetEntry entry) {
    if (_currentEntry == entry) {
      config = config.copyWith(snapGrid: entry.snapGrid);
    }
  }

  void didStartTransition(
    _PagedSheetEntry targetEntry,
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
          return (entry._targetOffset ?? entry.initialOffset).resolve(
            copyWith(contentSize: contentSize),
          );
        }
        return null;
      };
    }

    beginActivity(
      _RouteTransitionSheetActivity(
        destinationRouteOffset: targetOffsetResolver(targetEntry),
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

  @override
  void goIdle() {
    beginActivity(_PagedSheetIdleActivity());
  }
}

class _PagedSheetIdleActivity extends IdleSheetActivity<_PagedSheetModel> {
  _PagedSheetIdleActivity();

  @override
  void init(_PagedSheetModel owner) {
    super.init(owner);
    if (owner._currentEntry case _PagedSheetEntry(
      _contentSize: null,
      :final initialOffset,
    )) {
      targetOffset = initialOffset;
    }
  }
}

class _RouteTransitionSheetActivity extends SheetActivity<_PagedSheetModel> {
  _RouteTransitionSheetActivity({
    required this.destinationRouteOffset,
    required this.animation,
    required this.animationCurve,
  });

  final ValueGetter<double?> destinationRouteOffset;
  final Animation<double> animation;
  final Curve animationCurve;
  late final double _startPixelOffset;
  late final Animation<double> _effectiveAnimation;

  @override
  bool get shouldIgnorePointer => true;

  @override
  void init(_PagedSheetModel owner) {
    super.init(owner);
    _startPixelOffset = owner.offset;
    owner.config = owner.config.copyWith(snapGrid: _kDefaultSnapGrid);
    _effectiveAnimation = animation.drive(CurveTween(curve: animationCurve))
      ..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _effectiveAnimation.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    final fraction = _effectiveAnimation.value;
    final destOffset = destinationRouteOffset();

    if (destOffset != null) {
      owner.offset = lerpDouble(_startPixelOffset, destOffset, fraction)!;
      owner.didUpdateMetrics();
    }
  }
}

class PagedSheet extends StatelessWidget {
  const PagedSheet({
    super.key,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.controller,
    this.physics = kDefaultSheetPhysics,
    this.transitionCurve = Curves.easeInOutCubic,
    this.decoration = const DefaultSheetDecoration(),
    this.padding = EdgeInsets.zero,
    this.builder,
    required this.navigator,
  });

  /// The default drag configuration for all routes in this [PagedSheet].
  ///
  /// Individual routes can override this via their own
  /// [PagedSheetRoute.dragConfiguration]. If a route's `dragConfiguration` is
  /// `null`, it falls back to this value.
  ///
  /// Set to [SheetDragConfiguration.disabled] to disable dragging globally.
  ///
  /// This and per-route drag configurations also affect shared elements built
  /// by the [builder] callback. A shared element is a widget that is always
  /// displayed alongside all routes, such as an app bar (see [builder] for
  /// details). For example, if the current route's `dragConfiguration` is set
  /// to `.disabled`, the shared elements will not respond to drag gestures,
  /// just as the route content does not, regardless of the global
  /// [dragConfiguration].
  final SheetDragConfiguration dragConfiguration;

  final SheetController? controller;

  final SheetPhysics physics;

  /// The [Curve] used for both the offset and size transition animations
  /// when navigating to a new route within the [navigator].
  final Curve transitionCurve;

  final SheetDecoration decoration;

  /// {@macro viewport.BareSheet.padding}
  final EdgeInsets padding;

  /// A builder callback for inserting extra widgets between this
  /// [PagedSheet] and the [navigator].
  ///
  /// Think of this like the [WidgetsApp.builder] of [WidgetsApp]. A common use
  /// case is to create shared top bar and/or bottom bar that is always shown along
  /// with all routes in the [navigator].
  ///
  /// ```dart
  /// PagedSheet(
  ///   builder: (context, navigator) {
  ///     return SheetContentScaffold(
  ///       extendBodyBehindTopBar: true,
  ///       extendBodyBehindBottomBar: true,
  ///       topBar: AppBar(title: Text('Title')),
  ///       bottomBar: BottomNavigationBar(items: [...]),
  ///       body: navigator,
  ///     );
  ///   },
  ///   navigator: Navigator(...),
  /// )
  /// ```
  final Widget Function(BuildContext, Widget)? builder;

  final Widget navigator;

  @override
  Widget build(BuildContext context) {
    Widget content = NavigatorResizable(
      interpolationCurve: transitionCurve,
      child: _NavigatorEventDispatcher(child: navigator),
    );
    if (builder case final builder?) {
      content = builder(context, content);
    }

    return SheetModelOwner(
      factory: _PagedSheetModel.new,
      controller: controller ?? DefaultSheetController.maybeOf(context),
      config: _PagedSheetModelConfig(
        physics: physics,
        gestureProxy: SheetGestureProxy.maybeOf(context),
        offsetInterpolationCurve: transitionCurve,
      ),
      child: BareSheet(
        decoration: decoration,
        padding: padding,
        child: _RouteAwareSheetDraggable(
          defaultConfiguration: dragConfiguration,
          child: content,
        ),
      ),
    );
  }
}

class _RouteAwareSheetDraggable extends StatefulWidget {
  const _RouteAwareSheetDraggable({
    required this.defaultConfiguration,
    required this.child,
  });

  final SheetDragConfiguration defaultConfiguration;
  final Widget child;

  @override
  State<_RouteAwareSheetDraggable> createState() =>
      _RouteAwareSheetDraggableState();
}

class _RouteAwareSheetDraggableState extends State<_RouteAwareSheetDraggable>
    implements SheetDragConfiguration {
  late _PagedSheetModel _model;

  @override
  HitTestBehavior? get hitTestBehavior {
    final effectiveConfig =
        _model._currentEntry?.dragConfiguration ?? widget.defaultConfiguration;
    return effectiveConfig.hitTestBehavior;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _model = SheetModelOwner.of(context)! as _PagedSheetModel;
  }

  @override
  Widget build(BuildContext context) {
    return SheetDraggable(configuration: this, child: widget.child);
  }
}

class _NavigatorEventDispatcher extends StatefulWidget {
  const _NavigatorEventDispatcher({required this.child});

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
    Route<dynamic> targetRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {
    if (targetRoute case final _PagedSheetEntry entry) {
      _model!.didStartTransition(entry, animation, isUserGestureInProgress);
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
  ) {
    renderObject.onContentSizeChanged = onContentSizeChanged;
  }
}

class _RenderRouteContentLayoutObserver extends RenderProxyBox {
  _RenderRouteContentLayoutObserver(this.onContentSizeChanged);

  ValueChanged<Size> onContentSizeChanged;

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
          // _CurrentRouteAwareSheetDraggable already handles drag gestures
          // within the route content, so we eliminate per-route SheetDraggable.
          dragConfiguration: SheetDragConfiguration.disabled,
          child: buildContent(context, animation, secondaryAnimation),
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
    this.dragConfiguration,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset(1),
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset(1)),
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

  /// Overrides the global [PagedSheet.dragConfiguration] for this route.
  ///
  /// If `null`, the global configuration is inherited.
  /// Set to [SheetDragConfiguration.disabled] to explicitly disable
  /// dragging for this route.
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
    this.dragConfiguration,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset(1),
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset(1)),
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

  /// Overrides the global [PagedSheet.dragConfiguration] for the route
  /// associated with this page.
  ///
  /// If `null` (default), the global configuration is inherited.
  /// Set to [SheetDragConfiguration.disabled] to explicitly disable
  /// dragging for the route.
  final SheetDragConfiguration? dragConfiguration;

  final SheetScrollConfiguration? scrollConfiguration;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedPagedSheetRoute(page: this);
  }
}

class _PageBasedPagedSheetRoute<T> extends _BasePagedSheetRoute<T> {
  _PageBasedPagedSheetRoute({required PagedSheetPage<T> page})
    : super(settings: page);

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

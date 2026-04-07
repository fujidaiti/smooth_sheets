/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'draggable.dart';
library;

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

/// Holds default values for inheritable [PagedSheetRoute] and [PagedSheetPage]
/// parameters in a [PagedSheet].
///
/// Routes that don't specify a parameter will inherit the value from the
/// nearest [PagedSheetRouteTheme] ancestor.
@immutable
class PagedSheetRouteThemeData {
  /// Creates a [PagedSheetRouteThemeData] with the given defaults.
  const PagedSheetRouteThemeData({
    this.scrollConfiguration = SheetScrollConfiguration.disabled,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset(1),
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset(1)),
    this.transitionsBuilder,
  });

  static const _default = PagedSheetRouteThemeData();

  /// The default scroll configuration for routes.
  final SheetScrollConfiguration scrollConfiguration;

  /// The default drag configuration for routes.
  ///
  /// This is independent from [PagedSheet.dragConfiguration], which controls
  /// the sheet-level drag behavior for shared elements.
  final SheetDragConfiguration dragConfiguration;

  /// The default transition duration for routes.
  final Duration transitionDuration;

  /// The default initial offset for routes.
  final SheetOffset initialOffset;

  /// The default snap grid for routes.
  final SheetSnapGrid snapGrid;

  /// The default transitions builder for routes.
  final RouteTransitionsBuilder? transitionsBuilder;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PagedSheetRouteThemeData &&
            runtimeType == other.runtimeType &&
            scrollConfiguration == other.scrollConfiguration &&
            dragConfiguration == other.dragConfiguration &&
            transitionDuration == other.transitionDuration &&
            initialOffset == other.initialOffset &&
            snapGrid == other.snapGrid &&
            transitionsBuilder == other.transitionsBuilder;
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    scrollConfiguration,
    dragConfiguration,
    transitionDuration,
    initialOffset,
    snapGrid,
    transitionsBuilder,
  );
}

/// An [InheritedWidget] that provides default route parameter values
/// for [PagedSheetRoute]s and [PagedSheetPage]s in a [PagedSheet].
///
/// Place this widget above a [PagedSheet] to set shared defaults for all
/// routes. Individual routes can still override any parameter.
///
/// ```dart
/// PagedSheetRouteTheme(
///   data: PagedSheetRouteThemeData(
///     transitionsBuilder: myTransitionBuilder,
///     snapGrid: mySnapGrid,
///   ),
///   child: PagedSheet(
///     navigator: Navigator(...),
///   ),
/// )
/// ```
class PagedSheetRouteTheme extends InheritedWidget {
  /// Creates a [PagedSheetRouteTheme].
  const PagedSheetRouteTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The theme data for route defaults.
  final PagedSheetRouteThemeData data;

  /// Returns the [PagedSheetRouteThemeData] from the nearest
  /// [PagedSheetRouteTheme] ancestor, or the built-in defaults if none exists.
  static PagedSheetRouteThemeData of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<PagedSheetRouteTheme>()
            ?.data ??
        PagedSheetRouteThemeData._default;
  }

  @override
  bool updateShouldNotify(PagedSheetRouteTheme oldWidget) {
    return data != oldWidget.data;
  }
}

mixin _PagedSheetEntry {
  SheetSnapGrid? get snapGrid;

  SheetOffset? get initialOffset;

  SheetScrollConfiguration? get scrollConfiguration;

  SheetDragConfiguration? get dragConfiguration;

  SheetOffset? _lastSettledOffset;

  Size? _contentSize;
}

class _PagedSheetModelConfig extends SheetModelConfig {
  const _PagedSheetModelConfig({
    required super.physics,
    required super.gestureProxy,
    super.snapGrid = _kDefaultSnapGrid,
    required this.offsetInterpolationCurve,
    required this.routeThemeData,
  });

  final Curve offsetInterpolationCurve;

  final PagedSheetRouteThemeData routeThemeData;

  @override
  _PagedSheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
    Curve? offsetInterpolationCurve,
    PagedSheetRouteThemeData? routeThemeData,
  }) {
    return _PagedSheetModelConfig(
      physics: physics ?? this.physics,
      snapGrid: snapGrid ?? this.snapGrid,
      gestureProxy: gestureProxy ?? this.gestureProxy,
      offsetInterpolationCurve:
          offsetInterpolationCurve ?? this.offsetInterpolationCurve,
      routeThemeData: routeThemeData ?? this.routeThemeData,
    );
  }
}

class _PagedSheetModel extends SheetModel<_PagedSheetModelConfig>
    with ScrollAwareSheetModelMixin<_PagedSheetModelConfig> {
  _PagedSheetModel(super.context, super.config) {
    // This activity only initializes the offset to 0 to satisfy the SheetModel
    // contract. It waits for didEndTransition callback to be called with the
    // initial route entry, which eventually updates the offset to the correct
    // value for that route.
    beginActivity(_InitialActivity());
  }

  _PagedSheetEntry? _currentEntry;

  SheetScrollConfiguration _resolveScrollConfiguration(
    _PagedSheetEntry? entry,
  ) {
    return entry?.scrollConfiguration ??
        config.routeThemeData.scrollConfiguration;
  }

  SheetSnapGrid _resolveSnapGrid(_PagedSheetEntry? entry) {
    return entry?.snapGrid ?? config.routeThemeData.snapGrid;
  }

  SheetOffset _resolveInitialOffset(_PagedSheetEntry? entry) {
    return entry?.initialOffset ?? config.routeThemeData.initialOffset;
  }

  @override
  SheetScrollConfiguration get scrollConfiguration =>
      _resolveScrollConfiguration(_currentEntry);

  @override
  set config(_PagedSheetModelConfig value) {
    final resolvedSnapGrid = _resolveSnapGrid(_currentEntry);
    if (_currentEntry != null && resolvedSnapGrid != value.snapGrid) {
      // Always respects the snap grid of the current entry if exists.
      super.config = value.copyWith(snapGrid: resolvedSnapGrid);
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
      // Saves the offset to which the current entry settles when idle,
      // so that we can restore it when returning to this entry from another
      // via, e.g., Navigator.pop().
      _currentEntry?._lastSettledOffset = activity.targetOffset;
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
      config = config.copyWith(snapGrid: _resolveSnapGrid(entry));
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

    beginActivity(
      _TransitionActivity(
        destinationEntry: targetEntry,
        animation: effectiveAnimation,
        animationCurve: effectiveCurve,
      ),
    );
  }

  void didEndTransition(_PagedSheetEntry entry) {
    _currentEntry = entry;
    didChangeInternalStateOfEntry(entry);
    if (entry._contentSize != null) {
      goIdle();
    } else {
      // The new route size is not yet available, so we cannot determine the
      // final sheet offset here. This can occur when the initial route is
      // pushed to the Navigator stack, or when the route changes without
      // animation (e.g., via Navigator.replace()).
      //
      // In these cases, didEndTransition is called before the layout phase
      // where the new route is first laid out.
      // _PostTransitionWithoutAnimationActivity waits for the size to become
      // available, then updates the offset to the correct value and goes idle.
      beginActivity(_PostTransitionWithoutAnimationActivity(newEntry: entry));
    }
  }
}

class _InitialActivity extends SheetActivity<_PagedSheetModel> {
  @override
  bool get shouldIgnorePointer => true;

  @override
  double dryApplyNewLayout(ViewportLayout layout) =>
      owner.hasMetrics ? owner.offset : 0;

  @override
  void applyNewLayout(ViewportLayout? oldLayout) {
    if (!owner.hasMetrics) {
      owner.offset = dryApplyNewLayout(owner);
    }
  }
}

class _TransitionActivity extends SheetActivity<_PagedSheetModel> {
  _TransitionActivity({
    required this.destinationEntry,
    required this.animation,
    required this.animationCurve,
  });

  final _PagedSheetEntry destinationEntry;
  final Animation<double> animation;
  final Curve animationCurve;
  late final Animation<double> _effectiveAnimation;
  late final double _startOffset;

  @override
  bool get shouldIgnorePointer => true;

  @override
  void init(_PagedSheetModel owner) {
    super.init(owner);
    assert(
      owner.hasMetrics,
      '$runtimeType can not be the initial activity of the model.',
    );
    _startOffset = owner.offset;
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
    final targetSize = destinationEntry._contentSize;
    if (targetSize == null) {
      // The new route is not yet laid out.
      return;
    }

    final layoutAfterTransition = owner.copyWith(contentSize: targetSize);
    final preferredEndOffset =
        destinationEntry._lastSettledOffset ??
        owner._resolveInitialOffset(destinationEntry);
    final endOffset = owner
        ._resolveSnapGrid(destinationEntry)
        .getSnapOffset(
          layoutAfterTransition,
          preferredEndOffset.resolve(layoutAfterTransition),
          0,
        );

    owner
      ..offset = lerpDouble(
        _startOffset,
        endOffset.resolve(layoutAfterTransition),
        _effectiveAnimation.value,
      )!
      ..didUpdateMetrics();
  }
}

class _PostTransitionWithoutAnimationActivity
    extends SheetActivity<_PagedSheetModel> {
  _PostTransitionWithoutAnimationActivity({required this.newEntry});

  final _PagedSheetEntry newEntry;

  @override
  bool get shouldIgnorePointer => true;

  @override
  void init(_PagedSheetModel owner) {
    super.init(owner);
    assert(newEntry._contentSize == null);
  }

  @override
  double dryApplyNewLayout(ViewportLayout layout) =>
      _effectiveInitialOffset(layout).resolve(layout);

  @override
  void applyNewLayout(ViewportLayout? oldLayout) {
    final targetOffset = _effectiveInitialOffset(owner);
    owner
      ..offset = targetOffset.resolve(owner)
      ..didUpdateMetrics()
      ..goIdle(targetOffset: targetOffset);
  }

  SheetOffset _effectiveInitialOffset(ViewportLayout layout) {
    assert(layout.contentSize == newEntry._contentSize);
    assert(newEntry._lastSettledOffset == null);
    return owner
        ._resolveSnapGrid(newEntry)
        .getSnapOffset(
          layout,
          owner._resolveInitialOffset(newEntry).resolve(layout),
          velocity,
        );
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

  /// The drag configuration for this sheet.
  ///
  /// This controls drag behavior for the sheet itself and shared elements built
  /// by the [builder] callback. Set to [SheetDragConfiguration.disabled] to
  /// disable dragging for shared elements.
  ///
  /// Note that this value does not affect the drag behavior of individual
  /// routes. Even if this is set to [SheetDragConfiguration.disabled], routes
  /// with non-[SheetDragConfiguration.disabled] drag configuration can still
  /// be dragged except for the shared elements.
  ///
  /// However, the opposite is not true: if the current route's drag
  /// configuration is [SheetDragConfiguration.disabled], the shared elements
  /// will also not be draggable even if this is set to
  /// a non-[SheetDragConfiguration.disabled] value. This behavior is useful
  /// in cases where the sheet has a shared top bar and you want to entirely
  /// disable dragging for a certain route including the shared top bar.
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
        routeThemeData: PagedSheetRouteTheme.of(context),
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
    if (_model._currentEntry case final entry?) {
      // When a route is active, resolve from route → theme → built-in default.
      final effectiveConfig =
          entry.dragConfiguration ??
          _model.config.routeThemeData.dragConfiguration;
      return effectiveConfig.hitTestBehavior;
    }
    // When no route is active, use the sheet-level config.
    return widget.defaultConfiguration.hitTestBehavior;
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
  SheetOffset? get initialOffset;

  @override
  SheetSnapGrid? get snapGrid;

  RouteTransitionsBuilder? get transitionsBuilder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  PagedSheetRouteThemeData get _routeThemeData =>
      _model?.config.routeThemeData ?? PagedSheetRouteThemeData._default;

  @override
  void install() {
    super.install();
    _model = SheetModelOwner.of(navigator!.context)! as _PagedSheetModel;
    controller!
      ..duration = transitionDuration
      ..reverseDuration = reverseTransitionDuration;
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
    controller!
      ..duration = transitionDuration
      ..reverseDuration = reverseTransitionDuration;
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
          scrollConfiguration:
              scrollConfiguration ?? _routeThemeData.scrollConfiguration,
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
    final resolvedBuilder =
        transitionsBuilder ?? _routeThemeData.transitionsBuilder;
    if (resolvedBuilder case final builder?) {
      return builder(context, animation, secondaryAnimation, child);
    }
    final theme = Theme.of(context);
    return switch (theme.platform) {
      TargetPlatform.android =>
        _FadeForwardPageTransitionWithAnimationLessBackGesture(
          route: this,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
      _ => theme.pageTransitionsTheme.buildTransitions(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    };
  }
}

class PagedSheetRoute<T> extends _BasePagedSheetRoute<T> {
  PagedSheetRoute({
    super.settings,
    this.maintainState = true,
    this.scrollConfiguration,
    this.dragConfiguration,
    Duration? transitionDuration,
    SheetOffset? initialOffset,
    SheetSnapGrid? snapGrid,
    this.transitionsBuilder,
    required this.builder,
  }) : _transitionDuration = transitionDuration,
       _initialOffset = initialOffset,
       _snapGrid = snapGrid;

  final SheetOffset? _initialOffset;

  /// The initial offset for this route.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  @override
  SheetOffset? get initialOffset => _initialOffset;

  final SheetSnapGrid? _snapGrid;

  /// The snap grid for this route.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  @override
  SheetSnapGrid? get snapGrid => _snapGrid;

  @override
  final bool maintainState;

  final Duration? _transitionDuration;

  /// The transition duration for this route.
  ///
  /// If not specified, inherits from the nearest [PagedSheetRouteTheme]
  /// ancestor.
  @override
  Duration get transitionDuration =>
      _transitionDuration ?? _routeThemeData.transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  /// Overrides the [PagedSheetRouteTheme]'s drag configuration for this route.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  /// Set to [SheetDragConfiguration.disabled] to explicitly disable
  /// dragging for this route.
  @override
  final SheetDragConfiguration? dragConfiguration;

  /// The scroll configuration for this route.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  /// Set to [SheetScrollConfiguration.disabled] to explicitly disable
  /// scroll-sheet integration.
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
    this.transitionDuration,
    this.initialOffset,
    this.snapGrid,
    this.physics = kDefaultSheetPhysics,
    this.transitionsBuilder,
    required this.child,
  });

  /// The initial offset for the route created by this page.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  final SheetOffset? initialOffset;

  /// The snap grid for the route created by this page.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  final SheetSnapGrid? snapGrid;

  final SheetPhysics physics;

  final bool maintainState;

  /// The transition duration for the route created by this page.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  final Duration? transitionDuration;

  final RouteTransitionsBuilder? transitionsBuilder;

  /// Overrides the [PagedSheetRouteTheme]'s drag configuration for the route
  /// associated with this page.
  ///
  /// If `null` (default), inherits from the nearest [PagedSheetRouteTheme].
  /// Set to [SheetDragConfiguration.disabled] to explicitly disable
  /// dragging for the route.
  final SheetDragConfiguration? dragConfiguration;

  /// The scroll configuration for the route created by this page.
  ///
  /// If `null`, inherits from the nearest [PagedSheetRouteTheme] ancestor.
  /// Set to [SheetScrollConfiguration.disabled] to explicitly disable
  /// scroll-sheet integration.
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
  Duration get transitionDuration =>
      page.transitionDuration ?? _routeThemeData.transitionDuration;

  @override
  RouteTransitionsBuilder? get transitionsBuilder => page.transitionsBuilder;

  @override
  SheetDragConfiguration? get dragConfiguration => page.dragConfiguration;

  @override
  SheetScrollConfiguration? get scrollConfiguration => page.scrollConfiguration;

  @override
  SheetOffset? get initialOffset => page.initialOffset;

  @override
  SheetSnapGrid? get snapGrid => page.snapGrid;

  @override
  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page.child;
  }
}

/// A transition that enables Android's predictive back gesture to pop routes
/// within the nested [Navigator], without modifying route transition progress
/// during the gesture.
///
/// This is a workaround for the issue where [TransitionRoute.animation]
/// jumps from a mid-transition value to 1.0 when the back gesture is committed,
/// causing an abrupt pop-transition animation.
///
/// The root cause is that [TransitionRoute.handleUpdateBackGestureProgress]
/// updates the [TransitionRoute.controller]'s value as the gesture progresses,
/// but [TransitionRoute.handleCommitBackGesture] triggers the transition
/// animation via [AnimationController.reverse] with 1.0 as the starting point,
/// regardless of the current [TransitionRoute.controller]'s value.
///
/// The default back gesture handler behaves this way, but is incompatible with
/// [PagedSheet]'s size transition. This transition widget therefore suppresses
/// that gesture-driven transition progress while still allowing the gesture to
/// commit a route pop.
class _FadeForwardPageTransitionWithAnimationLessBackGesture
    extends StatefulWidget {
  const _FadeForwardPageTransitionWithAnimationLessBackGesture({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final PageRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_FadeForwardPageTransitionWithAnimationLessBackGesture> createState() =>
      _FadeForwardPageTransitionWithAnimationLessBackGestureState();
}

class _FadeForwardPageTransitionWithAnimationLessBackGestureState
    extends State<_FadeForwardPageTransitionWithAnimationLessBackGesture>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    return !backEvent.isButtonEvent &&
        widget.route.isCurrent &&
        !widget.route.isFirst;
  }

  @override
  void handleCancelBackGesture() {
    _handleEndBackGesture(isCommitted: false);
  }

  @override
  void handleCommitBackGesture() {
    _handleEndBackGesture(isCommitted: true);
  }

  void _handleEndBackGesture({required bool isCommitted}) {
    if (isCommitted && widget.route.isCurrent) {
      widget.route.navigator?.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const FadeForwardsPageTransitionsBuilder().buildTransitions(
      widget.route,
      context,
      widget.animation,
      widget.secondaryAnimation,
      widget.child,
    );
  }
}

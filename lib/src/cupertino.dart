import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'internal/double_utils.dart';
import 'modal.dart';
import 'model.dart';
import 'viewport.dart';

const _sheetTopInset = 12.0;
const _minimizedSheetScale = 0.92;
const _minimizedSheetCornerRadius = 12.0;
const _barrierColor = Color(0x18000000);
const _transitionDuration = Duration(milliseconds: 300);
const Cubic _outgoingTransitionCurve = Curves.easeIn;
const ThreePointCubic _incomingTransitionCurve = Curves.fastEaseInToSlowEaseOut;

/// Animated version of [ClipRRect].
///
/// The [radius] animation can be updated during the layout phase,
/// allowing the corner radius to depend on the sheet position and
/// reflect the new value in the subsequent painting phase.
class _ClipRRectTransition extends SingleChildRenderObjectWidget {
  const _ClipRRectTransition({
    required this.radius,
    required super.child,
  });

  final Animation<double> radius;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderClipRRectTransition(radius: radius);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderClipRRectTransition renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.radius = radius;
  }
}

class _RenderClipRRectTransition extends RenderClipRRect {
  _RenderClipRRectTransition({
    required Animation<double> radius,
  })  : _radius = radius,
        super(clipBehavior: Clip.antiAlias) {
    _radius.addListener(_invalidateBorderRadius);
  }

  Animation<double> _radius;

  // ignore: avoid_setters_without_getters
  set radius(Animation<double> value) {
    if (_radius != value) {
      _radius.removeListener(_invalidateBorderRadius);
      _radius = value..addListener(_invalidateBorderRadius);
      _invalidateBorderRadius();
    }
  }

  @override
  void dispose() {
    _radius.removeListener(_invalidateBorderRadius);
    super.dispose();
  }

  void _invalidateBorderRadius() {
    borderRadius = BorderRadius.circular(_radius.value);
  }
}

/// Animated version of [Transform].
///
/// The [animation] can be updated during the layout phase,
/// allowing the transform to depend on the sheet position and
/// reflect the new value in the subsequent painting phase.
class _TransformTransition extends SingleChildRenderObjectWidget {
  const _TransformTransition({
    required this.animation,
    required this.offsetTween,
    required this.scaleTween,
    required super.child,
  });

  final Animation<double> animation;
  final Tween<Offset> offsetTween;
  final Tween<double> scaleTween;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTransformTransition(
      animation: animation,
      scaleTween: scaleTween,
      offsetTween: offsetTween,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTransformTransition renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject
      ..animation = animation
      ..scaleTween = scaleTween
      ..offsetTween = offsetTween;
  }
}

class _RenderTransformTransition extends RenderTransform {
  _RenderTransformTransition({
    required Animation<double> animation,
    required Tween<double> scaleTween,
    required Tween<Offset> offsetTween,
  })  : _animation = animation,
        _scaleTween = scaleTween,
        _offsetTween = offsetTween,
        super(
          transform: Matrix4.identity(),
          alignment: Alignment.topCenter,
          transformHitTests: true,
        ) {
    _animation.addListener(_invalidateMatrix);
  }

  Animation<double> _animation;

  // ignore: avoid_setters_without_getters
  set animation(Animation<double> value) {
    if (_animation != value) {
      _animation.removeListener(_invalidateMatrix);
      _animation = value..addListener(_invalidateMatrix);
      _invalidateMatrix();
    }
  }

  Tween<double> _scaleTween;

  // ignore: avoid_setters_without_getters
  set scaleTween(Tween<double> value) {
    if (_scaleTween != value) {
      _scaleTween = value;
      _invalidateMatrix();
    }
  }

  Tween<Offset> _offsetTween;

  // ignore: avoid_setters_without_getters
  set offsetTween(Tween<Offset> value) {
    if (_offsetTween != value) {
      _offsetTween = value;
      _invalidateMatrix();
    }
  }

  @override
  void dispose() {
    _animation.removeListener(_invalidateMatrix);
    super.dispose();
  }

  void _invalidateMatrix() {
    final scaleFactor = _scaleTween.transform(_animation.value);
    final offset = _offsetTween.transform(_animation.value);
    transform = Matrix4.translationValues(offset.dx, offset.dy, 0.0)
      ..scale(scaleFactor, scaleFactor, 1.0);
  }
}

/// A transition for a route that is just below an incoming cupertino-style
/// modal sheet route in the navigation stack.
class _OutgoingTransition extends StatefulWidget {
  const _OutgoingTransition({
    required this.endOffset,
    required this.child,
  });

  final Offset endOffset;
  final Widget child;

  @override
  State<_OutgoingTransition> createState() => _OutgoingTransitionState();
}

class _OutgoingTransitionState extends State<_OutgoingTransition> {
  _OutgoingTransitionController? _controller;
  late final Animation<double> _animation;
  late final PageRoute<dynamic> _parentRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _parentRoute = ModalRoute.of(context)! as PageRoute<dynamic>;
      _controller = _OutgoingTransitionController(route: _parentRoute);
      _animation = CurvedAnimation(
        parent: _controller!,
        curve: _outgoingTransitionCurve,
      );
    } else {
      assert(ModalRoute.of(context) == _parentRoute);
    }
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TransformTransition(
      animation: _animation,
      offsetTween: Tween(
        begin: Offset.zero,
        end: widget.endOffset,
      ),
      scaleTween: Tween(begin: 1, end: _minimizedSheetScale),
      child: _ClipRRectTransition(
        radius: Tween(
          begin: 0.0,
          end: _minimizedSheetCornerRadius,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

/// Controls the progress of the outgoing transition of a route
/// that is just below an incoming cupertino-style modal sheet route
/// in the navigation stack.
class _OutgoingTransitionController extends Animation<double>
    with ChangeNotifier {
  _OutgoingTransitionController({
    required this.route,
  }) : assert(!_routeToControllerMap.containsKey(route)) {
    _routeToControllerMap[route] = this;
    route.secondaryAnimation!.addListener(_invalidateValue);
    _invalidateValue();
  }

  static final _routeToControllerMap =
      <Route<dynamic>, _OutgoingTransitionController>{};

  /// Returns the [_OutgoingTransitionController] associated with the
  /// [route], if any.
  ///
  /// Used by the incoming [_BaseCupertinoModalSheetRoute] to synchronize
  /// its own animation with the outgoing transition of the previous route.
  static _OutgoingTransitionController? of(Route<dynamic>? route) =>
      _routeToControllerMap[route];

  final PageRoute<dynamic> route;

  /// The progress of the outgoing transition.
  ///
  /// Must be between 0 and 1.
  @override
  double get value => _value;
  double _value = 0;

  /// The latest metrics of the incoming modal sheet above the [route].
  SheetMetrics? _lastReportedSheetMetrics;

  /// Updates the animation [value] of the transition based on the latest
  /// [metrics] of the sheet in the incoming [_BaseCupertinoModalSheetRoute].
  void applyNewIncomingSheetMetrics(SheetMetrics metrics) {
    _lastReportedSheetMetrics = metrics;
    _invalidateValue();
  }

  void _invalidateValue() {
    if (route.offstage) {
      // On the first build of the incoming route, its animation value
      // is set to 1, allowing the navigator to measure the final size
      // of the route before starting the transition.
      // After that, however, the animation value sudenly jumps from 1 to 0,
      // then gradually changes back to 1.
      //
      // In this case, we need to ignore the animation value notified
      // before the transition starts to prevent the outgoing transition
      // from appearing choppy.
      return;
    }

    final oldValue = _value;
    final sheetMetrics = _lastReportedSheetMetrics;
    if (sheetMetrics == null) {
      _value = route.secondaryAnimation!.value;
    } else {
      _value = min(
        route.secondaryAnimation!.value,
        sheetMetrics.offset
            .inverseLerp(sheetMetrics.minOffset, sheetMetrics.maxOffset)
            .clamp(0, 1),
      );
    }

    if (_value != oldValue) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _routeToControllerMap.remove(route);
    route.secondaryAnimation!.removeListener(_invalidateValue);
    super.dispose();
  }

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  void addStatusListener(AnimationStatusListener listener) {
    // The status will never change.
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    // The status will never change.
  }
}

class _SheetModelObserver extends StatefulWidget {
  const _SheetModelObserver({
    required this.onMetricsChanged,
    required this.child,
  });

  final ValueChanged<SheetMetrics> onMetricsChanged;
  final Widget child;

  @override
  State<_SheetModelObserver> createState() => _SheetModelObserverState();
}

class _SheetModelObserverState extends State<_SheetModelObserver> {
  SheetModelView? _model;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = SheetViewportState.of(context)?.model;
    if (model != _model) {
      _model?.removeListener(_invokeCallback);
      _model = model?..addListener(_invokeCallback);
    }
  }

  void _invokeCallback() => widget.onMetricsChanged(_model!.copyWith());

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

abstract class _BaseCupertinoModalSheetRoute<T> extends PageRoute<T>
    with ModalSheetRouteMixin<T> {
  _BaseCupertinoModalSheetRoute({super.settings});

  Route<dynamic>? _previousRoute;

  @override
  // TODO: Support custom viewport padding.
  EdgeInsets get viewportPadding => EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(navigator!.context).top + _sheetTopInset,
      );

  @override
  void dispose() {
    _previousRoute = null;
    super.dispose();
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    _previousRoute = previousRoute;
    super.didChangePrevious(previousRoute);
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is _BaseCupertinoModalSheetRoute;
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final previousRoute = _previousRoute;
    if (previousRoute != null &&
        previousRoute is PageRoute &&
        previousRoute is! _BaseCupertinoModalSheetRoute &&
        !previousRoute.fullscreenDialog) {
      return _buildOutgoingTransitionForNonCupertinoModalSheetRoute;
    }

    return null;
  }

  Widget? _buildOutgoingTransitionForNonCupertinoModalSheetRoute(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _OutgoingTransition(
      endOffset: Offset(0, MediaQuery.viewPaddingOf(context).top),
      child: child!,
    );
  }

  @nonVirtual
  @override
  Widget buildSheet(BuildContext context) {
    return _SheetModelObserver(
      onMetricsChanged: (metrics) {
        _OutgoingTransitionController.of(_previousRoute)
            ?.applyNewIncomingSheetMetrics(metrics);
      },
      child: _OutgoingTransition(
        endOffset: const Offset(0, -1 * _sheetTopInset),
        child: _buildSheetInternal(context),
      ),
    );
  }

  Widget _buildSheetInternal(BuildContext context);
}

class CupertinoModalSheetPage<T> extends Page<T> {
  const CupertinoModalSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.swipeDismissible = false,
    this.barrierLabel,
    this.barrierColor = _barrierColor,
    this.transitionDuration = _transitionDuration,
    this.transitionCurve = _incomingTransitionCurve,
    this.swipeDismissSensitivity = const SwipeDismissSensitivity(),
    required this.child,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Color? barrierColor;

  final bool barrierDismissible;

  final bool swipeDismissible;

  final String? barrierLabel;

  final Duration transitionDuration;

  final Curve transitionCurve;

  final SwipeDismissSensitivity swipeDismissSensitivity;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedCupertinoModalSheetRoute(
      page: this,
    );
  }
}

class _PageBasedCupertinoModalSheetRoute<T>
    extends _BaseCupertinoModalSheetRoute<T> {
  _PageBasedCupertinoModalSheetRoute({
    required CupertinoModalSheetPage<T> page,
  }) : super(settings: page);

  CupertinoModalSheetPage<T> get _page =>
      settings as CupertinoModalSheetPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  bool get swipeDismissible => _page.swipeDismissible;

  @override
  Curve get transitionCurve => _page.transitionCurve;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  SwipeDismissSensitivity get swipeDismissSensitivity =>
      _page.swipeDismissSensitivity;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget _buildSheetInternal(BuildContext context) => _page.child;
}

class CupertinoModalSheetRoute<T> extends _BaseCupertinoModalSheetRoute<T> {
  CupertinoModalSheetRoute({
    super.settings,
    required this.builder,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.swipeDismissible = false,
    this.barrierLabel,
    this.barrierColor = _barrierColor,
    this.transitionDuration = _transitionDuration,
    this.transitionCurve = _incomingTransitionCurve,
    this.swipeDismissSensitivity = const SwipeDismissSensitivity(),
  });

  final WidgetBuilder builder;

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final bool swipeDismissible;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final Curve transitionCurve;

  @override
  final SwipeDismissSensitivity swipeDismissSensitivity;

  @override
  Widget _buildSheetInternal(BuildContext context) => builder(context);
}

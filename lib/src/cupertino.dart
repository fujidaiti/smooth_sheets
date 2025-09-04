import 'dart:math';

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
const Cubic _outgoingTransitionOverlayCurve = Curves.easeIn;
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
class _ToningOverlay extends SingleChildRenderObjectWidget {
  const _ToningOverlay({
    required this.animation,
    required this.color,
    required super.child,
  });

  final Animation<double> animation;
  final Color color;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderToningOverlay(
      animation: animation,
      color: color,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderToningOverlay renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject
      ..animation = animation
      ..color = color;
  }
}

class _RenderToningOverlay extends RenderProxyBox {
  _RenderToningOverlay({
    required Animation<double> animation,
    required Color color,
  })  : _animation = animation,
        _color = color {
    _animation.addListener(markNeedsPaint);
  }

  Animation<double> _animation;

  // ignore: avoid_setters_without_getters
  set animation(Animation<double> value) {
    if (_animation != value) {
      _animation.removeListener(markNeedsPaint);
      _animation = value..addListener(markNeedsPaint);
      markNeedsPaint();
    }
  }

  Color _color;

  // ignore: avoid_setters_without_getters
  set color(Color value) {
    if (_color != value) {
      _color = value;
      markNeedsPaint();
    }
  }

  @override
  void dispose() {
    _animation.removeListener(markNeedsPaint);
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paint the child first
    super.paint(context, offset);

    final effectiveToneColor = Color.lerp(
      const Color(0x00000000),
      _color,
      _outgoingTransitionOverlayCurve.transform(_animation.value),
    )!;

    if (_animation.value > 0) {
      final paint = Paint()
        ..color = effectiveToneColor
        ..style = PaintingStyle.fill;
      context.canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
        paint,
      );
    }
  }
}

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
      // ignore: lines_longer_than_80_chars
      // TODO: Migrate to scaleByVector3 when minimum SDK version is raised to 3.35.0
      //
      // vector_math package has been upgraded to 2.2.0 in Flutter 3.35.0,
      // in which the `scale` method has been deprecated.
      // See: https://github.com/flutter/flutter/commit/c08e9dff6865b91a3c20bb39980053951a6cae34
      // ignore: deprecated_member_use
      ..scale(scaleFactor, scaleFactor, 1.0);
  }
}

/// A transition widget for a route that is immediately below an incoming
/// Cupertino-style modal sheet route in the navigation stack.
///
/// The outgoing transition is triggered when a [_BaseCupertinoModalSheetRoute]
/// is pushed onto the navigation stack above the parent route of this widget,
/// or when the sheet in a [_BaseCupertinoModalSheetRoute] above the parent
/// route is expanded from a minimized state via a swipe gesture.
///
/// See [_BaseCupertinoModalSheetRoute.delegatedTransition] and
/// [_BaseCupertinoModalSheetRoute.buildSheet] for more details.
class _OutgoingTransition extends StatefulWidget {
  const _OutgoingTransition({
    required this.endOffset,
    required this.animation,
    required this.child,
    this.overlayColor,
  });

  final Offset endOffset;
  final Animation<double> animation;
  final Widget child;
  final Color? overlayColor;

  @override
  State<_OutgoingTransition> createState() => _OutgoingTransitionState();
}

class _OutgoingTransitionState extends State<_OutgoingTransition> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = CurvedAnimation(
      parent: widget.animation,
      curve: _outgoingTransitionCurve,
    );
  }

  @override
  void didUpdateWidget(_OutgoingTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _animation = CurvedAnimation(
        parent: widget.animation,
        curve: _outgoingTransitionCurve,
      );
    }
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
        child: widget.overlayColor != null
            ? _ToningOverlay(
                animation: _animation,
                color: widget.overlayColor!,
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}

/// Controls the progress of the outgoing transition of a route
/// that is just below an incoming cupertino-style modal sheet route
/// in the navigation stack.
class _OutgoingTransitionController extends Animation<double>
    with ChangeNotifier {
  _OutgoingTransitionController({required this.route}) {
    route.secondaryAnimation!.addListener(_invalidateValue);
    _invalidateValue();
  }

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

/// Represents the previous route of a [_BaseCupertinoModalSheetRoute].
///
/// See [_BaseCupertinoModalSheetRoute._previousRouteEntry] for more details.
sealed class _PreviousRouteEntry {
  const _PreviousRouteEntry(this.value);

  final PageRoute<dynamic> value;

  _OutgoingTransitionController get outgoingTransitionController;
}

class _NonCupertinoModalEntry extends _PreviousRouteEntry {
  _NonCupertinoModalEntry(super.value) {
    _controllers[value]?.dispose();
    _controllers[value] = _OutgoingTransitionController(route: value);
  }

  /// Stores animation controllers for routes that are not of type
  /// [_BaseCupertinoModalSheetRoute].
  ///
  /// An [Expando] is used intentionally to tie the controller's lifecycle
  /// to that of the route. While this means the controllers may not be
  /// explicitly disposed, this is unlikely to cause any issues.
  static final _controllers = Expando<_OutgoingTransitionController>();

  @override
  _OutgoingTransitionController get outgoingTransitionController =>
      _controllers[value]!;
}

class _CupertinoModalEntry extends _PreviousRouteEntry {
  // ignore: use_super_parameters
  const _CupertinoModalEntry(_BaseCupertinoModalSheetRoute<dynamic> value)
      : super(value);

  @override
  _OutgoingTransitionController get outgoingTransitionController =>
      (value as _BaseCupertinoModalSheetRoute<dynamic>)
          ._outgoingTransitionController;
}

/// The base class for all Cupertino-style modal sheet routes.
abstract class _BaseCupertinoModalSheetRoute<T> extends PageRoute<T>
    with ModalSheetRouteMixin<T> {
  _BaseCupertinoModalSheetRoute({super.settings});

  /// {@template cupertino._BaseCupertinoModalSheetRoute.overlayColor}
  /// The color of the overlay applied to the outgoing transition.
  ///
  /// This color is applied to the sheet when another sheet is being pushed,
  /// especially useful when stacking multiple modal sheets in dark mode,
  /// so that the user can distinguish between the stacked sheets.
  ///
  /// If `null`, the overlay color is not applied at all.
  /// {@endtemplate}
  Color? get overlayColor;

  /// The animation controller that drives the outgoing transition
  /// of this route.
  ///
  /// See [_OutgoingTransition] for more details.
  late final _OutgoingTransitionController _outgoingTransitionController;

  /// Represents the route immediately below this one in the navigation stack.
  ///
  /// Used to communicate the sheet’s offset within this route
  /// to the [_OutgoingTransitionController] associated with the
  /// previous route. This is relevant when a sheet is expanded
  /// from a minimized state via a swipe gesture, triggering the
  /// outgoing transition of the previous route.
  ///
  /// If the previous route is another [_BaseCupertinoModalSheetRoute],
  /// this is a [_CupertinoModalEntry]. Otherwise, it's a
  /// [_NonCupertinoModalEntry], which manages its own
  /// [_OutgoingTransitionController]. This is necessary because
  /// there is no way to attach a controller to an existing
  /// non-[_BaseCupertinoModalSheetRoute] route.
  _PreviousRouteEntry? _previousRouteEntry;

  @override
  // TODO: Support custom viewport padding.
  EdgeInsets get viewportPadding => EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(navigator!.context).top + _sheetTopInset,
      );

  @override
  void install() {
    super.install();
    _outgoingTransitionController = _OutgoingTransitionController(route: this);
  }

  @override
  void dispose() {
    _outgoingTransitionController.dispose();
    super.dispose();
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    _previousRouteEntry = switch (previousRoute) {
      final _BaseCupertinoModalSheetRoute<dynamic> it =>
        _CupertinoModalEntry(it),
      final PageRoute<dynamic> it when !it.fullscreenDialog =>
        _NonCupertinoModalEntry(it),
      _ => null,
    };
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is _BaseCupertinoModalSheetRoute;
  }

  /// Creates a transition builder for the non cupertino-style modal route
  /// that is below this route.
  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final previousRouteEntry = _previousRouteEntry;
    if (previousRouteEntry is! _NonCupertinoModalEntry) {
      return null;
    }

    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      bool allowSnapshotting,
      Widget? child,
    ) {
      return _OutgoingTransition(
        animation: previousRouteEntry.outgoingTransitionController,
        endOffset: Offset(0, MediaQuery.viewPaddingOf(context).top),
        overlayColor: overlayColor,
        child: child!,
      );
    };
  }

  @nonVirtual
  @override
  Widget buildSheet(BuildContext context) {
    return _SheetModelObserver(
      onMetricsChanged: (metrics) {
        _previousRouteEntry?.outgoingTransitionController
            .applyNewIncomingSheetMetrics(metrics);
      },
      child: _OutgoingTransition(
        animation: _outgoingTransitionController,
        endOffset: const Offset(0, -1 * _sheetTopInset),
        overlayColor: overlayColor,
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
    this.overlayColor,
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

  /// {@macro cupertino._BaseCupertinoModalSheetRoute.overlayColor}
  final Color? overlayColor;

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
  Color? get overlayColor => _page.overlayColor;

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
    this.overlayColor,
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
  final Color? overlayColor;

  @override
  Widget _buildSheetInternal(BuildContext context) => builder(context);
}

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../foundation/sheet_controller.dart';
import '../internal/double_utils.dart';
import 'modal_sheet.dart';
import 'swipe_dismiss_sensitivity.dart';

const _minimizedViewportScale = 0.92;
const _cupertinoBarrierColor = Color(0x18000000);
const _cupertinoTransitionDuration = Duration(milliseconds: 300);
const _cupertinoTransitionCurve = Curves.fastEaseInToSlowEaseOut;
const _cupertinoStackedTransitionCurve = Curves.easeIn;

class _TransitionController extends ValueNotifier<double> {
  _TransitionController(super._value);

  @override
  set value(double newValue) {
    super.value = newValue.clamp(0, 1);
  }
}

/// Animates the corner radius of the [child] widget.
///
/// The associated render object ([_RenderCornerRadiusTransition]) observes
/// the [animation] and updates the [RenderClipRRect.borderRadius] property
/// when the animation value changes, which in turn updates the corner radius
/// of the [child] widget.
///
/// Although we can achieve the same effect by simply rebuilding a [ClipRRect]
/// when the [animation] value changes, this class is necessary because,
/// in our usecase, the [animation] may be updated during a layout phase
/// (e.g. when a [MediaQueryData.viewInsets] is changed), which is too late
/// to rebuild the widget tree.
class _CornerRadiusTransition extends SingleChildRenderObjectWidget {
  const _CornerRadiusTransition({
    required this.animation,
    required this.cornerRadius,
    required super.child,
  });

  final Animation<double> animation;
  final Tween<double> cornerRadius;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCornerRadiusTransition(
      animation: animation,
      cornerRadius: cornerRadius,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCornerRadiusTransition renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject
      ..animation = animation
      ..cornerRadius = cornerRadius;
  }
}

class _RenderCornerRadiusTransition extends RenderClipRRect {
  _RenderCornerRadiusTransition({
    required Animation<double> animation,
    required Tween<double> cornerRadius,
  })  : _animation = animation,
        _cornerRadius = cornerRadius,
        super(clipBehavior: Clip.antiAlias) {
    _animation.addListener(_invalidateBorderRadius);
  }

  Animation<double> _animation;
  // ignore: avoid_setters_without_getters
  set animation(Animation<double> value) {
    if (_animation != value) {
      _animation.removeListener(_invalidateBorderRadius);
      _animation = value..addListener(_invalidateBorderRadius);
      _invalidateBorderRadius();
    }
  }

  Tween<double> _cornerRadius;
  // ignore: avoid_setters_without_getters
  set cornerRadius(Tween<double> value) {
    if (_cornerRadius != value) {
      _cornerRadius = value;
      _invalidateBorderRadius();
    }
  }

  @override
  void dispose() {
    _animation.removeListener(_invalidateBorderRadius);
    super.dispose();
  }

  void _invalidateBorderRadius() {
    borderRadius = BorderRadius.circular(
      _cornerRadius.transform(_animation.value),
    );
  }
}

class _TransformTransition extends SingleChildRenderObjectWidget {
  const _TransformTransition({
    required this.animation,
    required this.offset,
    required this.scaleFactor,
    required super.child,
  });

  final Animation<double> animation;
  final Tween<double> offset;
  final Tween<double> scaleFactor;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTransformTransition(
      animation: animation,
      scaleTween: scaleFactor,
      translateTween: offset,
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
      ..scaleFactor = scaleFactor
      ..offset = offset;
  }
}

class _RenderTransformTransition extends RenderTransform {
  _RenderTransformTransition({
    required Animation<double> animation,
    required Tween<double> scaleTween,
    required Tween<double> translateTween,
  })  : _animation = animation,
        _scaleFactor = scaleTween,
        _offset = translateTween,
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

  Tween<double> _scaleFactor;
  // ignore: avoid_setters_without_getters
  set scaleFactor(Tween<double> value) {
    if (_scaleFactor != value) {
      _scaleFactor = value;
      _invalidateMatrix();
    }
  }

  Tween<double> _offset;
  // ignore: avoid_setters_without_getters
  set offset(Tween<double> value) {
    if (_offset != value) {
      _offset = value;
      _invalidateMatrix();
    }
  }

  @override
  void dispose() {
    _animation.removeListener(_invalidateMatrix);
    super.dispose();
  }

  void _invalidateMatrix() {
    final scaleFactor = _scaleFactor.transform(_animation.value);
    final offset = _offset.transform(_animation.value);
    transform = Matrix4.translationValues(0.0, offset, 0.0)
      ..scale(scaleFactor, scaleFactor, 1.0);
  }
}

/// A mapping of [PageRoute] to its associated [_TransitionController].
///
/// This is used to modify the transition progress of the previous route
/// from the current [_BaseCupertinoModalSheetRoute].
final _cupertinoTransitionControllerOf =
    <PageRoute<dynamic>, _TransitionController>{};

mixin _CupertinoStackedTransitionStateMixin<T extends StatefulWidget>
    on State<T> {
  late final _TransitionController _controller;
  PageRoute<dynamic>? _parentRoute;

  @override
  void initState() {
    super.initState();
    _controller = _TransitionController(0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentRoute = ModalRoute.of(context);

    assert(
      parentRoute is PageRoute<dynamic>,
      '$CupertinoModalStackedTransition can only be used with PageRoutes.',
    );
    assert(
      _cupertinoTransitionControllerOf[parentRoute] == null ||
          _cupertinoTransitionControllerOf[parentRoute] == _controller,
      'Only one $CupertinoModalStackedTransition can be used per route.',
    );

    _cupertinoTransitionControllerOf.remove(_parentRoute);
    _parentRoute = parentRoute! as PageRoute<dynamic>;
    _cupertinoTransitionControllerOf[_parentRoute!] = _controller;
  }

  @override
  void dispose() {
    _cupertinoTransitionControllerOf.remove(_parentRoute);
    _controller.dispose();
    super.dispose();
  }
}

class CupertinoModalStackedTransition extends StatefulWidget {
  const CupertinoModalStackedTransition({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<CupertinoModalStackedTransition> createState() =>
      _CupertinoModalStackedTransitionState();
}

class _CupertinoModalStackedTransitionState
    extends State<CupertinoModalStackedTransition>
    with
        _CupertinoStackedTransitionStateMixin<CupertinoModalStackedTransition> {
  @override
  Widget build(BuildContext context) {
    const extraMargin = 12.0;

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top + extraMargin,
      ),
      child: MediaQuery.removeViewPadding(
        context: context,
        removeTop: true,
        child: _TransformTransition(
          animation: Animation.fromValueListenable(_controller)
              .drive(CurveTween(curve: _cupertinoStackedTransitionCurve)),
          offset: Tween(begin: 0.0, end: -extraMargin),
          scaleFactor: Tween(begin: 1.0, end: _minimizedViewportScale),
          child: widget.child,
        ),
      ),
    );
  }
}

class CupertinoStackedTransition extends StatefulWidget {
  const CupertinoStackedTransition({
    super.key,
    this.cornerRadius,
    required this.child,
  });

  final Tween<double>? cornerRadius;
  final Widget child;

  @override
  State<CupertinoStackedTransition> createState() =>
      _CupertinoStackedTransitionState();
}

class _CupertinoStackedTransitionState extends State<CupertinoStackedTransition>
    with _CupertinoStackedTransitionStateMixin<CupertinoStackedTransition> {
  @override
  Widget build(BuildContext context) {
    final topViewPadding = MediaQuery.viewPaddingOf(context).top;
    final animation = Animation.fromValueListenable(_controller)
        .drive(CurveTween(curve: _cupertinoStackedTransitionCurve));

    final result = switch (widget.cornerRadius) {
      // Some optimizations to avoid unnecessary animations.
      null => widget.child,
      Tween(begin: null, end: null) => widget.child,
      Tween(begin: 0.0, end: 0.0) => widget.child,
      Tween(:final begin, :final end) when begin == end => ClipRRect(
          borderRadius: BorderRadius.circular(begin ?? 0.0),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        ),
      final cornerRadius => _CornerRadiusTransition(
          animation: animation,
          cornerRadius: cornerRadius,
          child: widget.child,
        ),
    };

    return _TransformTransition(
      animation: animation,
      offset: Tween(begin: 0.0, end: topViewPadding),
      scaleFactor: Tween(begin: 1.0, end: _minimizedViewportScale),
      child: result,
    );
  }
}

abstract class _BaseCupertinoModalSheetRoute<T> extends PageRoute<T>
    with ModalSheetRouteMixin<T> {
  _BaseCupertinoModalSheetRoute({
    super.settings,
    super.fullscreenDialog,
  });

  late final SheetController _sheetController;
  Route<dynamic>? _previousRoute;

  @override
  void install() {
    super.install();
    controller!.addListener(_invalidateTransitionProgress);
    _sheetController = SheetController()
      ..addListener(
        _invalidateTransitionProgress,
        fireImmediately: true,
      );
  }

  @override
  void dispose() {
    controller!.removeListener(_invalidateTransitionProgress);
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    _previousRoute = previousRoute as Route?;
  }

  void _invalidateTransitionProgress() {
    switch (controller!.status) {
      case AnimationStatus.forward:
      case AnimationStatus.completed:
        final metrics = _sheetController.metrics;
        if (metrics.hasDimensions) {
          _cupertinoTransitionControllerOf[_previousRoute]?.value = min(
            controller!.value,
            metrics.viewPixels.inverseLerp(
              // TODO: Make this configurable.
              metrics.viewportSize.height / 2,
              metrics.viewportSize.height,
            ),
          );
        }

      case AnimationStatus.reverse:
      case AnimationStatus.dismissed:
        _cupertinoTransitionControllerOf[_previousRoute]?.value = min(
          controller!.value,
          _cupertinoTransitionControllerOf[_previousRoute]!.value,
        );
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return CupertinoModalStackedTransition(
      child: SheetControllerScope(
        controller: _sheetController,
        child: super.buildPage(context, animation, secondaryAnimation),
      ),
    );
  }
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
    this.fullscreenDialog = false,
    this.barrierLabel,
    this.barrierColor = _cupertinoBarrierColor,
    this.transitionDuration = _cupertinoTransitionDuration,
    this.transitionCurve = _cupertinoTransitionCurve,
    this.swipeDismissSensitivity = const SwipeDismissSensitivity(),
    required this.child,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final bool fullscreenDialog;

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
      fullscreenDialog: fullscreenDialog,
    );
  }
}

class _PageBasedCupertinoModalSheetRoute<T>
    extends _BaseCupertinoModalSheetRoute<T> {
  _PageBasedCupertinoModalSheetRoute({
    required CupertinoModalSheetPage<T> page,
    super.fullscreenDialog,
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
  Widget buildContent(BuildContext context) => _page.child;
}

class CupertinoModalSheetRoute<T> extends _BaseCupertinoModalSheetRoute<T> {
  CupertinoModalSheetRoute({
    super.settings,
    super.fullscreenDialog,
    required this.builder,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.swipeDismissible = false,
    this.barrierLabel,
    this.barrierColor = _cupertinoBarrierColor,
    this.transitionDuration = _cupertinoTransitionDuration,
    this.transitionCurve = _cupertinoTransitionCurve,
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
  Widget buildContent(BuildContext context) {
    return builder(context);
  }
}

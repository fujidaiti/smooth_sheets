import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'controller.dart';
import 'internal/double_utils.dart';
import 'modal_sheet.dart';

const _minimizedViewportScale = 0.92;
const _cupertinoBarrierColor = Color(0x18000000);
const _cupertinoTransitionDuration = Duration(milliseconds: 300);
const _cupertinoTransitionCurve = Curves.fastEaseInToSlowEaseOut;
const _cupertinoStackedTransitionCurve = Curves.easeIn;

/// Similar to [ClipRRect], but allows to be updated during the layout phase.
class _CornerRadiusTransition extends SingleChildRenderObjectWidget {
  const _CornerRadiusTransition({
    required this.radius,
    required super.child,
  });

  final Animation<double> radius;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCornerRadiusTransition(radius: radius);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCornerRadiusTransition renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.radius = radius;
  }
}

class _RenderCornerRadiusTransition extends RenderClipRRect {
  _RenderCornerRadiusTransition({
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

/// Similar to [Transform], but allows to be updated during the layout phase.
class _TransformTransition extends SingleChildRenderObjectWidget {
  const _TransformTransition({
    required this.animation,
    required this.offsetTween,
    required this.scaleTween,
    required super.child,
  });

  final Animation<double> animation;
  final Tween<double> offsetTween;
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
    required Tween<double> offsetTween,
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

  Tween<double> _offsetTween;

  // ignore: avoid_setters_without_getters
  set offsetTween(Tween<double> value) {
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
    transform = Matrix4.translationValues(0.0, offset, 0.0)
      ..scale(scaleFactor, scaleFactor, 1.0);
  }
}

class _OutgoingSheetTransitionAnimation extends Animation<double>
    with ChangeNotifier {
  @override
  void addStatusListener(AnimationStatusListener listener) {
    // TODO: implement addStatusListener
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    // TODO: implement removeStatusListener
  }

  @override
  // TODO: implement status
  AnimationStatus get status => throw UnimplementedError();

  @override
  // TODO: implement value
  double get value => throw UnimplementedError();
}

class _InheritedOutgoingSheetTransitionAnimation extends InheritedWidget {
  const _InheritedOutgoingSheetTransitionAnimation({
    required this.animation,
    required super.child,
  });

  final _OutgoingSheetTransitionAnimation animation;

  @override
  bool updateShouldNotify(
    _InheritedOutgoingSheetTransitionAnimation oldWidget,
  ) =>
      animation != oldWidget.animation;
}

class _OutgoingSheetTransition extends StatefulWidget {
  const _OutgoingSheetTransition({
    required this.child,
  });

  final Widget child;

  @override
  State<_OutgoingSheetTransition> createState() =>
      _OutgoingSheetTransitionState();
}

class _OutgoingSheetTransitionState extends State<_OutgoingSheetTransition> {
  late _OutgoingSheetTransitionAnimation? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animation = context
        .dependOnInheritedWidgetOfExactType<
            _InheritedOutgoingSheetTransitionAnimation>()
        ?.animation;
  }

  @override
  Widget build(BuildContext context) {
    return _TransformTransition(
      animation: _animation,
      offsetTween: Tween<double>(begin: 0.0, end: 1.0),
      scaleTween: Tween<double>(begin: 0.0, end: 1.0),
      child: widget.child,
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
  PageRoute<dynamic>? _previousRoute;

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
    _previousRoute = previousRoute as PageRoute?;
  }

  void _invalidateTransitionProgress() {
    switch (controller!.status) {
      case AnimationStatus.forward:
      case AnimationStatus.completed:
        final metrics = _sheetController.metrics;
        if (metrics != null) {
          _cupertinoTransitionControllerOf[_previousRoute]?.value = min(
            controller!.value,
            metrics.offset.inverseLerp(
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
  // TODO: Support viewport padding.
  EdgeInsets get viewportPadding => EdgeInsets.zero;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget buildSheet(BuildContext context) => _page.child;
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
  // TODO: Support viewport padding.
  EdgeInsets get viewportPadding => EdgeInsets.zero;

  @override
  Widget buildSheet(BuildContext context) {
    return builder(context);
  }
}

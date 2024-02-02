import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/internal/double_utils.dart';
import 'package:smooth_sheets/src/modal/modal_sheet.dart';

const _minimizedViewportScale = 0.92;
const _cupertinoBarrierColor = Color(0x18000000);
const _cupertinoTransitionDuration = Duration(milliseconds: 300);
const _cupertinoTransitionCurve = Curves.fastEaseInToSlowEaseOut;
const _cupertinoStackedTransitionCurve = Curves.easeIn;

final _cupertinoTransitionControllerOf =
    <PageRoute<dynamic>, _TransitionController>{};

class _TransitionController extends ValueNotifier<double> {
  _TransitionController(super._value);

  @override
  set value(double newValue) {
    super.value = newValue.clamp(0, 1);
  }
}

class _ClipRRectTransition extends AnimatedWidget {
  const _ClipRRectTransition({
    required Animation<BorderRadius?> borderRadius,
    required this.child,
  }) : super(listenable: borderRadius);

  final Widget child;

  Animation<BorderRadius?> get borderRadius =>
      listenable as Animation<BorderRadius?>;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius.value ?? BorderRadius.zero,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _VerticalTranslateTransition extends MatrixTransition {
  const _VerticalTranslateTransition({
    required Animation<double> delta,
    required super.child,
  }) : super(
          animation: delta,
          alignment: Alignment.topCenter,
          onTransform: _onTransform,
        );

  static Matrix4 _onTransform(double value) =>
      Matrix4.translationValues(0, value, 0);
}

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
      child: _VerticalTranslateTransition(
        delta: Animation.fromValueListenable(_controller).drive(
          Tween(begin: 0.0, end: -extraMargin)
              .chain(CurveTween(curve: _cupertinoStackedTransitionCurve)),
        ),
        child: ScaleTransition(
          alignment: Alignment.topCenter,
          scale: Animation.fromValueListenable(_controller).drive(
            Tween(begin: 1.0, end: _minimizedViewportScale)
                .chain(CurveTween(curve: _cupertinoStackedTransitionCurve)),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class CupertinoStackedTransition extends StatefulWidget {
  const CupertinoStackedTransition({
    super.key,
    this.borderRadius,
    required this.child,
  });

  final Tween<BorderRadius?>? borderRadius;
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

    final child = switch (widget.borderRadius) {
      // Some optimizations to avoid unnecessary animations.
      null => widget.child,
      Tween(begin: null, end: null) => widget.child,
      Tween(begin: BorderRadius.zero, end: BorderRadius.zero) => widget.child,
      Tween(:final begin, :final end) when begin == end => ClipRRect(
          borderRadius: begin ?? BorderRadius.zero,
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        ),
      final borderRadius => _ClipRRectTransition(
          borderRadius: Animation.fromValueListenable(_controller).drive(
            borderRadius
                .chain(CurveTween(curve: _cupertinoStackedTransitionCurve)),
          ),
          child: widget.child,
        ),
    };

    return _VerticalTranslateTransition(
      delta: Animation.fromValueListenable(_controller).drive(
        Tween(begin: 0.0, end: topViewPadding)
            .chain(CurveTween(curve: _cupertinoStackedTransitionCurve)),
      ),
      child: ScaleTransition(
        alignment: Alignment.topCenter,
        scale: Animation.fromValueListenable(_controller).drive(
          Tween(begin: 1.0, end: _minimizedViewportScale)
              .chain(CurveTween(curve: _cupertinoStackedTransitionCurve)),
        ),
        child: child,
      ),
    );
  }
}

abstract class _BaseCupertinoModalSheetRoute<T> extends PageRoute<T>
    with ModalSheetRouteMixin<T> {
  _BaseCupertinoModalSheetRoute({super.settings});

  PageRoute<dynamic>? _previousRoute;

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    _previousRoute = previousRoute as PageRoute?;
  }

  @override
  void install() {
    super.install();
    controller!.addListener(_onTransitionAnimationTick);
    sheetController.addListener(_onSheetMetricsChanged);
  }

  @override
  void dispose() {
    sheetController.removeListener(_onSheetMetricsChanged);
    controller!.removeListener(_onTransitionAnimationTick);
    super.dispose();
  }

  void _onTransitionAnimationTick() {
    switch (controller!.status) {
      case AnimationStatus.forward:
      case AnimationStatus.completed:
        if (sheetController.metrics case final metrics?) {
          _cupertinoTransitionControllerOf[_previousRoute]?.value = min(
            controller!.value,
            inverseLerp(metrics.minPixels, metrics.maxPixels, metrics.pixels),
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

  void _onSheetMetricsChanged() {
    if (sheetController.metrics case final metrics?) {
      _cupertinoTransitionControllerOf[_previousRoute]?.value =
          inverseLerp(metrics.minPixels, metrics.maxPixels, metrics.pixels);
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return CupertinoModalStackedTransition(
      child: super.buildPage(context, animation, secondaryAnimation),
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
    this.enablePullToDismiss = true,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = _cupertinoBarrierColor,
    this.transitionDuration = _cupertinoTransitionDuration,
    this.transitionCurve = _cupertinoTransitionCurve,
    required this.child,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Color? barrierColor;

  final bool barrierDismissible;

  final String? barrierLabel;

  final bool enablePullToDismiss;

  final Duration transitionDuration;

  final Curve transitionCurve;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedCupertinoModalSheetRoute(page: this);
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
  bool get enablePullToDismiss => _page.enablePullToDismiss;

  @override
  Curve get transitionCurve => _page.transitionCurve;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget buildContent(BuildContext context) => _page.child;
}

class CupertinoModalSheetRoute<T> extends _BaseCupertinoModalSheetRoute<T> {
  CupertinoModalSheetRoute({
    required this.builder,
    this.enablePullToDismiss = true,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = _cupertinoBarrierColor,
    this.transitionDuration = _cupertinoTransitionDuration,
    this.transitionCurve = _cupertinoTransitionCurve,
  });

  final WidgetBuilder builder;

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final bool enablePullToDismiss;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final Curve transitionCurve;

  @override
  Widget buildContent(BuildContext context) {
    return builder(context);
  }
}

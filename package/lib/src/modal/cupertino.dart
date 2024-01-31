import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/modal/modal_sheet.dart';

const _minimizedViewportScale = 0.92;

final _transitionControllerOf = <PageRoute<dynamic>, ValueNotifier<double>>{};

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
  late final ValueNotifier<double> _controller;
  PageRoute<dynamic>? _parentRoute;

  @override
  void initState() {
    super.initState();
    _controller = ValueNotifier(0.0);
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
      _transitionControllerOf[parentRoute] == null ||
          _transitionControllerOf[parentRoute] == _controller,
      'Only one $CupertinoModalStackedTransition can be used per route.',
    );

    _transitionControllerOf.remove(_parentRoute);
    _parentRoute = parentRoute! as PageRoute<dynamic>;
    _transitionControllerOf[_parentRoute!] = _controller;
  }

  @override
  void dispose() {
    _transitionControllerOf.remove(_parentRoute);
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
        delta: Animation.fromValueListenable(_controller)
            .drive(Tween(begin: 0.0, end: -extraMargin)),
        child: ScaleTransition(
          alignment: Alignment.topCenter,
          scale: Animation.fromValueListenable(_controller).drive(
            Tween(begin: 1.0, end: _minimizedViewportScale),
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
    required this.child,
  });

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

    return _VerticalTranslateTransition(
      delta: Animation.fromValueListenable(_controller).drive(
        Tween(begin: 0.0, end: topViewPadding),
      ),
      child: ScaleTransition(
        alignment: Alignment.topCenter,
        scale: Animation.fromValueListenable(_controller).drive(
          Tween(begin: 1.0, end: _minimizedViewportScale),
        ),
        child: widget.child,
      ),
    );
  }
}

class CupertinoModalSheetRoute<T> extends PageRoute<T>
    with ModalSheetRouteMixin<T> {
  CupertinoModalSheetRoute({
    required this.builder,
    this.enablePullToDismiss = true,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = Colors.black38,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
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

  PageRoute<dynamic>? _previousRoute;

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    _previousRoute = previousRoute as PageRoute?;
  }

  @override
  void install() {
    super.install();
    controller!.addListener(onAnimationTick);
  }

  @override
  void dispose() {
    controller!.removeListener(onAnimationTick);
    super.dispose();
  }

  void onAnimationTick() {
    _transitionControllerOf[_previousRoute]?.value = controller!.value;
  }

  @override
  Widget buildContent(BuildContext context) {
    return builder(context);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return CupertinoModalStackedTransition(
      child: super.buildPage(context, animation, secondaryAnimation),
    );
  }
}

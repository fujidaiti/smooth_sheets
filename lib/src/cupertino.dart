import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'internal/double_utils.dart';
import 'modal_sheet.dart';
import 'model.dart';
import 'viewport.dart';

const _sheetTopInset = 12.0;
const _minimizedSheetScale = 0.92;
const _minimizedSheetCornerRadius = 12.0;
const _barrierColor = Color(0x18000000);
const _transitionDuration = Duration(milliseconds: 300);
const _outgoingTransitionCurve = Curves.easeIn;
const _incomingTransitionCurve = Curves.fastEaseInToSlowEaseOut;

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
class _OutgoingTransition extends StatelessWidget {
  const _OutgoingTransition({
    required this.animation,
    required this.endOffset,
    required this.child,
  });

  final Animation<double> animation;
  final Offset endOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: _outgoingTransitionCurve,
    );

    return _TransformTransition(
      animation: curvedAnimation,
      offsetTween: Tween(
        begin: Offset.zero,
        end: endOffset,
      ),
      scaleTween: Tween(begin: 1, end: _minimizedSheetScale),
      child: _ClipRRectTransition(
        radius: Tween(
          begin: 0.0,
          end: _minimizedSheetCornerRadius,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

class _OutgoingTransitionWithInheritedController extends StatefulWidget {
  const _OutgoingTransitionWithInheritedController({
    required this.endOffset,
    required this.child,
  });

  final Offset endOffset;
  final Widget child;

  @override
  State<_OutgoingTransitionWithInheritedController> createState() =>
      _OutgoingTransitionWithInheritedControllerState();
}

class _OutgoingTransitionWithInheritedControllerState
    extends State<_OutgoingTransitionWithInheritedController> {
  final _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // This maintains the child's state regardless of the existence of the
    // inherited controller.
    final keyedChild = KeyedSubtree(key: _childKey, child: widget.child);

    final controller = _InheritedOutgoingTransitionController.maybeOf(context);
    if (controller == null) {
      // There is no inherited animation,
      // so we don't need to perform any transition.
      return keyedChild;
    }

    return _OutgoingTransition(
      animation: controller,
      endOffset: widget.endOffset,
      child: keyedChild,
    );
  }
}

/// Controls the progress of the outgoing transition of a route
/// that is just below an incoming cupertino-style modal sheet route
/// in the navigation stack.
class _OutgoingTransitionController extends Animation<double>
    with ChangeNotifier {
  _OutgoingTransitionController({
    required this.incomingRoute,
  }) {
    incomingRoute.animation!.addListener(_invalidateValue);
    _invalidateValue();
  }

  final PageRoute<dynamic> incomingRoute;

  SheetModelView? get incomingSheet => _incomingSheet;
  SheetModelView? _incomingSheet;
  set incomingSheet(SheetModelView? value) {
    if (_incomingSheet != value) {
      _incomingSheet?.removeListener(_invalidateValue);
      _incomingSheet = value?..addListener(_invalidateValue);
      _invalidateValue();
    }
  }

  /// The progress of the outgoing transition.
  ///
  /// Must be between 0 and 1.
  @override
  double get value => _value!;
  double? _value;

  void _invalidateValue() {
    if (incomingRoute.offstage) {
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
    final incomingSheet = this.incomingSheet;
    if (incomingSheet == null || !incomingSheet.hasMetrics) {
      _value = incomingRoute.animation!.value;
    } else {
      _value = min(
        incomingRoute.animation!.value,
        incomingSheet.offset
            .inverseLerp(incomingSheet.minOffset, incomingSheet.maxOffset)
            .clamp(0, 1),
      );
    }

    if (_value != oldValue) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    incomingRoute.animation!.removeListener(_invalidateValue);
    incomingSheet?.removeListener(_invalidateValue);
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

class _InheritedOutgoingTransitionController extends InheritedWidget {
  const _InheritedOutgoingTransitionController({
    required this.controller,
    required super.child,
  });

  final _OutgoingTransitionController controller;

  @override
  bool updateShouldNotify(_InheritedOutgoingTransitionController oldWidget) =>
      controller != oldWidget.controller;

  static _OutgoingTransitionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
            _InheritedOutgoingTransitionController>()
        ?.controller;
  }
}

class _SheetModelObserver extends StatefulWidget {
  const _SheetModelObserver({
    required this.onModelChanged,
    required this.child,
  });

  final ValueSetter<SheetModelView> onModelChanged;
  final Widget child;

  @override
  State<_SheetModelObserver> createState() => _SheetModelObserverState();
}

class _SheetModelObserverState extends State<_SheetModelObserver> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onModelChanged(SheetViewportState.of(context)!.model);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

abstract class _BaseCupertinoModalSheetRoute<T> extends PageRoute<T>
    with ModalSheetRouteMixin<T> {
  _BaseCupertinoModalSheetRoute({super.settings});

  Route<dynamic>? _previousRoute;

  late final _OutgoingTransitionController
      _outgoingTransitionControllerForPreviousRoute;

  bool get _shouldControlPreviousRouteTransition {
    final previousRoute = _previousRoute;
    return previousRoute != null &&
        previousRoute is PageRoute &&
        !previousRoute.fullscreenDialog;
  }

  @override
  // TODO: Support custom viewport padding.
  EdgeInsets get viewportPadding => EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(navigator!.context).top + _sheetTopInset,
      );

  @override
  void install() {
    super.install();
    _outgoingTransitionControllerForPreviousRoute =
        _OutgoingTransitionController(incomingRoute: this);
  }

  @override
  void dispose() {
    _outgoingTransitionControllerForPreviousRoute.dispose();
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
    if (!_shouldControlPreviousRouteTransition) {
      return null;
    } else if (_previousRoute is _BaseCupertinoModalSheetRoute) {
      // As the previous route already has an _OutgoingTransition
      // in its subtree, all we need to do here is to expose the
      // _outgoingTransitionControllerForPreviousRoute to the
      // _OutgoingTransitionWithInheritedController in the subtree
      // of the previous route.
      return _buildInheritedController;
    } else {
      assert(_previousRoute is PageRoute);
      return _buildOutgoingTransitionForNonCupertinoModalSheetRoute;
    }
  }

  Widget? _buildOutgoingTransitionForNonCupertinoModalSheetRoute(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _OutgoingTransition(
      animation: _outgoingTransitionControllerForPreviousRoute,
      endOffset: Offset(0, MediaQuery.viewPaddingOf(context).top),
      child: child!,
    );
  }

  Widget? _buildInheritedController(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _InheritedOutgoingTransitionController(
      controller: _outgoingTransitionControllerForPreviousRoute,
      child: child!,
    );
  }

  @nonVirtual
  @override
  Widget buildSheet(BuildContext context) {
    return _SheetModelObserver(
      onModelChanged: (model) {
        // Obtain the SheetModel from the ancestor SheetViewport
        // and attach it to the controller.
        _outgoingTransitionControllerForPreviousRoute.incomingSheet = model;
      },
      // If a _BaseCupertinoModalSheetRoute is pushed on top of this route
      // in the navigation stack, the incoming route inserts an
      // _InheritedOutgoingTransitionController above the
      // _OutgoingTransitionWithInheritedController in the subtree of this
      // route via ModalRoute.delegatedTransition.
      //
      // Then, the _OutgoingTransitionWithInheritedController can read the
      // controller from the ancestor and use it to synchronize its own
      // animation with the incoming route's animation.
      child: _OutgoingTransitionWithInheritedController(
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

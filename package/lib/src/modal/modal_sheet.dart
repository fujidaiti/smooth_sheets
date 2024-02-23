import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';
import 'package:smooth_sheets/src/internal/double_utils.dart';
import 'package:smooth_sheets/src/internal/monodrag.dart';

const _minFlingVelocityToDismiss = 1.0;
const _minDragDistanceToDismiss = 100.0; // Logical pixels.
const _minReleasedPageForwardAnimationTime = 300; // Milliseconds.
const _releasedPageForwardAnimationCurve = Curves.fastLinearToSlowEaseIn;

class ModalSheetPage<T> extends Page<T> {
  const ModalSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.fullscreenDialog = false,
    this.barrierLabel,
    this.barrierColor = Colors.black54,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
    required this.child,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final bool fullscreenDialog;

  final Color? barrierColor;

  final bool barrierDismissible;

  final String? barrierLabel;

  final Duration transitionDuration;

  final Curve transitionCurve;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedModalSheetRoute(
      page: this,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

class _PageBasedModalSheetRoute<T> extends PageRoute<T>
    with ModalSheetRouteMixin<T> {
  _PageBasedModalSheetRoute({
    required ModalSheetPage<T> page,
    super.fullscreenDialog,
  }) : super(settings: page);

  ModalSheetPage<T> get _page => settings as ModalSheetPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  Curve get transitionCurve => _page.transitionCurve;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget buildContent(BuildContext context) => _page.child;
}

class ModalSheetRoute<T> extends PageRoute<T> with ModalSheetRouteMixin<T> {
  ModalSheetRoute({
    super.settings,
    super.fullscreenDialog,
    required this.builder,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = Colors.black54,
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

mixin ModalSheetRouteMixin<T> on ModalRoute<T> {
  Curve get transitionCurve;

  @override
  bool get opaque => false;

  @protected
  late final SheetController sheetController;

  /// Re-exposed [ModalRoute.controller] for use in [SheetDismissible].
  AnimationController get _transitionController => controller!;

  @override
  void install() {
    super.install();
    sheetController = SheetController();
  }

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  Widget buildContent(BuildContext context);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SheetControllerScope(
      controller: sheetController,
      child: buildContent(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitionTween = Tween(begin: const Offset(0, 1), end: Offset.zero);
    // In the middle of a dismiss gesture drag,
    // let the transition be linear to match finger motions.
    final curve =
        navigator!.userGestureInProgress ? Curves.linear : this.transitionCurve;
    return SlideTransition(
      position: animation.drive(
        transitionTween.chain(CurveTween(curve: curve)),
      ),
      child: child,
    );
  }
}

class SheetDismissible extends StatefulWidget {
  const SheetDismissible({
    super.key,
    this.onDismiss,
    required this.child,
  });

  final ValueGetter<bool>? onDismiss;
  final Widget child;

  @override
  State<SheetDismissible> createState() => _SheetDismissibleState();
}

class _SheetDismissibleState extends State<SheetDismissible> {
  late SheetController _sheetController;
  late ModalSheetRouteMixin<dynamic> _parentRoute;
  late final _PullToDismissGestureRecognizer _gestureRecognizer;
  ScrollMetrics? _lastReportedScrollMetrics;

  AnimationController get _transitionController =>
      _parentRoute._transitionController;

  @override
  void initState() {
    super.initState();
    _gestureRecognizer = _PullToDismissGestureRecognizer(target: this)
      ..onStart = _handleDragStart
      ..onUpdate = handleDragUpdate
      ..onEnd = handleDragEnd
      ..onCancel = handleDragCancel;
  }

  @override
  void dispose() {
    _gestureRecognizer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gestureRecognizer.gestureSettings =
        MediaQuery.maybeGestureSettingsOf(context);
    _sheetController = DefaultSheetController.of(context);

    assert(
      ModalRoute.of(context) is ModalSheetRouteMixin<dynamic>,
      '$SheetDismissible must be a descendant of a $ModalRoute '
      'that mixins $ModalSheetRouteMixin.',
    );

    _parentRoute = ModalRoute.of(context)! as ModalSheetRouteMixin<dynamic>;
  }

  double _draggedDistance = 0;

  void _handleDragStart(DragStartDetails details) {
    _draggedDistance = 0;
    _parentRoute.navigator!.didStartUserGesture();
  }

  void handleDragUpdate(DragUpdateDetails details) {
    _draggedDistance += details.delta.dy;
    final animationDelta = details.delta.dy / context.size!.height;
    _transitionController.value =
        (_parentRoute.animation!.value - animationDelta).clamp(0, 1);
  }

  Future<void> handleDragEnd(DragEndDetails details) async {
    final velocity = details.velocity.pixelsPerSecond.dy / context.size!.height;
    final shouldDismissCallback = widget.onDismiss ?? () => true;

    final bool willPop;
    if (velocity > 0) {
      // Flings down.
      willPop = velocity.abs() > _minFlingVelocityToDismiss &&
          !_transitionController.isAnimating &&
          shouldDismissCallback();
    } else if (velocity.isApprox(0)) {
      willPop = _draggedDistance.abs() > _minDragDistanceToDismiss &&
          !_transitionController.isAnimating &&
          shouldDismissCallback();
    } else {
      // Flings up.
      willPop = false;
    }

    if (willPop) {
      _parentRoute.navigator!.pop();
    } else if (!_transitionController.isCompleted) {
      // The route won't be popped, so animate the transition
      // back to the origin.
      final fraction = 1.0 - _transitionController.value;
      final animationTime = max(
        (_parentRoute.transitionDuration.inMilliseconds * fraction).floor(),
        _minReleasedPageForwardAnimationTime,
      );

      const completedAnimationValue = 1.0;
      unawaited(_transitionController.animateTo(
        completedAnimationValue,
        duration: Duration(milliseconds: animationTime),
        curve: _releasedPageForwardAnimationCurve,
      ));
    }

    if (_transitionController.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since the route's transition
      // depends on userGestureInProgress.
      late final AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        _parentRoute.navigator!.didStopUserGesture();
        _transitionController.removeStatusListener(animationStatusCallback);
      };
      _transitionController.addStatusListener(animationStatusCallback);
    } else {
      _parentRoute.navigator!.didStopUserGesture();
    }

    _draggedDistance = 0;
  }

  void handleDragCancel() {
    _draggedDistance = 0;
    if (_parentRoute.navigator!.userGestureInProgress) {
      _parentRoute.navigator!.didStopUserGesture();
    }
  }

  bool _handleScrollUpdate(ScrollNotification notification) {
    if (notification.depth == 0) {
      _lastReportedScrollMetrics = notification.metrics;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Instead of wrapping the child in a Listener, we stack it on top of
    // the child. This is because the child may be a scrollable widget,
    // and in that case the Listener will never win the gesture arena
    // if it is an ancestor of the scrollable child.
    // By stacking the Listener on top, it is able to get the gesture first
    // if certain conditions are met.
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollUpdate,
          child: widget.child,
        ),
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _gestureRecognizer.addPointer,
        ),
      ],
    );
  }
}

/// A special [VerticalDragGestureRecognizer] that only recognizes
/// drag down gestures that start on the sheet.
class _PullToDismissGestureRecognizer extends VerticalDragGestureRecognizer {
  _PullToDismissGestureRecognizer({required this.target})
      : super(debugOwner: target);

  final _SheetDismissibleState target;

  @override
  void addPointer(PointerDownEvent event) {
    if (_isPointerOnSheet(event.localPosition)) {
      super.addPointer(event);
    }
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    // We are only interested in vertical downward gestures.
    return globalDistanceMoved > 0 &&
        _shouldStartDismissGesture() &&
        super.hasSufficientGlobalDistanceToAccept(
            pointerDeviceKind, deviceTouchSlop);
  }

  bool _isPointerOnSheet(Offset pointer) {
    final viewport = target.context.size!;
    final localY = viewport.height - pointer.dy;
    final currentExtent = target._sheetController.metrics?.pixels;
    return currentExtent != null && localY <= currentExtent;
  }

  bool _shouldStartDismissGesture() {
    if (target._transitionController.isAnimating) {
      return false;
    }

    final contentScrollableDistance =
        target._lastReportedScrollMetrics?.extentBefore;
    final currentExtent = target._sheetController.metrics?.pixels;
    final threshold = target._sheetController.metrics?.minPixels;

    return (contentScrollableDistance == null ||
            contentScrollableDistance.isApprox(0)) &&
        currentExtent != null &&
        threshold != null &&
        currentExtent <= threshold;
  }
}

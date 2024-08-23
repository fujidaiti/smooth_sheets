import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../foundation/sheet_drag.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../internal/float_comp.dart';
import 'swipe_dismiss_sensitivity.dart';

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
    this.swipeDismissible = false,
    this.fullscreenDialog = false,
    this.barrierLabel,
    this.barrierColor = Colors.black54,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
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

  final String? barrierLabel;

  final bool swipeDismissible;

  final Duration transitionDuration;

  final Curve transitionCurve;

  final SwipeDismissSensitivity swipeDismissSensitivity;

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

class ModalSheetRoute<T> extends PageRoute<T> with ModalSheetRouteMixin<T> {
  ModalSheetRoute({
    super.settings,
    super.fullscreenDialog,
    required this.builder,
    this.maintainState = true,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = Colors.black54,
    this.swipeDismissible = false,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
    this.swipeDismissSensitivity = const SwipeDismissSensitivity(),
  });

  final WidgetBuilder builder;

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final bool swipeDismissible;

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

mixin ModalSheetRouteMixin<T> on ModalRoute<T> {
  bool get swipeDismissible;
  Curve get transitionCurve;
  SwipeDismissSensitivity get swipeDismissSensitivity;

  @override
  bool get opaque => false;

  /// Lazily initialized in case `swipeDismissible` is set to false.
  late final _swipeDismissibleController = _SwipeDismissibleController(
    route: this,
    transitionController: controller!,
    sensitivity: swipeDismissSensitivity,
  );

  Widget buildContent(BuildContext context);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return switch (swipeDismissible) {
      true => TamperSheetGesture(
          tamperer: _swipeDismissibleController,
          child: buildContent(context),
        ),
      false => buildContent(context),
    };
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

  @override
  Widget buildModalBarrier() {
    void onDismiss() {
      if (animation!.isCompleted && !navigator!.userGestureInProgress) {
        navigator?.maybePop();
      }
    }

    final barrierColor = this.barrierColor;
    if (barrierColor != null && barrierColor.alpha != 0 && !offstage) {
      assert(barrierColor != barrierColor.withOpacity(0.0));
      return AnimatedModalBarrier(
        onDismiss: onDismiss,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
        color: animation!.drive(
          ColorTween(
            begin: barrierColor.withOpacity(0.0),
            end: barrierColor,
          ).chain(CurveTween(curve: barrierCurve)),
        ),
      );
    } else {
      return ModalBarrier(
        onDismiss: onDismiss,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      );
    }
  }
}

class _SwipeDismissibleController with SheetGestureTamperer {
  _SwipeDismissibleController({
    required this.route,
    required this.transitionController,
    required this.sensitivity,
  });

  final ModalRoute<dynamic> route;
  final AnimationController transitionController;
  final SwipeDismissSensitivity sensitivity;

  BuildContext get _context => route.subtreeContext!;

  bool get _isUserGestureInProgress => route.navigator!.userGestureInProgress;

  set _isUserGestureInProgress(bool inProgress) {
    if (inProgress && !_isUserGestureInProgress) {
      route.navigator!.didStartUserGesture();
    } else if (!inProgress && _isUserGestureInProgress) {
      route.navigator!.didStopUserGesture();
    }
  }

  @override
  SheetDragUpdateDetails tamperWithDragUpdate(
    SheetDragUpdateDetails details,
    Offset minPotentialDeltaConsumption,
  ) {
    final dragDelta = switch (details.axisDirection) {
      VerticalDirection.up => details.delta.dy,
      // We flip the sign of the delta here because all of the following
      // logic assumes that the axis direction is upwards.
      VerticalDirection.down => -1 * details.delta.dy,
    };

    final minPDC = minPotentialDeltaConsumption.dy;
    assert(details.delta.dy * minPDC >= 0);
    final double effectiveDragDelta;
    if (!transitionController.isCompleted) {
      // Dominantly use the full pixels if it is in the middle of a transition.
      effectiveDragDelta = dragDelta;
    } else if (dragDelta < 0 &&
        FloatComp.distance(MediaQuery.devicePixelRatioOf(_context))
            .isNotApprox(dragDelta, minPDC) &&
        MediaQuery.viewInsetsOf(_context).bottom == 0) {
      // If the drag is downwards and the sheet may not consume the full pixels,
      // then use the remaining pixels as the effective drag delta.
      effectiveDragDelta = switch (details.axisDirection) {
        VerticalDirection.up => dragDelta - minPDC,
        VerticalDirection.down => dragDelta + minPDC,
      };
      assert(dragDelta * effectiveDragDelta >= 0);
    } else {
      // Otherwise, the drag delta doesn't change the transition progress.
      return super.tamperWithDragUpdate(details, minPotentialDeltaConsumption);
    }

    final viewport = _context.size!.height;
    final visibleViewport = viewport * transitionController.value;
    assert(0 <= visibleViewport && visibleViewport <= viewport);
    final newVisibleViewport =
        (visibleViewport + effectiveDragDelta).clamp(0, viewport);

    assert(viewport > 0);
    final transitionProgress = newVisibleViewport / viewport;
    assert(0 <= transitionProgress && transitionProgress <= 1);
    _isUserGestureInProgress = transitionProgress < 1;
    transitionController.value = transitionProgress;

    final viewportDelta = newVisibleViewport - visibleViewport;
    final unconsumedDragDelta = switch (details.axisDirection) {
      VerticalDirection.up => dragDelta - viewportDelta,
      VerticalDirection.down => viewportDelta - dragDelta,
    };

    return super.tamperWithDragUpdate(
      details.copyWith(deltaY: unconsumedDragDelta),
      minPotentialDeltaConsumption,
    );
  }

  @override
  SheetDragEndDetails tamperWithDragEnd(SheetDragEndDetails details) {
    final wasHandled = _handleDragEnd(
      velocity: details.velocity,
      axisDirection: details.axisDirection,
    );
    return wasHandled
        ? super.tamperWithDragEnd(details.copyWith(velocityX: 0, velocityY: 0))
        : super.tamperWithDragEnd(details);
  }

  @override
  void onDragCancel(SheetDragCancelDetails details) {
    super.onDragCancel(details);
    _handleDragEnd(
      axisDirection: details.axisDirection,
      velocity: Velocity.zero,
    );
  }

  bool _handleDragEnd({
    required Velocity velocity,
    required VerticalDirection axisDirection,
  }) {
    if (!_isUserGestureInProgress || transitionController.isAnimating) {
      return false;
    }

    final viewportHeight = _context.size!.height;
    final draggedDistance = viewportHeight * (1 - transitionController.value);

    final effectiveVelocity = switch (axisDirection) {
      VerticalDirection.up => velocity.pixelsPerSecond.dy / viewportHeight,
      VerticalDirection.down =>
        -1 * velocity.pixelsPerSecond.dy / viewportHeight,
    };

    final bool invokePop;
    if (MediaQuery.viewInsetsOf(_context).bottom > 0) {
      // The on-screen keyboard is open.
      invokePop = false;
    } else if (effectiveVelocity < 0) {
      // Flings down.
      invokePop = effectiveVelocity.abs() > sensitivity.minFlingVelocity;
    } else if (FloatComp.velocity(MediaQuery.devicePixelRatioOf(_context))
        .isApprox(effectiveVelocity, 0)) {
      assert(draggedDistance >= 0);
      // Dragged down enough to dismiss.
      invokePop = draggedDistance > sensitivity.minDragDistance;
    } else {
      // Flings up.
      invokePop = false;
    }

    final didPop = invokePop && route.popDisposition == RoutePopDisposition.pop;

    if (didPop) {
      route.navigator!.pop();
    } else if (!transitionController.isCompleted) {
      // The route won't be popped, so animate the transition
      // back to the origin.
      final fraction = 1.0 - transitionController.value;
      final animationTime = max(
        (route.transitionDuration.inMilliseconds * fraction).floor(),
        _minReleasedPageForwardAnimationTime,
      );

      const completedAnimationValue = 1.0;
      unawaited(transitionController.animateTo(
        completedAnimationValue,
        duration: Duration(milliseconds: animationTime),
        curve: _releasedPageForwardAnimationCurve,
      ));
    }

    if (transitionController.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since the route's transition
      // depends on userGestureInProgress.
      late final AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (_) {
        _isUserGestureInProgress = false;
        transitionController.removeStatusListener(animationStatusCallback);
      };
      transitionController.addStatusListener(animationStatusCallback);
    } else {
      // Otherwise, reset the userGestureInProgress state immediately.
      _isUserGestureInProgress = false;
    }

    if (invokePop) {
      route.onPopInvoked(didPop);
    }

    return true;
  }
}

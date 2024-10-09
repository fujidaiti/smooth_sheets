import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
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

  /// The curve used for the transition animation.
  ///
  /// In the middle of a dismiss gesture drag,
  /// this returns [Curves.linear] to match the finger motion.
  @nonVirtual
  @visibleForTesting
  Curve get effectiveCurve => (navigator?.userGestureInProgress ?? false)
      ? Curves.linear
      : transitionCurve;

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
      true => SheetGestureProxy(
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
    return SlideTransition(
      position: animation.drive(
        transitionTween.chain(CurveTween(curve: effectiveCurve)),
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

class _SwipeDismissibleController with SheetGestureProxyMixin {
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
  SheetDragUpdateDetails onDragUpdate(
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
      return super.onDragUpdate(details, minPotentialDeltaConsumption);
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

    return super.onDragUpdate(
      details.copyWith(deltaY: unconsumedDragDelta),
      minPotentialDeltaConsumption,
    );
  }

  @override
  SheetDragEndDetails onDragEnd(SheetDragEndDetails details) {
    final wasHandled = _handleDragEnd(
      velocity: details.velocity,
      axisDirection: details.axisDirection,
    );
    return wasHandled
        ? super.onDragEnd(details.copyWith(velocityX: 0, velocityY: 0))
        : super.onDragEnd(details);
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
      invokePop = effectiveVelocity.abs() > sensitivity.minFlingVelocityRatio;
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

    // Reset the transition animation curve back to the default from linear
    // indirectly, by resetting the userGestureInProgress flag.
    // It is "indirect" because ModalSheetRouteMixin.effectiveCurve returns
    // the linear curve when the userGestureInProgress flag is set to true.
    //
    // If the transition animation has not settled at either the start or end,
    // delay resetting the userGestureInProgress until the animation completes
    // to ensure the effectiveCurve remains linear during the animation,
    // matching the user's swipe motion. This is important to prevent the sheet
    // from jerking when the user swipes it down.
    // See https://github.com/fujidaiti/smooth_sheets/issues/250.
    //
    // Note: We cannot use AnimationController.isAnimating here to determine if
    // the transition animation is running, because, in Navigator 2.0,
    // the pop animation may not have started at this point even if
    // Navigator.pop() is called to pop the modal route.
    //
    // The following sequence of events illustrates why:
    // 1. Calling Navigator.pop() updates the internal page stack, triggering
    //    a rebuild of the Navigator. Note that the transition animation
    //    does not start here, so AnimationController.isAnimating returns false.
    // 2. The Navigator rebuilds with the new page stack.
    // 3. The modal route is removed from the Navigator's subtree.
    // 4. Route.didPop() is called, initiating the pop transition animation
    //    by calling AnimationController.reverse().
    if (transitionController.isCompleted || transitionController.isDismissed) {
      _isUserGestureInProgress = false;
    } else {
      late final AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _isUserGestureInProgress = false;
          transitionController.removeStatusListener(animationStatusCallback);
        }
      };
      transitionController.addStatusListener(animationStatusCallback);
    }

    if (invokePop) {
      route.onPopInvoked(didPop);
    }

    return true;
  }
}

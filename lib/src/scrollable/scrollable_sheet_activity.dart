import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_activity.dart';
import '../foundation/sheet_drag.dart';
import '../foundation/sheet_status.dart';
import '../internal/float_comp.dart';
import 'scrollable_sheet.dart';
import 'scrollable_sheet_extent.dart';
import 'sheet_content_scroll_activity.dart';
import 'sheet_content_scroll_position.dart';

/// A [SheetActivity] that is associated with a [SheetContentScrollPosition].
///
/// This activity is responsible for both scrolling a scrollable content
/// in the sheet and dragging the sheet itself.
///
/// [shouldIgnorePointer] and [SheetContentScrollPosition.shouldIgnorePointer]
/// of the associated scroll position may be synchronized, but not always.
/// For example, [BallisticScrollDrivenSheetActivity]'s [shouldIgnorePointer]
/// is always `false` while the associated scroll position sets it to `true`
/// in most cases to ensure that the pointer events, which potentially
/// interrupt the ballistic scroll animation, are not stolen by clickable
/// items in the scroll view.
@internal
abstract class ScrollableSheetActivity
    extends SheetActivity<ScrollableSheetExtent> {
  ScrollableSheetActivity(SheetContentScrollPosition scrollPosition)
      : _scrollPosition = scrollPosition;

  SheetContentScrollPosition? _scrollPosition;
  SheetContentScrollPosition get scrollPosition {
    assert(debugAssertNotDisposed());
    return _scrollPosition!;
  }

  @mustCallSuper
  void updateScrollPosition(SheetContentScrollPosition scrollPosition) {
    _scrollPosition = scrollPosition;
  }

  @override
  void dispose() {
    _scrollPosition = null;
    super.dispose();
  }

  double _applyPhysicsToOffset(double offset) {
    return owner.physics.applyPhysicsToOffset(offset, owner.metrics);
  }

  double _applyScrollOffset(double offset) {
    final cmp = FloatComp.distance(owner.context.devicePixelRatio);
    if (cmp.isApprox(offset, 0)) return 0;

    final position = scrollPosition;
    final maxPixels = owner.metrics.maxPixels;
    final oldPixels = owner.metrics.pixels;
    final oldScrollPixels = position.pixels;
    final minScrollPixels = position.minScrollExtent;
    final maxScrollPixels = position.maxScrollExtent;
    var newPixels = oldPixels;
    var delta = offset;

    if (offset > 0) {
      // If the sheet is not at top, drag it up as much as possible
      // until it reaches at 'maxPixels'.
      if (cmp.isLessThanOrApprox(newPixels, maxPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta, delta));
        newPixels = min(newPixels + physicsAppliedDelta, maxPixels);
        delta -= newPixels - oldPixels;
      }
      // If the sheet is at the top, scroll the content up as much as possible.
      if (cmp.isGreaterThanOrApprox(newPixels, maxPixels) &&
          position.extentAfter > 0) {
        position.correctPixels(min(position.pixels + delta, maxScrollPixels));
        delta -= position.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled up anymore, drag the sheet up
      // to make a bouncing effect (if needed).
      if (cmp.isApprox(position.pixels, maxScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta, delta));
        newPixels += physicsAppliedDelta;
        delta -= physicsAppliedDelta;
      }
    } else if (offset < 0) {
      // If the sheet is beyond 'maxPixels', drag it down as much
      // as possible until it reaches at 'maxPixels'.
      if (cmp.isGreaterThanOrApprox(newPixels, maxPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta.abs(), delta.abs()));
        newPixels = max(newPixels + physicsAppliedDelta, maxPixels);
        delta -= newPixels - oldPixels;
      }
      // If the sheet is not beyond 'maxPixels', scroll the content down
      // as much as possible.
      if (cmp.isLessThanOrApprox(newPixels, maxPixels) &&
          position.extentBefore > 0) {
        position.correctPixels(max(position.pixels + delta, minScrollPixels));
        delta -= position.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled down anymore, drag the sheet down
      // to make a shrinking effect (if needed).
      if (cmp.isApprox(position.pixels, minScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta.abs(), delta.abs()));
        newPixels += physicsAppliedDelta;
        delta -= physicsAppliedDelta;
      }
    }

    if (position.pixels != oldScrollPixels) {
      position
        ..notifyListeners()
        ..didUpdateScrollPositionBy(position.pixels - oldScrollPixels);
    }

    owner.setPixels(newPixels);

    final overflow = owner.physics.computeOverflow(delta, owner.metrics);
    if (overflow.abs() > 0) {
      position.didOverscrollBy(overflow);
      return overflow;
    }

    return 0;
  }
}

/// A [SheetActivity] that either scrolls a scrollable content of
/// a [ScrollableSheet] or drags the sheet itself as the user drags
/// their finger across the screen.
///
/// The [scrollPosition], which is associated with the scrollable content,
/// must have a [SheetContentDragScrollActivity] as its activity throughout
/// the lifetime of this activity.
@internal
class DragScrollDrivenSheetActivity extends ScrollableSheetActivity
    with UserControlledSheetActivityMixin
    implements SheetDragControllerTarget {
  DragScrollDrivenSheetActivity(super.scrollPosition)
      : assert(() {
          if (scrollPosition.axisDirection != AxisDirection.down &&
              scrollPosition.axisDirection != AxisDirection.up) {
            throw FlutterError(
              'The axis direction of the scroll position associated with a '
              '$ScrollableSheet must be either $AxisDirection.down '
              'or $AxisDirection.up, but the provided scroll position has an '
              'axis direction of ${scrollPosition.axisDirection}.',
            );
          }
          return true;
        }());

  @override
  VerticalDirection get dragAxisDirection {
    if (scrollPosition.axisDirection == AxisDirection.up) {
      return VerticalDirection.up;
    } else {
      assert(scrollPosition.axisDirection == AxisDirection.down);
      return VerticalDirection.down;
    }
  }

  @override
  Offset computeMinPotentialDeltaConsumption(Offset delta) {
    final metrics = owner.metrics;

    switch (delta.dy) {
      case < 0:
        final draggablePixels = scrollPosition.extentAfter +
            max(0.0, metrics.maxPixels - metrics.pixels);
        assert(draggablePixels >= 0);
        return Offset(delta.dx, max(-1 * draggablePixels, delta.dy));

      case > 0:
        final draggablePixels = scrollPosition.extentBefore +
            max(0.0, metrics.pixels - metrics.minPixels);
        assert(draggablePixels >= 0);
        return Offset(delta.dx, min(draggablePixels, delta.dy));

      case _:
        return delta;
    }
  }

  @override
  void onDragUpdate(SheetDragUpdateDetails details) {
    scrollPosition.userScrollDirection = details.deltaY > 0.0
        ? ScrollDirection.forward
        : ScrollDirection.reverse;
    final oldPixels = owner.metrics.pixels;
    final overflow = _applyScrollOffset(-1 * details.deltaY);
    if (owner.metrics.pixels != oldPixels) {
      owner.didDragUpdateMetrics(details);
    }
    if (overflow > 0) {
      owner.didOverflowBy(overflow);
    }
  }

  @override
  void onDragEnd(SheetDragEndDetails details) {
    owner
      ..didDragEnd(details)
      ..goBallisticWithScrollPosition(
        velocity: -1 * details.velocityY,
        scrollPosition: scrollPosition,
      );
  }

  @override
  void onDragCancel(SheetDragCancelDetails details) {
    owner
      ..didDragCancel()
      ..goBallisticWithScrollPosition(
        velocity: 0,
        scrollPosition: scrollPosition,
      );
  }
}

/// A [SheetActivity] that animates either a scrollable content of
/// a [ScrollableSheet] or the sheet itself based on a physics simulation.
///
/// The [scrollPosition], which is associated with the scrollable content,
/// must have a [SheetContentBallisticScrollActivity] as its activity throughout
/// the lifetime of this activity.
@internal
class BallisticScrollDrivenSheetActivity extends ScrollableSheetActivity
    with ControlledSheetActivityMixin {
  BallisticScrollDrivenSheetActivity(
    super.scrollPosition, {
    required this.simulation,
    required double initialPixels,
  }) : _oldPixels = initialPixels;

  final Simulation simulation;

  double _oldPixels;

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(vsync: owner.context.vsync);
  }

  @override
  TickerFuture onAnimationStart() {
    return controller.animateWith(simulation);
  }

  @override
  void onAnimationTick() {
    final cmp = FloatComp.distance(owner.context.devicePixelRatio);
    final delta = controller.value - _oldPixels;
    _oldPixels = controller.value;
    final overflow = _applyScrollOffset(delta);
    if (owner.metrics.pixels != _oldPixels) {
      owner.didUpdateMetrics();
    }
    if (cmp.isNotApprox(overflow, 0)) {
      owner
        ..didOverflowBy(overflow)
        ..goIdleWithScrollPosition();
      return;
    }

    final scrollExtentBefore = scrollPosition.extentBefore;
    final scrollExtentAfter = scrollPosition.extentAfter;
    final shouldInterruptBallisticScroll =
        ((cmp.isApprox(scrollExtentBefore, 0) && velocity < 0) ||
                (cmp.isApprox(scrollExtentAfter, 0) && velocity > 0)) &&
            owner.physics
                .shouldInterruptBallisticScroll(velocity, owner.metrics);

    if (shouldInterruptBallisticScroll) {
      _end();
    }
  }

  @override
  void onAnimationEnd() {
    if (mounted) {
      _end();
    }
  }

  void _end() {
    owner.goBallisticWithScrollPosition(
      velocity: 0,
      scrollPosition: scrollPosition,
    );
  }
}

/// A [SheetActivity] that does nothing but can be released to resume
/// normal idle behavior.
///
/// This is used while the user is touching the scrollable content but before
/// the touch has become a [Drag]. The [scrollPosition], which is associated
/// with the scrollable content must have a [SheetContentHoldScrollActivity]
/// as its activity throughout the lifetime of this activity.
class HoldScrollDrivenSheetActivity extends ScrollableSheetActivity
    implements ScrollHoldController {
  HoldScrollDrivenSheetActivity(
    super.scrollPosition, {
    required this.heldPreviousVelocity,
    required this.onHoldCanceled,
  });

  final double heldPreviousVelocity;
  final VoidCallback? onHoldCanceled;

  @override
  SheetStatus get status => SheetStatus.dragging;

  @override
  void cancel() {
    owner.goBallisticWithScrollPosition(
      velocity: 0,
      scrollPosition: scrollPosition,
    );
  }

  @override
  void dispose() {
    onHoldCanceled?.call();
    super.dispose();
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'scrollable_sheet_activity.dart';
import 'sheet_content_scroll_position.dart';

/// A [ScrollActivity] for the [SheetContentScrollPosition] that is associated
/// with a [DragScrollDrivenSheetActivity].
///
/// This activity is like a placeholder, meaning it doesn't actually modify the
/// scroll position and the actual scrolling is done by the associated
/// [DragScrollDrivenSheetActivity].
@internal
class SheetContentDragScrollActivity extends ScrollActivity {
  SheetContentDragScrollActivity({
    required ScrollActivityDelegate delegate,
    required this.getLastDragDetails,
    required this.getPointerDeviceKind,
  }) : super(delegate);

  final ValueGetter<dynamic> getLastDragDetails;
  final ValueGetter<PointerDeviceKind?> getPointerDeviceKind;

  @override
  void dispatchScrollStartNotification(
    ScrollMetrics metrics,
    BuildContext? context,
  ) {
    final lastDetails = getLastDragDetails();
    if (lastDetails is DragStartDetails) {
      ScrollStartNotification(
        metrics: metrics,
        context: context,
        dragDetails: lastDetails,
      ).dispatch(context);
    } else {
      assert(() {
        throw FlutterError(
          'Expected to have a $DragStartDetails, but got $lastDetails.',
        );
      }());
    }
  }

  @override
  void dispatchScrollUpdateNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double scrollDelta,
  ) {
    final lastDetails = getLastDragDetails();
    if (lastDetails is DragUpdateDetails) {
      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: scrollDelta,
        dragDetails: lastDetails,
      ).dispatch(context);
    } else {
      assert(() {
        throw FlutterError(
          'Expected to have a $DragUpdateDetails, but got $lastDetails.',
        );
      }());
    }
  }

  @override
  void dispatchOverscrollNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double overscroll,
  ) {
    final lastDetails = getLastDragDetails();
    if (lastDetails is DragUpdateDetails) {
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: overscroll,
        dragDetails: lastDetails,
      ).dispatch(context);
    } else {
      assert(() {
        throw FlutterError(
          'Expected to have a $DragUpdateDetails, but got $lastDetails.',
        );
      }());
    }
  }

  @override
  void dispatchScrollEndNotification(
    ScrollMetrics metrics,
    BuildContext context,
  ) {
    final lastDetails = getLastDragDetails();
    if (lastDetails is DragEndDetails?) {
      ScrollEndNotification(
        metrics: metrics,
        context: context,
        dragDetails: lastDetails,
      ).dispatch(context);
    } else {
      assert(() {
        throw FlutterError(
          'Expected to have a $DragEndDetails?, but got $lastDetails.',
        );
      }());
    }
  }

  @override
  bool get shouldIgnorePointer =>
      getPointerDeviceKind() != PointerDeviceKind.trackpad;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => 0.0;
}

/// A [ScrollActivity] for the [SheetContentScrollPosition] that is associated
/// with a [BallisticScrollDrivenSheetActivity].
///
/// This activity is like a placeholder, meaning it doesn't actually modify the
/// scroll position and the actual scrolling is done by the associated
/// [BallisticScrollDrivenSheetActivity].
@internal
class SheetContentBallisticScrollActivity extends ScrollActivity {
  SheetContentBallisticScrollActivity({
    required ScrollActivityDelegate delegate,
    required this.getVelocity,
    required this.shouldIgnorePointer,
  }) : super(delegate);

  @override
  final bool shouldIgnorePointer;
  final ValueGetter<double> getVelocity;

  @override
  void resetActivity() {
    delegate.goBallistic(velocity);
  }

  @override
  void applyNewDimensions() {
    delegate.goBallistic(velocity);
  }

  @override
  void dispatchOverscrollNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double overscroll,
  ) {
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: overscroll,
      velocity: velocity,
    ).dispatch(context);
  }

  @override
  bool get isScrolling => true;

  @override
  double get velocity => getVelocity();
}

/// A [ScrollActivity] for the [SheetContentScrollPosition] that is associated
/// with a [HoldScrollDrivenSheetActivity].
///
/// This activity is like a placeholder, meaning it doesn't actually modify the
/// scroll position and the actual scrolling is done by the associated
/// [HoldScrollDrivenSheetActivity].
class SheetContentHoldScrollActivity extends ScrollActivity {
  SheetContentHoldScrollActivity({
    required ScrollActivityDelegate delegate,
  }) : super(delegate);

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0.0;
}

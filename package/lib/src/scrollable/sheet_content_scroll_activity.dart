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
    final dynamic lastDetails = getLastDragDetails();
    assert(lastDetails is DragStartDetails);
    ScrollStartNotification(
      metrics: metrics,
      context: context,
      dragDetails: lastDetails as DragStartDetails,
    ).dispatch(context);
  }

  @override
  void dispatchScrollUpdateNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double scrollDelta,
  ) {
    final dynamic lastDetails = getLastDragDetails();
    assert(lastDetails is DragUpdateDetails);
    ScrollUpdateNotification(
      metrics: metrics,
      context: context,
      scrollDelta: scrollDelta,
      dragDetails: lastDetails as DragUpdateDetails,
    ).dispatch(context);
  }

  @override
  void dispatchOverscrollNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double overscroll,
  ) {
    final dynamic lastDetails = getLastDragDetails();
    assert(lastDetails is DragUpdateDetails);
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: overscroll,
      dragDetails: lastDetails as DragUpdateDetails,
    ).dispatch(context);
  }

  @override
  void dispatchScrollEndNotification(
    ScrollMetrics metrics,
    BuildContext context,
  ) {
    // We might not have DragEndDetails yet if we're being
    // called from beginActivity.
    final dynamic lastDetails = getLastDragDetails();
    assert(lastDetails == null || lastDetails is DragEndDetails);
    ScrollEndNotification(
      metrics: metrics,
      context: context,
      dragDetails: lastDetails as DragEndDetails?,
    ).dispatch(context);
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

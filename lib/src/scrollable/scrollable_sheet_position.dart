import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/model.dart';
import '../internal/float_comp.dart';
import 'scrollable_sheet_activity.dart';
import 'sheet_content_scroll_activity.dart';
import 'sheet_content_scroll_position.dart';

// TODO: Expose this from the ScrollableSheet's constructor
const _kMaxScrollSpeedToInterrupt = double.infinity;

@internal
class DraggableScrollableSheetPosition extends SheetModel
    implements SheetScrollPositionDelegate {
  DraggableScrollableSheetPosition({
    required super.context,
    required super.initialOffset,
    required super.physics,
    required super.snapGrid,
    super.gestureProxy,
    super.debugLabel,
  });

  // TODO: Stop scroll animations when a non-scrollable activity starts.
  final _scrollPositions = HashSet<SheetScrollPosition>();

  /// A [ScrollPosition] that is currently driving the sheet position.
  SheetScrollPosition? get _primaryScrollPosition => switch (activity) {
        final ScrollAwareSheetActivityMixin activity => activity.scrollPosition,
        _ => null,
      };

  @override
  bool get hasPrimaryScrollPosition => _primaryScrollPosition != null;

  @override
  void addScrollPosition(SheetScrollPosition position) {
    assert(!_scrollPositions.contains(position));
    assert(position != _primaryScrollPosition);
    _scrollPositions.add(position);
  }

  @override
  void removeScrollPosition(SheetScrollPosition position) {
    assert(_scrollPositions.contains(position));
    _scrollPositions.remove(position);
    if (position == _primaryScrollPosition) {
      goIdle();
    }
    assert(position != _primaryScrollPosition);
  }

  @override
  void replaceScrollPosition({
    required SheetScrollPosition oldPosition,
    required SheetScrollPosition newPosition,
  }) {
    assert(_scrollPositions.contains(oldPosition));
    _scrollPositions.remove(oldPosition);
    _scrollPositions.add(newPosition);
    if (activity case final ScrollAwareSheetActivityMixin activity
        when activity.scrollPosition == oldPosition) {
      activity.scrollPosition = newPosition;
    }
  }

  @override
  void takeOver(SheetModel other) {
    super.takeOver(other);
    if (other is DraggableScrollableSheetPosition) {
      assert(_scrollPositions.isEmpty);
      _scrollPositions.addAll(other._scrollPositions);
      other._scrollPositions.clear();
    }
    assert(
      _primaryScrollPosition == null ||
          _scrollPositions.contains(_primaryScrollPosition),
    );
  }

  @override
  void dispose() {
    _scrollPositions.clear();
    super.dispose();
  }

  @override
  void goIdleWithScrollPosition() {
    assert(hasPrimaryScrollPosition);
    _primaryScrollPosition!.goIdle(calledByDelegate: true);
    goIdle();
  }

  @override
  ScrollHoldController holdWithScrollPosition({
    required double heldPreviousVelocity,
    required VoidCallback holdCancelCallback,
    required SheetScrollPosition scrollPosition,
  }) {
    final holdActivity = HoldScrollDrivenSheetActivity(
      scrollPosition,
      onHoldCanceled: holdCancelCallback,
      heldPreviousVelocity: heldPreviousVelocity,
    );
    scrollPosition.beginActivity(
      SheetHoldScrollActivity(delegate: scrollPosition),
    );
    beginActivity(holdActivity);
    return holdActivity;
  }

  @override
  Drag dragWithScrollPosition({
    required DragStartDetails details,
    required VoidCallback dragCancelCallback,
    required SheetScrollPosition scrollPosition,
  }) {
    final heldPreviousVelocity = switch (activity) {
      final HoldScrollDrivenSheetActivity holdActivity =>
        holdActivity.heldPreviousVelocity,
      _ => 0.0,
    };
    final dragActivity = DragScrollDrivenSheetActivity(
      scrollPosition,
      startDetails: details,
      cancelCallback: dragCancelCallback,
      carriedVelocity:
          scrollPosition.physics.carriedMomentum(heldPreviousVelocity),
    );

    beginActivity(dragActivity);
    scrollPosition.beginActivity(
      SheetDragScrollActivity(
        delegate: scrollPosition,
        getLastDragDetails: () => dragActivity.drag.lastRawDetails,
        getPointerDeviceKind: () => dragActivity.drag.pointerDeviceKind,
      ),
    );

    return dragActivity.drag;
  }

  @override
  void goBallisticWithScrollPosition({
    required double velocity,
    required SheetScrollPosition scrollPosition,
  }) {
    if (FloatComp.distance(context.devicePixelRatio)
        .isApprox(scrollPosition.pixels, scrollPosition.minScrollExtent)) {
      final simulation =
          physics.createBallisticSimulation(velocity, this, snapGrid);
      if (simulation != null) {
        scrollPosition.goIdle(calledByDelegate: true);
        goBallisticWith(simulation);
        return;
      }
    }

    final scrolledDistance = scrollPosition.pixels;
    final draggedDistance = offset - minOffset;
    final draggableDistance = maxOffset - minOffset;
    final scrollableDistance =
        scrollPosition.maxScrollExtent - scrollPosition.minScrollExtent;
    final scrollPixelsForScrollPhysics = scrolledDistance + draggedDistance;
    final maxScrollExtentForScrollPhysics =
        draggableDistance + scrollableDistance;
    final scrollMetricsForScrollPhysics = scrollPosition.copyWith(
      minScrollExtent: 0,
      // How many pixels the user can scroll and drag.
      maxScrollExtent: maxScrollExtentForScrollPhysics,
      // How many pixels the user has scrolled and dragged.
      pixels: FloatComp.distance(context.devicePixelRatio).roundToEdgeIfApprox(
        // Round the scrollPixelsForScrollPhysics to 0.0 or the maxScrollExtent
        // if necessary to prevents issues with floating-point precision errors.
        // For example, issue #207 and #212 were caused by infinite recursion of
        // SheetContentScrollPositionOwner.goBallisticWithScrollPosition calls,
        // triggered by ScrollMetrics.outOfRange always being true in
        // ScrollPhysics.createBallisticSimulation due to such a floating-point
        // precision error.
        scrollPixelsForScrollPhysics,
        0,
        maxScrollExtentForScrollPhysics,
      ),
    );

    final scrollSimulation = scrollPosition.physics
        .createBallisticSimulation(scrollMetricsForScrollPhysics, velocity);
    if (scrollSimulation != null) {
      beginActivity(
        BallisticScrollDrivenSheetActivity(
          scrollPosition,
          simulation: scrollSimulation,
          initialOffset: scrollPixelsForScrollPhysics,
          // TODO: Make this configurable.
          shouldInterrupt: (velocity) =>
              velocity.abs() < _kMaxScrollSpeedToInterrupt,
        ),
      );
      scrollPosition.beginActivity(
        SheetBallisticScrollActivity(
          delegate: scrollPosition,
          shouldIgnorePointer: scrollPosition.shouldIgnorePointer,
          getVelocity: () => activity.velocity,
        ),
      );
    } else {
      scrollPosition.goBallistic(velocity, calledByOwner: true);
      goIdle();
    }
  }
}

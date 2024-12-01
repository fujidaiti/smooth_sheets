import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_drag.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import '../internal/float_comp.dart';
import 'scrollable_sheet_activity.dart';
import 'scrollable_sheet_physics.dart';
import 'sheet_content_scroll_activity.dart';
import 'sheet_content_scroll_position.dart';

// TODO: Rename to ScrollableSheetGeometry.
@internal
class ScrollableSheetPosition extends SheetPosition
    implements SheetContentScrollPositionOwner {
  ScrollableSheetPosition({
    required super.context,
    required this.initialPosition,
    required super.minPosition,
    required super.maxPosition,
    required super.physics,
    super.gestureTamperer,
    super.debugLabel,
  });

  /// {@template ScrollableSheetPosition.initialPosition}
  /// The initial position of the sheet.
  /// {@endtemplate}
  final SheetAnchor initialPosition;

  // TODO: Stop scroll animations when a non-scrollable activity starts.
  final _scrollPositions = HashSet<SheetContentScrollPosition>();

  /// A [ScrollPosition] that is currently driving the sheet position.
  SheetContentScrollPosition? get _primaryScrollPosition => switch (activity) {
        final ScrollableSheetActivity activity => activity.scrollPosition,
        _ => null,
      };

  @override
  bool get hasPrimaryScrollPosition => _primaryScrollPosition != null;

  @override
  void addScrollPosition(SheetContentScrollPosition position) {
    assert(!_scrollPositions.contains(position));
    assert(position != _primaryScrollPosition);
    _scrollPositions.add(position);
  }

  @override
  void removeScrollPosition(SheetContentScrollPosition position) {
    assert(_scrollPositions.contains(position));
    _scrollPositions.remove(position);
    if (position == _primaryScrollPosition) {
      goIdle();
    }
    assert(position != _primaryScrollPosition);
  }

  @override
  void replaceScrollPosition({
    required SheetContentScrollPosition oldPosition,
    required SheetContentScrollPosition newPosition,
  }) {
    assert(_scrollPositions.contains(oldPosition));
    _scrollPositions.remove(oldPosition);
    _scrollPositions.add(newPosition);
    if (activity case final ScrollableSheetActivity activity
        when activity.scrollPosition == oldPosition) {
      activity.updateScrollPosition(newPosition);
    }
  }

  @override
  void updatePhysics(SheetPhysics physics) {
    super.updatePhysics(ScrollableSheetPhysics.wrap(physics));
  }

  @override
  void applyNewContentSize(Size contentSize) {
    super.applyNewContentSize(contentSize);
    if (maybePixels == null) {
      setPixels(initialPosition.resolve(contentSize));
    }
  }

  @override
  void takeOver(SheetPosition other) {
    super.takeOver(other);
    if (other is ScrollableSheetPosition) {
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
    _primaryScrollPosition!.goIdle(calledByOwner: true);
    goIdle();
  }

  @override
  ScrollHoldController holdWithScrollPosition({
    required double heldPreviousVelocity,
    required VoidCallback holdCancelCallback,
    required SheetContentScrollPosition scrollPosition,
  }) {
    final holdActivity = HoldScrollDrivenSheetActivity(
      scrollPosition,
      onHoldCanceled: holdCancelCallback,
      heldPreviousVelocity: heldPreviousVelocity,
    );
    scrollPosition.beginActivity(
      SheetContentHoldScrollActivity(delegate: scrollPosition),
    );
    beginActivity(holdActivity);
    return holdActivity;
  }

  @override
  Drag dragWithScrollPosition({
    required DragStartDetails details,
    required VoidCallback dragCancelCallback,
    required SheetContentScrollPosition scrollPosition,
  }) {
    assert(currentDrag == null);
    final dragActivity = DragScrollDrivenSheetActivity(scrollPosition);
    var startDetails = SheetDragStartDetails(
      sourceTimeStamp: details.sourceTimeStamp,
      axisDirection: dragActivity.dragAxisDirection,
      localPositionX: details.localPosition.dx,
      localPositionY: details.localPosition.dy,
      globalPositionX: details.globalPosition.dx,
      globalPositionY: details.globalPosition.dy,
      kind: details.kind,
    );
    if (gestureTamperer case final tamperer?) {
      startDetails = tamperer.onDragStart(startDetails);
    }
    final heldPreviousVelocity = switch (activity) {
      final HoldScrollDrivenSheetActivity holdActivity =>
        holdActivity.heldPreviousVelocity,
      _ => 0.0,
    };
    final drag = SheetDragController(
      target: dragActivity,
      gestureTamperer: gestureTamperer,
      details: startDetails,
      onDragCanceled: dragCancelCallback,
      carriedVelocity:
          scrollPosition.physics.carriedMomentum(heldPreviousVelocity),
      motionStartDistanceThreshold:
          scrollPosition.physics.dragStartDistanceMotionThreshold,
    );
    scrollPosition.beginActivity(
      SheetContentDragScrollActivity(
        delegate: scrollPosition,
        getLastDragDetails: () => drag.lastRawDetails,
        getPointerDeviceKind: () => drag.pointerDeviceKind,
      ),
    );
    beginActivity(dragActivity);
    currentDrag = drag;
    didDragStart(startDetails);
    return drag;
  }

  @override
  void goBallisticWithScrollPosition({
    required double velocity,
    required SheetContentScrollPosition scrollPosition,
  }) {
    assert(hasDimensions);
    if (FloatComp.distance(context.devicePixelRatio)
        .isApprox(scrollPosition.pixels, scrollPosition.minScrollExtent)) {
      final simulation = physics.createBallisticSimulation(velocity, snapshot);
      if (simulation != null) {
        scrollPosition.goIdle(calledByOwner: true);
        goBallisticWith(simulation);
        return;
      }
    }

    final scrolledDistance = scrollPosition.pixels;
    final draggedDistance = pixels - minPixels;
    final draggableDistance = maxPixels - minPixels;
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
          initialPixels: scrollPixelsForScrollPhysics,
        ),
      );
      scrollPosition.beginActivity(
        SheetContentBallisticScrollActivity(
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

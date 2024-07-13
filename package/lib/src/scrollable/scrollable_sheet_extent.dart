import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_drag.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_physics.dart';
import '../internal/double_utils.dart';
import 'scrollable_sheet_activity.dart';
import 'scrollable_sheet_physics.dart';
import 'sheet_content_scroll_activity.dart';
import 'sheet_content_scroll_position.dart';

@internal
class ScrollableSheetExtent extends SheetExtent
    implements SheetContentScrollPositionOwner {
  ScrollableSheetExtent({
    required super.context,
    required this.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required SheetPhysics physics,
    super.gestureTamperer,
    super.debugLabel,
  }) : super(physics: ScrollableSheetPhysics.wrap(physics));

  /// {@template ScrollableSheetExtent.initialExtent}
  /// The initial extent of the sheet.
  /// {@endtemplate}
  final Extent initialExtent;

  @override
  ScrollableSheetPhysics get physics => super.physics as ScrollableSheetPhysics;

  final _scrollPositions = HashSet<SheetContentScrollPosition>();

  /// A [ScrollPosition] that is currently driving the sheet extent.
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
    if (metrics.maybePixels == null) {
      setPixels(initialExtent.resolve(metrics.contentSize));
    }
  }

  @override
  void takeOver(SheetExtent other) {
    super.takeOver(other);
    if (other is ScrollableSheetExtent) {
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
      startDetails = tamperer.tamperWithDragStart(startDetails);
    }
    final drag = currentDrag = SheetDragController(
      target: dragActivity,
      gestureTamperer: gestureTamperer,
      details: startDetails,
      onDragCanceled: dragCancelCallback,
      carriedVelocity: scrollPosition.physics
          .carriedMomentum(scrollPosition.heldPreviousVelocity),
      motionStartDistanceThreshold:
          scrollPosition.physics.dragStartDistanceMotionThreshold,
    );
    scrollPosition.beginActivity(
      SheetContentDragScrollActivity(
        delegate: scrollPosition,
        getLastDragDetails: () => currentDrag?.lastRawDetails,
        getPointerDeviceKind: () => currentDrag?.pointerDeviceKind,
      ),
    );
    beginActivity(dragActivity);
    didDragStart(startDetails);
    return drag;
  }

  @override
  void goBallisticWithScrollPosition({
    required double velocity,
    required SheetContentScrollPosition scrollPosition,
  }) {
    assert(metrics.hasDimensions);
    if (scrollPosition.pixels.isApprox(scrollPosition.minScrollExtent)) {
      final simulation = physics.createBallisticSimulation(velocity, metrics);
      if (simulation != null) {
        scrollPosition.goIdle(calledByOwner: true);
        goBallisticWith(simulation);
        return;
      }
    }

    final scrolledDistance = scrollPosition.pixels;
    final draggedDistance = metrics.pixels - metrics.minPixels;
    final draggableDistance = metrics.maxPixels - metrics.minPixels;
    final scrollableDistance =
        scrollPosition.maxScrollExtent - scrollPosition.minScrollExtent;
    final scrollPixelsForScrollPhysics = scrolledDistance + draggedDistance;
    final scrollMetricsForScrollPhysics = scrollPosition.copyWith(
      minScrollExtent: 0,
      // How many pixels the user can scroll/drag
      maxScrollExtent: draggableDistance + scrollableDistance,
      // How many pixels the user scrolled/dragged
      pixels: scrollPixelsForScrollPhysics,
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

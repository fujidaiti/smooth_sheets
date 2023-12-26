import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/single_child_sheet.dart';
import 'package:smooth_sheets/src/internal/double_utils.dart';
import 'package:smooth_sheets/src/internal/into.dart';
import 'package:smooth_sheets/src/scrollable/content_scroll_position.dart';

class ScrollableSheetExtentFactory extends SingleChildSheetExtentFactory {
  const ScrollableSheetExtentFactory({
    required super.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required super.physics,
  });

  @override
  SheetExtent create({required SheetContext context}) {
    return ScrollableSheetExtent(
      initialExtent: initialExtent,
      minExtent: minExtent,
      maxExtent: maxExtent,
      physics: physics,
      context: context,
    );
  }
}

class ScrollableSheetExtent extends SingleChildSheetExtent {
  ScrollableSheetExtent({
    required super.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required super.physics,
    required super.context,
  }) {
    goIdle();
  }

  final Set<SheetContentScrollPosition> _contentScrollPositions = {};

  void attach(SheetContentScrollPosition position) {
    _contentScrollPositions.add(position);
    position.delegate = () => activity.intoOrNull();
  }

  void detach(SheetContentScrollPosition position) {
    _contentScrollPositions.remove(position);
    position.delegate = null;
  }

  @override
  void dispose() {
    [..._contentScrollPositions].forEach(detach);
    super.dispose();
  }

  @override
  void goIdle() => beginActivity(
        _ContentScrollDrivenSheetActivity(initialExtent: initialExtent),
      );

  @override
  void goBallistic(double velocity) {
    final simulation = physics.createBallisticSimulation(velocity, metrics);
    if (simulation != null) {
      beginActivity(
        _DragInterruptibleBallisticSheetActivity(simulation: simulation),
      );
    } else {
      goIdle();
    }
  }

  @override
  void beginActivity(SheetActivity activity) {
    // TODO: Stop the content scrolling when the new activity is not '_ContentScrollDrivenSheetActivity'.
    super.beginActivity(activity);
  }
}

class _ContentScrollDrivenSheetActivity extends SheetActivity
    with SheetContentScrollPositionDelegate {
  _ContentScrollDrivenSheetActivity({
    required this.initialExtent,
  });

  final Extent initialExtent;

  @override
  void didChangeContentDimensions() {
    if (pixels == null) {
      setPixels(initialExtent.resolve(delegate.contentDimensions!));
    } else {
      super.didChangeContentDimensions();
    }
  }

  double scrolledDistance(ScrollPosition position) => position.pixels;

  double draggedDistance() => pixels! - delegate.minPixels!;

  double draggableDistance() => delegate.maxPixels! - delegate.minPixels!;

  double scrollableDistance(ScrollPosition position) =>
      position.maxScrollExtent - position.minScrollExtent;

  double pixelsForPhysics(ScrollPosition position) =>
      scrolledDistance(position) + draggedDistance();

  ScrollMetrics scrollMetricsForPhysics(ScrollPosition position) =>
      position.copyWith(
        minScrollExtent: 0,
        // How many pixels the user can scroll/drag
        maxScrollExtent: draggableDistance() + scrollableDistance(position),
        // How many pixels the user scrolled/dragged
        pixels: pixelsForPhysics(position),
      );

  double _applyPhysicsToOffset(double offset) {
    return delegate.physics.applyPhysicsToOffset(offset, delegate.metrics);
  }

  double _applyOffset(double offset, SheetContentScrollPosition position) {
    if (offset.isApprox(0)) return 0;

    final maxPixels = delegate.maxPixels!;
    final oldPixels = pixels!;
    final oldScrollPixels = position.pixels;
    final minScrollPixels = position.minScrollExtent;
    final maxScrollPixels = position.maxScrollExtent;
    var delta = offset;

    if (offset > 0) {
      // If the sheet is not at top, drag it up as much as possible
      // until it reaches at 'maxPixels'.
      if (pixels!.isLessThanOrApprox(maxPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.isLessThanOrApprox(delta));
        correctPixels(min(pixels! + physicsAppliedDelta, maxPixels));
        delta -= pixels! - oldPixels;
      }
      // If the sheet is at the top, scroll the content up as much as possible.
      if (pixels!.isGreaterThanOrApprox(maxPixels) &&
          position.extentAfter > 0) {
        position.correctPixels(min(position.pixels + delta, maxScrollPixels));
        delta -= position.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled up anymore, drag the sheet up
      // to make a stretching effect (if needed).
      if (position.pixels.isApprox(maxScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.isLessThanOrApprox(delta));
        correctPixels(pixels! + physicsAppliedDelta);
        delta -= physicsAppliedDelta;
      }
    } else if (offset < 0) {
      // If the sheet is beyond 'maxPixels', drag it down as much
      // as possible until it reaches at 'maxPixels'.
      if (pixels!.isGreaterThanOrApprox(maxPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.abs().isLessThanOrApprox(delta.abs()));
        correctPixels(max(pixels! + physicsAppliedDelta, maxPixels));
        delta -= pixels! - oldPixels;
      }
      // If the sheet is not beyond 'maxPixels', scroll the content down
      // as much as possible.
      if (pixels!.isLessThanOrApprox(maxPixels) && position.extentBefore > 0) {
        position.correctPixels(max(position.pixels + delta, minScrollPixels));
        delta -= position.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled down anymore, drag the sheet down
      // to make a shrinking effect (if needed).
      if (position.pixels.isApprox(minScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.abs().isLessThanOrApprox(delta.abs()));
        correctPixels(pixels! + physicsAppliedDelta);
        delta -= physicsAppliedDelta;
      }
    }

    if (position.pixels != oldScrollPixels) {
      position
        ..notifyListeners()
        ..didUpdateScrollPositionBy(position.pixels - oldScrollPixels);
    }

    if (pixels! != oldPixels) {
      notifyListeners();
      dispatchExtentUpdateNotification();
    }

    final overflow = delegate.physics.computeOverflow(delta, delegate.metrics);
    if (overflow.abs() > 0) {
      position.didOverscrollBy(overflow);
      dispatchOverflowNotification(overflow);
      return overflow;
    }

    return 0;
  }

  @override
  DelegationResult<double> applyBallisticScrollOffset(
    double delta,
    double velocity,
    SheetContentScrollPosition position,
  ) {
    if (!delegate.hasPixels) {
      return const DelegationResult.notHandled();
    }

    final overscroll = _applyOffset(delta, position);
    if (delegate.physics.shouldGoBallistic(velocity, delegate.metrics)) {
      position.goBallistic(velocity);
    }

    return DelegationResult.handled(overscroll);
  }

  @override
  DelegationResult<void> applyUserScrollOffset(
    double delta,
    SheetContentScrollPosition position,
  ) {
    if (!delegate.hasPixels) {
      return const DelegationResult.notHandled();
    }

    _applyOffset(-1 * delta, position);
    return const DelegationResult.handled(null);
  }

  @override
  DelegationResult<ScrollActivity> goBallisticScroll(
    double velocity,
    bool shouldIgnorePointer,
    SheetContentScrollPosition position,
  ) {
    if (!delegate.hasPixels) {
      return const DelegationResult.notHandled();
    }

    if (delegate.physics.shouldGoBallistic(velocity, delegate.metrics)) {
      delegate.goBallistic(velocity);
      return DelegationResult.handled(IdleScrollActivity(position));
    }

    final scrollSimulation = position.physics
        .createBallisticSimulation(scrollMetricsForPhysics(position), velocity);
    if (scrollSimulation != null) {
      return DelegationResult.handled(
        _SheetContentBallisticScrollActivity(
          delegate: position,
          simulation: scrollSimulation,
          vsync: position.context.vsync,
          shouldIgnorePointer: shouldIgnorePointer,
          initialPixels: pixelsForPhysics(position),
        ),
      );
    }

    return const DelegationResult.notHandled();
  }

  @override
  void onWillBallisticScrollCancel() {
    delegate.goBallistic(0);
  }
}

class _DragInterruptibleBallisticSheetActivity extends BallisticSheetActivity
    with SheetContentScrollPositionDelegate {
  _DragInterruptibleBallisticSheetActivity({
    required super.simulation,
  });

  void _cancel() {
    if (controller.isAnimating) {
      controller.stop(canceled: true);
    }
    delegate.goIdle();
  }

  @override
  void onDrag(DragStartDetails details) {
    _cancel();
  }

  @override
  DelegationResult<ScrollActivity> goBallisticScroll(
    double velocity,
    bool shouldIgnorePointer,
    SheetContentScrollPosition position,
  ) {
    _cancel();
    return const DelegationResult.notHandled();
  }
}

class _SheetContentBallisticScrollActivity extends BallisticScrollActivity {
  _SheetContentBallisticScrollActivity({
    required SheetContentScrollPosition delegate,
    required Simulation simulation,
    required TickerProvider vsync,
    required double initialPixels,
    required bool shouldIgnorePointer,
  })  : _oldPixels = initialPixels,
        super(delegate, simulation, vsync, shouldIgnorePointer);

  double _oldPixels;

  @override
  bool applyMoveTo(double pixels) {
    final position = delegate as SheetContentScrollPosition;
    final delta = pixels - _oldPixels;
    final overscroll = position.applyBallisticOffset(delta, velocity);
    _oldPixels = pixels;

    if (overscroll.isApprox(0)) {
      return true;
    } else {
      position.onWillBallisticCancel();
      return false;
    }
  }
}

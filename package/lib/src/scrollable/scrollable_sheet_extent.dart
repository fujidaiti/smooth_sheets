import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/activities.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_status.dart';
import '../internal/double_utils.dart';
import 'delegatable_scroll_position.dart';
import 'scrollable_sheet_physics.dart';

class ScrollableSheetExtentConfig extends SheetExtentConfig {
  const ScrollableSheetExtentConfig({
    required this.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required super.physics,
    super.debugLabel,
  });

  final Extent initialExtent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScrollableSheetExtentConfig &&
        other.initialExtent == initialExtent &&
        super == other;
  }

  @override
  int get hashCode => Object.hash(
        initialExtent,
        super.hashCode,
      );
}

class ScrollableSheetExtentDelegate with SheetExtentDelegate {
  const ScrollableSheetExtentDelegate();

  @override
  SheetActivity createIdleActivity() {
    return _ContentIdleScrollDrivenSheetActivity();
  }

  @override
  SheetActivity createBallisticActivity(Simulation simulation) {
    return _DragInterruptibleBallisticSheetActivity(simulation: simulation);
  }
}

@internal
class SheetContentScrollController extends ScrollController {
  SheetContentScrollController({
    super.debugLabel,
    super.initialScrollOffset,
    super.keepScrollOffset,
    required this.extent,
  });

  final SheetExtent extent;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return DelegatableScrollPosition(
      getDelegate: () => switch (extent.activity) {
        final ScrollPositionDelegate delegate => delegate,
        _ => null,
      },
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
      context: context,
      oldPosition: oldPosition,
      physics: switch (physics) {
        AlwaysScrollableScrollPhysics() => physics,
        _ => AlwaysScrollableScrollPhysics(parent: physics),
      },
    );
  }
}

/// A [SheetActivity] that is driven by one or more [ScrollPosition]s
/// of the scrollable content within the sheet.
abstract class _ContentScrollDrivenSheetActivity extends SheetActivity
    with ScrollPositionDelegate {
  @mustCallSuper
  @override
  void onContentDragStart(
    DragStartDetails details,
    DelegatableScrollPosition position,
  ) {
    delegate.beginActivity(
      _ContentUserScrollDrivenSheetActivity(
        contentScrollPosition: position,
      ),
    );

    dispatchDragStartNotification(details);
  }

  @mustCallSuper
  @override
  void onContentDragEnd(
    DragEndDetails details,
    DelegatableScrollPosition position,
  ) {
    dispatchDragEndNotification(details);
  }

  @mustCallSuper
  @override
  void onContentDragCancel(DelegatableScrollPosition position) {
    dispatchDragCancelNotification();
  }

  @override
  DelegationResult<ScrollActivity> onContentGoIdle(
    DelegatableScrollPosition position,
  ) {
    delegate.goIdle();
    return super.onContentGoIdle(position);
  }

  @override
  DelegationResult<ScrollActivity> onContentGoBallistic(
    double velocity,
    bool shouldIgnorePointer,
    DelegatableScrollPosition position,
  ) {
    if (!delegate.metrics.hasPixels) {
      return const DelegationResult.notHandled();
    }

    if (position.pixels.isApprox(position.minScrollExtent)) {
      final simulation = delegate.physics
          .createBallisticSimulation(velocity, delegate.metrics);
      if (simulation != null) {
        delegate.goBallisticWith(simulation);
        return DelegationResult.handled(IdleScrollActivity(position));
      }
    }

    final scrolledDistance = position.pixels;
    final draggedDistance = pixels! - delegate.metrics.minPixels;
    final draggableDistance =
        delegate.metrics.maxPixels - delegate.metrics.minPixels;
    final scrollableDistance =
        position.maxScrollExtent - position.minScrollExtent;
    final pixelsForScrollPhysics = scrolledDistance + draggedDistance;
    final scrollMetricsForScrollPhysics = position.copyWith(
      minScrollExtent: 0,
      // How many pixels the user can scroll/drag
      maxScrollExtent: draggableDistance + scrollableDistance,
      // How many pixels the user scrolled/dragged
      pixels: pixelsForScrollPhysics,
    );

    final scrollSimulation = position.physics
        .createBallisticSimulation(scrollMetricsForScrollPhysics, velocity);
    if (scrollSimulation != null) {
      delegate.beginActivity(
        _ContentBallisticScrollDrivenSheetActivity(
          contentScrollPosition: position,
        ),
      );

      return DelegationResult.handled(
        _SheetContentBallisticScrollActivity(
          delegate: position,
          simulation: scrollSimulation,
          vsync: position.context.vsync,
          shouldIgnorePointer: shouldIgnorePointer,
          initialPixels: pixelsForScrollPhysics,
        ),
      );
    }

    return const DelegationResult.notHandled();
  }
}

/// A [SheetActivity] that is driven by a single [ScrollPosition]
/// of the scrollable content within the sheet.
abstract class _SingleContentScrollDrivenSheetActivity
    extends _ContentScrollDrivenSheetActivity {
  _SingleContentScrollDrivenSheetActivity({
    required this.contentScrollPosition,
  });

  /// The [DelegatableScrollPosition] that drives this activity.
  final DelegatableScrollPosition contentScrollPosition;

  double _applyPhysicsToOffset(double offset) {
    return delegate.physics.applyPhysicsToOffset(offset, delegate.metrics);
  }

  double _applyScrollOffset(double offset) {
    if (offset.isApprox(0)) return 0;

    final position = contentScrollPosition;
    final maxPixels = delegate.metrics.maxPixels;
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
  DelegationResult<ScrollActivity> onContentGoIdle(
    DelegatableScrollPosition position,
  ) {
    return identical(position, contentScrollPosition)
        ? super.onContentGoIdle(position)
        : const DelegationResult.notHandled();
  }

  @override
  DelegationResult<ScrollActivity> onContentGoBallistic(
    double velocity,
    // ignore: avoid_positional_boolean_parameters
    bool shouldIgnorePointer,
    DelegatableScrollPosition position,
  ) {
    return identical(position, contentScrollPosition)
        ? super.onContentGoBallistic(velocity, shouldIgnorePointer, position)
        : const DelegationResult.notHandled();
  }
}

class _ContentIdleScrollDrivenSheetActivity
    extends _ContentScrollDrivenSheetActivity {
  _ContentIdleScrollDrivenSheetActivity();

  @override
  SheetStatus get status => SheetStatus.stable;

  @override
  void didChangeContentDimensions(Size? oldDimensions) {
    super.didChangeContentDimensions(oldDimensions);
    final config = delegate.config;
    final metrics = delegate.metrics;
    if (pixels == null && config is ScrollableSheetExtentConfig) {
      setPixels(config.initialExtent.resolve(metrics.contentDimensions));
    }
  }
}

class _ContentUserScrollDrivenSheetActivity
    extends _SingleContentScrollDrivenSheetActivity
    with UserControlledSheetActivityMixin {
  _ContentUserScrollDrivenSheetActivity({
    required super.contentScrollPosition,
  });

  @override
  DelegationResult<void> onApplyUserScrollOffsetToContent(
    double delta,
    DelegatableScrollPosition position,
  ) {
    if (!delegate.metrics.hasPixels ||
        !identical(position, contentScrollPosition)) {
      return const DelegationResult.notHandled();
    }

    final oldPixels = pixels!;
    _applyScrollOffset(-1 * delta);

    if (pixels != oldPixels) {
      dispatchDragUpdateNotification(delta: pixels! - oldPixels);
    }

    return const DelegationResult.handled(null);
  }

  @override
  void onContentDragCancel(DelegatableScrollPosition position) {
    super.onContentDragCancel(position);
    if (identical(position, contentScrollPosition)) {
      delegate.goBallistic(0);
    }
  }
}

class _ContentBallisticScrollDrivenSheetActivity
    extends _SingleContentScrollDrivenSheetActivity {
  _ContentBallisticScrollDrivenSheetActivity({
    required super.contentScrollPosition,
  });

  @override
  SheetStatus get status => SheetStatus.controlled;

  @override
  DelegationResult<double> onApplyBallisticScrollOffsetToContent(
    double delta,
    double velocity,
    DelegatableScrollPosition position,
  ) {
    if (!delegate.metrics.hasPixels ||
        !identical(position, contentScrollPosition)) {
      return const DelegationResult.notHandled();
    }

    final oldPixels = pixels!;
    final overscroll = _applyScrollOffset(delta);

    if (pixels != oldPixels) {
      dispatchUpdateNotification();
    }

    final physics = delegate.physics;
    if (((position.extentBefore.isApprox(0) && velocity < 0) ||
            (position.extentAfter.isApprox(0) && velocity > 0)) &&
        physics is ScrollableSheetPhysics &&
        physics.shouldInterruptBallisticScroll(velocity, delegate.metrics)) {
      delegate.goBallistic(0);
    }

    return DelegationResult.handled(overscroll);
  }

  @override
  void onWillContentBallisticScrollCancel(DelegatableScrollPosition position) {
    if (identical(position, contentScrollPosition)) {
      delegate.goBallistic(0);
    }
  }
}

class _DragInterruptibleBallisticSheetActivity extends BallisticSheetActivity
    with ScrollPositionDelegate {
  _DragInterruptibleBallisticSheetActivity({
    required super.simulation,
  });

  void _cancelSimulation() {
    if (controller.isAnimating) {
      controller.stop(canceled: true);
    }
  }

  @override
  void onContentDragStart(
    DragStartDetails details,
    DelegatableScrollPosition position,
  ) {
    _cancelSimulation();
    delegate.beginActivity(
      _ContentUserScrollDrivenSheetActivity(
        contentScrollPosition: position,
      ),
    );
  }
}

class _SheetContentBallisticScrollActivity extends BallisticScrollActivity {
  _SheetContentBallisticScrollActivity({
    required DelegatableScrollPosition delegate,
    required Simulation simulation,
    required TickerProvider vsync,
    required double initialPixels,
    required bool shouldIgnorePointer,
  })  : _oldPixels = initialPixels,
        super(delegate, simulation, vsync, shouldIgnorePointer);

  double _oldPixels;

  @override
  bool applyMoveTo(double pixels) {
    final position = delegate as DelegatableScrollPosition;
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

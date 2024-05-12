import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../foundation/activities.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_status.dart';
import '../internal/double_utils.dart';
import 'delegatable_scroll_position.dart';
import 'scrollable_sheet_physics.dart';

@internal
class ScrollableSheetExtentFactory extends SheetExtentFactory {
  const ScrollableSheetExtentFactory();

  @override
  SheetExtent createSheetExtent({
    required SheetContext context,
    required SheetExtentConfig config,
  }) {
    return ScrollableSheetExtent(
      context: context,
      config: config,
    );
  }
}

class ScrollableSheetExtentConfig extends SheetExtentConfig {
  const ScrollableSheetExtentConfig({
    required this.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required ScrollableSheetPhysics physics,
    super.debugLabel,
  }) : super(physics: physics);

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

@internal
class ScrollableSheetExtent extends SheetExtent {
  ScrollableSheetExtent({
    required super.context,
    required super.config,
  });

  @override
  void goIdle() {
    beginActivity(_ContentIdleScrollDrivenSheetActivity());
  }

  @override
  void goBallisticWith(Simulation simulation) {
    beginActivity(
      _DragInterruptibleBallisticSheetActivity(
        simulation: simulation,
      ),
    );
  }
}

// TODO: Move this to a separate file
@internal
class SheetContentScrollController extends ScrollController {
  SheetContentScrollController({
    super.debugLabel,
    super.initialScrollOffset,
    super.keepScrollOffset,
    required this.getDelegate,
  });

  final ValueGetter<ScrollPositionDelegate?> getDelegate;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return DelegatableScrollPosition(
      getDelegate: getDelegate,
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
  @override
  bool isCompatibleWith(SheetExtent newOwner) {
    return newOwner is ScrollableSheetExtent;
  }

  @mustCallSuper
  @override
  void onContentDragStart(
    DragStartDetails details,
    DelegatableScrollPosition position,
  ) {
    owner.beginActivity(
      _ContentUserScrollDrivenSheetActivity(
        contentScrollPosition: position,
      ),
    );
  }

  @override
  DelegationResult<ScrollActivity> onContentGoIdle(
    DelegatableScrollPosition position,
  ) {
    owner.goIdle();
    return super.onContentGoIdle(position);
  }

  @override
  DelegationResult<ScrollActivity> onContentGoBallistic(
    double velocity,
    bool shouldIgnorePointer,
    DelegatableScrollPosition position,
  ) {
    final metrics = owner.metrics;
    if (!metrics.hasDimensions) {
      return const DelegationResult.notHandled();
    }

    if (position.pixels.isApprox(position.minScrollExtent)) {
      final simulation =
          owner.config.physics.createBallisticSimulation(velocity, metrics);
      if (simulation != null) {
        owner.goBallisticWith(simulation);
        return DelegationResult.handled(IdleScrollActivity(position));
      }
    }

    final scrolledDistance = position.pixels;
    final draggedDistance = metrics.pixels - metrics.minPixels;
    final draggableDistance = metrics.maxPixels - metrics.minPixels;
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
      owner.beginActivity(
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
    return owner.config.physics.applyPhysicsToOffset(offset, owner.metrics);
  }

  double _applyScrollOffset(double offset) {
    if (offset.isApprox(0)) return 0;

    final position = contentScrollPosition;
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
      if (newPixels.isLessThanOrApprox(maxPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.isLessThanOrApprox(delta));
        newPixels = min(newPixels + physicsAppliedDelta, maxPixels);
        delta -= newPixels - oldPixels;
      }
      // If the sheet is at the top, scroll the content up as much as possible.
      if (newPixels.isGreaterThanOrApprox(maxPixels) &&
          position.extentAfter > 0) {
        position.correctPixels(min(position.pixels + delta, maxScrollPixels));
        delta -= position.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled up anymore, drag the sheet up
      // to make a stretching effect (if needed).
      if (position.pixels.isApprox(maxScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.isLessThanOrApprox(delta));
        newPixels += physicsAppliedDelta;
        delta -= physicsAppliedDelta;
      }
    } else if (offset < 0) {
      // If the sheet is beyond 'maxPixels', drag it down as much
      // as possible until it reaches at 'maxPixels'.
      if (newPixels.isGreaterThanOrApprox(maxPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.abs().isLessThanOrApprox(delta.abs()));
        newPixels = max(newPixels + physicsAppliedDelta, maxPixels);
        delta -= newPixels - oldPixels;
      }
      // If the sheet is not beyond 'maxPixels', scroll the content down
      // as much as possible.
      if (newPixels.isLessThanOrApprox(maxPixels) &&
          position.extentBefore > 0) {
        position.correctPixels(max(position.pixels + delta, minScrollPixels));
        delta -= position.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled down anymore, drag the sheet down
      // to make a shrinking effect (if needed).
      if (position.pixels.isApprox(minScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(physicsAppliedDelta.abs().isLessThanOrApprox(delta.abs()));
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

    final overflow = owner.config.physics.computeOverflow(delta, owner.metrics);
    if (overflow.abs() > 0) {
      position.didOverscrollBy(overflow);
      owner.dispatchOverflowNotification(overflow);
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
  void didChangeContentSize(Size? oldSize) {
    super.didChangeContentSize(oldSize);
    final config = owner.config;
    final metrics = owner.metrics;
    if (metrics.maybePixels == null && config is ScrollableSheetExtentConfig) {
      owner.setPixels(config.initialExtent.resolve(metrics.contentSize));
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
    if (!owner.metrics.hasDimensions ||
        !identical(position, contentScrollPosition)) {
      return const DelegationResult.notHandled();
    }

    _applyScrollOffset(-1 * delta);
    return const DelegationResult.handled(null);
  }

  @override
  void onContentDragCancel(DelegatableScrollPosition position) {
    super.onContentDragCancel(position);
    if (identical(position, contentScrollPosition)) {
      owner.goBallistic(0);
    }
  }
}

class _ContentBallisticScrollDrivenSheetActivity
    extends _SingleContentScrollDrivenSheetActivity {
  _ContentBallisticScrollDrivenSheetActivity({
    required super.contentScrollPosition,
  });

  @override
  SheetStatus get status => SheetStatus.animating;

  @override
  DelegationResult<double> onApplyBallisticScrollOffsetToContent(
    double delta,
    double velocity,
    DelegatableScrollPosition position,
  ) {
    if (!owner.metrics.hasDimensions ||
        !identical(position, contentScrollPosition)) {
      return const DelegationResult.notHandled();
    }

    final overscroll = _applyScrollOffset(delta);
    final physics = owner.config.physics;
    if (((position.extentBefore.isApprox(0) && velocity < 0) ||
            (position.extentAfter.isApprox(0) && velocity > 0)) &&
        physics is ScrollableSheetPhysics &&
        physics.shouldInterruptBallisticScroll(velocity, owner.metrics)) {
      owner.goBallistic(0);
    }

    return DelegationResult.handled(overscroll);
  }

  @override
  void onWillContentBallisticScrollCancel(DelegatableScrollPosition position) {
    if (identical(position, contentScrollPosition)) {
      owner.goBallistic(0);
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
    owner.beginActivity(
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

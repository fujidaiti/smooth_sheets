import 'dart:collection';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../internal/float_comp.dart';
import 'activity.dart';
import 'drag.dart';
import 'model.dart';
import 'model_owner.dart';

// TODO: Expose this from the ScrollableSheet's constructor
const _kMaxScrollSpeedToInterrupt = double.infinity;

@internal
class ScrollAwareSheetModel extends SheetModel
    implements SheetScrollPositionDelegate {
  ScrollAwareSheetModel({
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
    if (other is ScrollAwareSheetModel) {
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

/// A mixin for [SheetActivity]s that is associated with
/// a [SheetScrollPosition].
///
/// This activity is responsible for both scrolling a scrollable content
/// in the sheet and dragging the sheet itself.
///
/// [shouldIgnorePointer] and [SheetScrollPosition.shouldIgnorePointer]
/// of the associated scroll position may be synchronized, but not always.
/// For example, [BallisticScrollDrivenSheetActivity]'s [shouldIgnorePointer]
/// is always `false` while the associated scroll position sets it to `true`
/// in most cases to ensure that the pointer events, which potentially
/// interrupt the ballistic scroll animation, are not stolen by clickable
/// items in the scroll view.
@internal
mixin ScrollAwareSheetActivityMixin on SheetActivity<ScrollAwareSheetModel> {
  SheetScrollPosition get scrollPosition;

  set scrollPosition(SheetScrollPosition value);

  double _applyPhysicsToOffset(double offset) {
    return owner.physics.applyPhysicsToOffset(offset, owner);
  }

  double _applyScrollOffset(double offset) {
    final cmp = FloatComp.distance(owner.context.devicePixelRatio);
    if (cmp.isApprox(offset, 0)) return 0;

    final maxOffset = owner.maxOffset;
    final oldOffset = owner.offset;
    final oldScrollPixels = scrollPosition.pixels;
    final minScrollPixels = scrollPosition.minScrollExtent;
    final maxScrollPixels = scrollPosition.maxScrollExtent;
    var newOffset = oldOffset;
    var delta = offset;

    if (offset > 0) {
      // If the sheet is not at top, drag it up as much as possible
      // until it reaches at 'maxOffset'.
      if (cmp.isLessThanOrApprox(newOffset, maxOffset)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta, delta));
        newOffset = min(newOffset + physicsAppliedDelta, maxOffset);
        delta -= newOffset - oldOffset;
      }
      // If the sheet is at the top, scroll the content up as much as possible.
      if (cmp.isGreaterThanOrApprox(newOffset, maxOffset) &&
          scrollPosition.extentAfter > 0) {
        scrollPosition
            .correctPixels(min(scrollPosition.pixels + delta, maxScrollPixels));
        delta -= scrollPosition.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled up anymore, drag the sheet up
      // to make a bouncing effect (if needed).
      if (cmp.isApprox(scrollPosition.pixels, maxScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta, delta));
        newOffset += physicsAppliedDelta;
        delta -= physicsAppliedDelta;
      }
    } else if (offset < 0) {
      // If the sheet is beyond 'maxOffset', drag it down as much
      // as possible until it reaches at 'maxOffset'.
      if (cmp.isGreaterThanOrApprox(newOffset, maxOffset)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta.abs(), delta.abs()));
        newOffset = max(newOffset + physicsAppliedDelta, maxOffset);
        delta -= newOffset - oldOffset;
      }
      // If the sheet is not beyond 'maxOffset', scroll the content down
      // as much as possible.
      if (cmp.isLessThanOrApprox(newOffset, maxOffset) &&
          scrollPosition.extentBefore > 0) {
        scrollPosition
            .correctPixels(max(scrollPosition.pixels + delta, minScrollPixels));
        delta -= scrollPosition.pixels - oldScrollPixels;
      }
      // If the content cannot be scrolled down anymore, drag the sheet down
      // to make a shrinking effect (if needed).
      if (cmp.isApprox(scrollPosition.pixels, minScrollPixels)) {
        final physicsAppliedDelta = _applyPhysicsToOffset(delta);
        assert(cmp.isLessThanOrApprox(physicsAppliedDelta.abs(), delta.abs()));
        newOffset += physicsAppliedDelta;
        delta -= physicsAppliedDelta;
      }
    }

    if (scrollPosition.pixels != oldScrollPixels) {
      scrollPosition
        ..notifyListeners()
        ..didUpdateScrollPositionBy(scrollPosition.pixels - oldScrollPixels);
    }

    owner.setOffset(newOffset);

    final overflow = owner.physics.computeOverflow(delta, owner);
    if (overflow.abs() > 0) {
      scrollPosition.didOverscrollBy(overflow);
      return overflow;
    }

    return 0;
  }
}

/// A [SheetActivity] that either scrolls a scrollable content of
/// a sheet or drags the sheet itself as the user drags
/// their finger across the screen.
///
/// The [scrollPosition], which is associated with the scrollable content,
/// must have a [SheetDragScrollActivity] as its activity throughout
/// the lifetime of this activity.
@internal
class DragScrollDrivenSheetActivity
    extends DragSheetActivity<ScrollAwareSheetModel>
    with ScrollAwareSheetActivityMixin {
  DragScrollDrivenSheetActivity(
    SheetScrollPosition scrollPosition, {
    required super.startDetails,
    required super.cancelCallback,
    required super.carriedVelocity,
  })  : _scrollPosition = scrollPosition,
        assert(() {
          if (scrollPosition.axisDirection != AxisDirection.down &&
              scrollPosition.axisDirection != AxisDirection.up) {
            throw FlutterError(
              'The axis direction of the scroll position associated with a '
              'Sheet must be either $AxisDirection.down '
              'or $AxisDirection.up, but the provided scroll position has an '
              'axis direction of ${scrollPosition.axisDirection}.',
            );
          }
          return true;
        }());

  SheetScrollPosition? _scrollPosition;

  @override
  SheetScrollPosition get scrollPosition {
    assert(debugAssertNotDisposed());
    return _scrollPosition!;
  }

  @override
  set scrollPosition(SheetScrollPosition value) {
    _scrollPosition = value;
  }

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
    switch (delta.dy) {
      case < 0:
        final draggablePixels = scrollPosition.extentAfter +
            max(0.0, owner.maxOffset - owner.offset);
        assert(draggablePixels >= 0);
        return Offset(delta.dx, max(-1 * draggablePixels, delta.dy));

      case > 0:
        final draggablePixels = scrollPosition.extentBefore +
            max(0.0, owner.offset - owner.minOffset);
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
    final oldOffset = owner.offset;
    final overflow = _applyScrollOffset(-1 * details.deltaY);
    if (owner.offset != oldOffset) {
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
/// a sheet or the sheet itself based on a physics simulation.
///
/// The [scrollPosition], which is associated with the scrollable content,
/// must have a [SheetBallisticScrollActivity] as its activity throughout
/// the lifetime of this activity.
@internal
class BallisticScrollDrivenSheetActivity
    extends SheetActivity<ScrollAwareSheetModel>
    with ControlledSheetActivityMixin, ScrollAwareSheetActivityMixin {
  BallisticScrollDrivenSheetActivity(
    SheetScrollPosition scrollPosition, {
    required this.simulation,
    required this.shouldInterrupt,
    required double initialOffset,
  })  : _scrollPosition = scrollPosition,
        _oldOffset = initialOffset;

  final Simulation simulation;
  final bool Function(double velocity) shouldInterrupt;

  double _oldOffset;

  SheetScrollPosition? _scrollPosition;

  @override
  SheetScrollPosition get scrollPosition {
    assert(debugAssertNotDisposed());
    return _scrollPosition!;
  }

  @override
  set scrollPosition(SheetScrollPosition value) {
    _scrollPosition = value;
  }

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
    final delta = controller.value - _oldOffset;
    _oldOffset = controller.value;
    final overflow = _applyScrollOffset(delta);
    if (owner.offset != _oldOffset) {
      owner.didUpdateGeometry();
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
            shouldInterrupt(velocity);
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
/// with the scrollable content must have a [SheetHoldScrollActivity]
/// as its activity throughout the lifetime of this activity.
class HoldScrollDrivenSheetActivity extends SheetActivity<ScrollAwareSheetModel>
    with ScrollAwareSheetActivityMixin
    implements ScrollHoldController {
  HoldScrollDrivenSheetActivity(
    SheetScrollPosition scrollPosition, {
    required this.heldPreviousVelocity,
    required this.onHoldCanceled,
  }) : _scrollPosition = scrollPosition;

  final double heldPreviousVelocity;
  final VoidCallback? onHoldCanceled;

  SheetScrollPosition? _scrollPosition;

  @override
  SheetScrollPosition get scrollPosition {
    assert(debugAssertNotDisposed());
    return _scrollPosition!;
  }

  @override
  set scrollPosition(SheetScrollPosition value) {
    _scrollPosition = value;
  }

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

class SheetScrollable extends StatefulWidget {
  const SheetScrollable({
    super.key,
    this.debugLabel,
    this.keepScrollOffset = true,
    this.initialScrollOffset = 0,
    required this.builder,
  });

  final String? debugLabel;
  final bool keepScrollOffset;
  final double initialScrollOffset;
  final ScrollableWidgetBuilder builder;

  @override
  State<SheetScrollable> createState() => _SheetScrollableState();
}

class _SheetScrollableState extends State<SheetScrollable> {
  late ScrollController _scrollController;
  ScrollAwareSheetModel? _model;

  @override
  void initState() {
    super.initState();
    _scrollController = createController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _model = SheetModelOwner.of(context)! as ScrollAwareSheetModel;
  }

  @override
  void didUpdateWidget(SheetScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.debugLabel != oldWidget.debugLabel ||
        widget.keepScrollOffset != oldWidget.keepScrollOffset ||
        widget.initialScrollOffset != oldWidget.initialScrollOffset) {
      _scrollController.dispose();
      _scrollController = createController();
    }
  }

  @factory
  SheetScrollController createController() {
    return SheetScrollController(
      delegate: () => _model,
      debugLabel: widget.debugLabel,
      initialScrollOffset: widget.initialScrollOffset,
      keepScrollOffset: widget.keepScrollOffset,
    );
  }

  @override
  void dispose() {
    _model = null;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _scrollController);
}

/// Delegate of a [SheetScrollPosition].
///
/// The associated scroll positions delegate their behavior of
/// `goIdle`, `hold`, `drag`, and `goBallistic` to this object.
@internal
abstract class SheetScrollPositionDelegate {
  // TODO: Remove the following 3 methods.
  bool get hasPrimaryScrollPosition;

  void addScrollPosition(SheetScrollPosition position);

  void removeScrollPosition(SheetScrollPosition position);

  void replaceScrollPosition({
    required SheetScrollPosition oldPosition,
    required SheetScrollPosition newPosition,
  });

  // TODO: Change the signature to `(SheetScrollPosition) -> void`.
  void goIdleWithScrollPosition();

  ScrollHoldController holdWithScrollPosition({
    required double heldPreviousVelocity,
    required VoidCallback holdCancelCallback,
    required SheetScrollPosition scrollPosition,
  });

  Drag dragWithScrollPosition({
    required DragStartDetails details,
    required VoidCallback dragCancelCallback,
    required SheetScrollPosition scrollPosition,
  });

  void goBallisticWithScrollPosition({
    required double velocity,
    required SheetScrollPosition scrollPosition,
  });
}

/// A [ScrollPosition] for a scrollable content in a sheet.
@internal
class SheetScrollPosition extends ScrollPositionWithSingleContext {
  SheetScrollPosition({
    required ScrollPhysics physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.debugLabel,
    super.keepScrollOffset,
  }) : super(
          physics: switch (physics) {
            AlwaysScrollableScrollPhysics() => physics,
            _ => AlwaysScrollableScrollPhysics(parent: physics),
          },
        );

  /// Getter of a [SheetScrollPositionDelegate] for this scroll position.
  ///
  /// This property is set by [SheetScrollController] when attaching
  /// this object to the controller, and it is unset when detaching.
  ValueGetter<SheetScrollPositionDelegate?>? _delegate;

  /// Whether the scroll view should prevent its contents from receiving
  /// pointer events.
  @override
  bool get shouldIgnorePointer => activity!.shouldIgnorePointer;

  /// Sets the user scroll direction.
  ///
  /// This exists only to expose `updateUserScrollDirection`
  /// that is marked as `@protected` in the [ScrollPositionWithSingleContext].
  set userScrollDirection(ScrollDirection value) {
    updateUserScrollDirection(value);
  }

  @override
  void absorb(ScrollPosition other) {
    if (other is SheetScrollPosition) {
      _delegate?.call()?.replaceScrollPosition(
            oldPosition: other,
            newPosition: this,
          );
    }
    super.absorb(other);
  }

  @override
  void goIdle({bool calledByDelegate = false}) {
    final delegate = _delegate?.call();
    if (delegate != null &&
        delegate.hasPrimaryScrollPosition &&
        !calledByDelegate) {
      delegate.goIdleWithScrollPosition();
    } else {
      beginActivity(IdleScrollActivity(this));
    }
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    return switch (_delegate?.call()) {
      null => super.hold(holdCancelCallback),
      final it => it.holdWithScrollPosition(
          scrollPosition: this,
          holdCancelCallback: holdCancelCallback,
          heldPreviousVelocity: activity!.velocity,
        ),
    };
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    return switch (_delegate?.call()) {
      null => super.drag(details, dragCancelCallback),
      final it => it.dragWithScrollPosition(
          scrollPosition: this,
          dragCancelCallback: dragCancelCallback,
          details: details,
        ),
    };
  }

  @override
  void goBallistic(double velocity, {bool calledByOwner = false}) {
    final delegate = _delegate?.call();
    if (delegate != null &&
        delegate.hasPrimaryScrollPosition &&
        !calledByOwner) {
      delegate.goBallisticWithScrollPosition(
        velocity: velocity,
        scrollPosition: this,
      );
      return;
    }
    final simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      beginActivity(BallisticScrollActivity(
        this,
        simulation,
        context.vsync,
        activity?.shouldIgnorePointer ?? true,
      ));
    } else {
      goIdle(calledByDelegate: calledByOwner);
    }
  }
}

/// A [ScrollActivity] for the [SheetScrollPosition] that is associated
/// with a [DragScrollDrivenSheetActivity].
///
/// This activity is like a placeholder, meaning it doesn't actually modify the
/// scroll position and the actual scrolling is done by the associated
/// [DragScrollDrivenSheetActivity].
@internal
class SheetDragScrollActivity extends ScrollActivity {
  SheetDragScrollActivity({
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

/// A [ScrollActivity] for the [SheetScrollPosition] that is associated
/// with a [BallisticScrollDrivenSheetActivity].
///
/// This activity is like a placeholder, meaning it doesn't actually modify the
/// scroll position and the actual scrolling is done by the associated
/// [BallisticScrollDrivenSheetActivity].
@internal
class SheetBallisticScrollActivity extends ScrollActivity {
  SheetBallisticScrollActivity({
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

/// A [ScrollActivity] for the [SheetScrollPosition] that is associated
/// with a [HoldScrollDrivenSheetActivity].
///
/// This activity is like a placeholder, meaning it doesn't actually modify the
/// scroll position and the actual scrolling is done by the associated
/// [HoldScrollDrivenSheetActivity].
class SheetHoldScrollActivity extends ScrollActivity {
  SheetHoldScrollActivity({
    required ScrollActivityDelegate delegate,
  }) : super(delegate);

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0.0;
}

@internal
class SheetScrollController extends ScrollController {
  SheetScrollController({
    required this.delegate,
    super.debugLabel,
    super.initialScrollOffset,
    super.keepScrollOffset,
  });

  final ValueGetter<SheetScrollPositionDelegate?> delegate;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return SheetScrollPosition(
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
      context: context,
      oldPosition: oldPosition,
      physics: physics,
    );
  }

  @override
  void attach(ScrollPosition position) {
    assert(position is SheetScrollPosition);
    super.attach(position);
    if (delegate() case final it?) {
      it.addScrollPosition(position as SheetScrollPosition);
      position._delegate = delegate;
    }
  }

  @override
  void detach(ScrollPosition position) {
    assert(position is SheetScrollPosition);
    super.detach(position);
    if (delegate() case final it?) {
      it.removeScrollPosition(position as SheetScrollPosition);
      position._delegate = null;
    }
  }
}

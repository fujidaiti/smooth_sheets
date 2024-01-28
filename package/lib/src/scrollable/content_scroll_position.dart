import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet_extent.dart';

@internal
sealed class DelegationResult<T> {
  const DelegationResult();
  const factory DelegationResult.handled(T value) = Handled<T>;
  const factory DelegationResult.notHandled() = NotHandled<T>;
}

@internal
class Handled<T> extends DelegationResult<T> {
  const Handled(this.value);
  final T value;
}

@internal
class NotHandled<T> extends DelegationResult<T> {
  const NotHandled();
}

@internal
mixin SheetContentScrollPositionDelegate {
  void onDragStart(DragStartDetails details) {}
  void onDragEnd() {}
  void onWillBallisticScrollCancel() {}

  DelegationResult<void> applyUserScrollOffset(
    double delta,
    SheetContentScrollPosition position,
  ) {
    return const DelegationResult.notHandled();
  }

  DelegationResult<double> applyBallisticScrollOffset(
    double delta,
    double velocity,
    SheetContentScrollPosition position,
  ) {
    return const DelegationResult.notHandled();
  }

  DelegationResult<ScrollActivity> goIdleScroll(
    SheetContentScrollPosition position,
  ) {
    return const DelegationResult.notHandled();
  }

  DelegationResult<ScrollActivity> goBallisticScroll(
    double velocity,
    // ignore: avoid_positional_boolean_parameters
    bool shouldIgnorePointer,
    SheetContentScrollPosition position,
  ) {
    return const DelegationResult.notHandled();
  }
}

@internal
class SheetContentScrollPosition extends ScrollPositionWithSingleContext {
  SheetContentScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.debugLabel,
    super.keepScrollOffset,
  });

  ValueGetter<SheetContentScrollPositionDelegate?>? delegate;
  SheetContentScrollPositionDelegate? get _delegate => delegate?.call();

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
      delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
    );

    final result = _delegate?.applyUserScrollOffset(delta, this);
    switch (result) {
      case NotHandled():
        setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
      case null || Handled():
        break;
    }
  }

  double applyBallisticOffset(double delta, double velocity) {
    final result = _delegate?.applyBallisticScrollOffset(delta, velocity, this);
    return switch (result) {
      Handled(value: final overscroll) => overscroll,
      null || NotHandled() => physics.applyPhysicsToUserOffset(this, delta),
    };
  }

  @override
  void goIdle() {
    switch (_delegate?.goIdleScroll(this)) {
      case null || NotHandled():
        super.goIdle();
      case Handled(value: final activity):
        beginActivity(activity);
    }
  }

  @override
  void goBallistic(double velocity) {
    final shouldIgnorePointer = activity?.shouldIgnorePointer ?? true;
    final result =
        _delegate?.goBallisticScroll(velocity, shouldIgnorePointer, this);

    switch (result) {
      case Handled(value: final activity):
        beginActivity(activity);
      case null || NotHandled():
        super.goBallistic(velocity);
    }
  }

  void onWillBallisticCancel() {
    if (_delegate != null) {
      _delegate!.onWillBallisticScrollCancel();
    }
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    switch (_delegate) {
      case null:
        return super.drag(details, dragCancelCallback);

      case final delegate:
        delegate.onDragStart(details);
        return super.drag(details, () {
          _delegate?.onDragEnd();
          dragCancelCallback();
        });
    }
  }
}

@internal
class SheetContentScrollController extends ScrollController {
  SheetContentScrollController({
    super.debugLabel,
    super.initialScrollOffset,
    super.keepScrollOffset,
  });

  ScrollableSheetExtent? _extent;
  // ignore: avoid_setters_without_getters
  set extent(ScrollableSheetExtent? newExtent) {
    if (_extent == newExtent) return;

    if (_extent != null) {
      positions
          .whereType<SheetContentScrollPosition>()
          .forEach(_extent!.detach);
    }

    if (newExtent != null) {
      positions
          .whereType<SheetContentScrollPosition>()
          .forEach(newExtent.attach);
    }

    _extent = newExtent;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return SheetContentScrollPosition(
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

  @override
  void attach(ScrollPosition position) {
    if (position is SheetContentScrollPosition) {
      _extent?.attach(position);
    }

    super.attach(position);
  }

  @override
  void detach(ScrollPosition position) {
    if (position is SheetContentScrollPosition) {
      _extent?.detach(position);
    }

    super.detach(position);
  }
}

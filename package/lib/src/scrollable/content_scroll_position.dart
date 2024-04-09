import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

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
  void onDragStart(
    DragStartDetails details,
    SheetContentScrollPosition position,
  ) {}

  void onDragUpdate(
    DragUpdateDetails details,
    SheetContentScrollPosition position,
  ) {}

  void onDragEnd(
    DragEndDetails details,
    SheetContentScrollPosition position,
  ) {}

  void onDragCancel(
    SheetContentScrollPosition position,
  ) {}

  void onWillBallisticScrollCancel(
    SheetContentScrollPosition position,
  ) {}

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
    required this.getDelegate,
  });

  final ValueGetter<SheetContentScrollPositionDelegate?> getDelegate;
  SheetContentScrollPositionDelegate? get _delegate => getDelegate();

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
      _delegate!.onWillBallisticScrollCancel(this);
    }
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _delegate?.onDragStart(details, this);
    return _DragProxy(
      target: super.drag(details, dragCancelCallback),
      onUpdate: (details) => _delegate?.onDragUpdate(details, this),
      onEnd: (details) => _delegate?.onDragEnd(details, this),
      onCancel: () => _delegate?.onDragCancel(this),
    );
  }
}

class _DragProxy extends Drag {
  _DragProxy({
    required this.target,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final Drag target;
  final void Function(DragUpdateDetails) onUpdate;
  final void Function(DragEndDetails) onEnd;
  final VoidCallback onCancel;

  @override
  void update(DragUpdateDetails details) {
    onUpdate(details);
    target.update(details);
  }

  @override
  void end(DragEndDetails details) {
    onEnd(details);
    target.end(details);
  }

  @override
  void cancel() {
    onCancel();
    target.cancel();
  }
}

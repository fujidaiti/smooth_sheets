import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'scrollable_sheet.dart';

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

/// A [ScrollPosition] for a scrollable content in a [Sheet].
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

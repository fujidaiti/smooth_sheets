import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'scrollable_sheet.dart';

/// An owner of [SheetContentScrollPosition]s.
///
/// The associated scroll positions delegate their behavior of
/// `goIdle`, `hold`, `drag`, and `goBallistic` to this owner.
@internal
abstract class SheetContentScrollPositionOwner {
  bool get hasPrimaryScrollPosition;
  void addScrollPosition(SheetContentScrollPosition position);
  void removeScrollPosition(SheetContentScrollPosition position);

  void replaceScrollPosition({
    required SheetContentScrollPosition oldPosition,
    required SheetContentScrollPosition newPosition,
  });

  void goIdleWithScrollPosition();

  ScrollHoldController holdWithScrollPosition({
    required double heldPreviousVelocity,
    required VoidCallback holdCancelCallback,
    required SheetContentScrollPosition scrollPosition,
  });

  Drag dragWithScrollPosition({
    required DragStartDetails details,
    required VoidCallback dragCancelCallback,
    required SheetContentScrollPosition scrollPosition,
  });

  void goBallisticWithScrollPosition({
    required double velocity,
    required SheetContentScrollPosition scrollPosition,
  });
}

/// A [ScrollPosition] for a scrollable content in a [ScrollableSheet].
@internal
class SheetContentScrollPosition extends ScrollPositionWithSingleContext {
  SheetContentScrollPosition({
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

  /// Getter for the owner of this scroll position.
  ///
  /// This property is set by [SheetContentScrollController] when attaching
  /// this object to the controller, and it is unset when detaching.
  ValueGetter<SheetContentScrollPositionOwner?>? _getOwner;

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
    if (other is SheetContentScrollPosition) {
      _getOwner?.call()?.replaceScrollPosition(
            oldPosition: other,
            newPosition: this,
          );
    }
    super.absorb(other);
  }

  @override
  void goIdle({bool calledByOwner = false}) {
    final owner = _getOwner?.call();
    if (owner != null && owner.hasPrimaryScrollPosition && !calledByOwner) {
      owner.goIdleWithScrollPosition();
    } else {
      beginActivity(IdleScrollActivity(this));
    }
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    return switch (_getOwner?.call()) {
      null => super.hold(holdCancelCallback),
      final owner => owner.holdWithScrollPosition(
          scrollPosition: this,
          holdCancelCallback: holdCancelCallback,
          heldPreviousVelocity: activity!.velocity,
        ),
    };
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    return switch (_getOwner?.call()) {
      null => super.drag(details, dragCancelCallback),
      final owner => owner.dragWithScrollPosition(
          scrollPosition: this,
          dragCancelCallback: dragCancelCallback,
          details: details,
        ),
    };
  }

  @override
  void goBallistic(double velocity, {bool calledByOwner = false}) {
    final owner = _getOwner?.call();
    if (owner != null && owner.hasPrimaryScrollPosition && !calledByOwner) {
      owner.goBallisticWithScrollPosition(
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
      goIdle(calledByOwner: calledByOwner);
    }
  }
}

@internal
class SheetContentScrollController extends ScrollController {
  SheetContentScrollController({
    required this.getOwner,
    super.debugLabel,
    super.initialScrollOffset,
    super.keepScrollOffset,
  });

  final ValueGetter<SheetContentScrollPositionOwner?> getOwner;

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
      physics: physics,
    );
  }

  @override
  void attach(ScrollPosition position) {
    assert(position is SheetContentScrollPosition);
    super.attach(position);
    if (getOwner() case final owner?) {
      owner.addScrollPosition(position as SheetContentScrollPosition);
      position._getOwner = getOwner;
    }
  }

  @override
  void detach(ScrollPosition position) {
    assert(position is SheetContentScrollPosition);
    super.detach(position);
    if (getOwner() case final owner?) {
      owner.removeScrollPosition(position as SheetContentScrollPosition);
      position._getOwner = null;
    }
  }
}

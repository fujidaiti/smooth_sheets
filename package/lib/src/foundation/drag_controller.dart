import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

abstract class SheetDragDelegate {
  AxisDirection get dragAxisDirection;
  void onDragUpdate(double delta);
  void onDragEnd(double velocity);
}

/// Moves a sheet as the user drags their finger across the screen.
@internal
class SheetDragController implements Drag, ScrollActivityDelegate {
  /// Creates an object that scrolls a scroll view as the user drags their
  /// finger across the screen.
  SheetDragController({
    required SheetDragDelegate delegate,
    required DragStartDetails details,
    required VoidCallback onDragCanceled,
    required double? carriedVelocity,
    required double? motionStartDistanceThreshold,
  }) : _delegate = delegate {
    _impl = ScrollDragController(
      delegate: this,
      details: details,
      onDragCanceled: onDragCanceled,
      carriedVelocity: carriedVelocity,
      motionStartDistanceThreshold: motionStartDistanceThreshold,
    );
  }

  // Proxies update(), end(), and cancel() to this object
  // to avoid duplicating the code of ScrollDragController.
  late final ScrollDragController _impl;

  SheetDragDelegate? _delegate;

  void updateDelegate(SheetDragDelegate delegate) {
    _delegate = delegate;
  }

  @override
  void update(DragUpdateDetails details) {
    _impl.update(details);
  }

  @override
  void end(DragEndDetails details) {
    _impl.end(details);
  }

  @override
  void cancel() {
    _impl.cancel();
  }

  // Called by the ScrollDragController in end() and cancel().
  @override
  void goBallistic(double velocity) {
    _delegate!.onDragEnd(-1 * velocity);
  }

  // Called by the ScrollDragController in update().
  @override
  void applyUserOffset(double delta) => _delegate!.onDragUpdate(delta);

  @override
  AxisDirection get axisDirection => _delegate!.dragAxisDirection;

  @override
  void goIdle() {
    assert(false, 'This should never be called.');
  }

  @override
  double setPixels(double pixels) {
    assert(false, 'This should never be called.');
    return 0;
  }

  @mustCallSuper
  void dispose() {
    _delegate = null;
    _impl.dispose();
  }
}

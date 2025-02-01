import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'gesture_proxy.dart';

/// Represents the details of a drag event on a sheet.
sealed class SheetDragDetails {
  /// Const constructor to allow subclasses to be const.
  SheetDragDetails({
    required this.axisDirection,
  });

  /// The direction in which the drag is occurring.
  final VerticalDirection axisDirection;
}

/// Details for the start of a sheet drag.
///
/// Contains information about the starting position and velocity of the drag.
class SheetDragStartDetails extends SheetDragDetails {
  /// Creates details for the start of a sheet drag.
  SheetDragStartDetails({
    required super.axisDirection,
    required this.localPositionX,
    required this.localPositionY,
    required this.globalPositionX,
    required this.globalPositionY,
    this.sourceTimeStamp,
    this.kind,
  });

  /// Recorded timestamp of the source pointer event that
  /// triggered the drag events.
  final Duration? sourceTimeStamp;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  /// The local x position in the coordinate system of the event receiver
  /// at which the pointer contacted the screen.
  final double localPositionX;

  /// The local y position in the coordinate system of the event receiver
  /// at which the pointer contacted the screen.
  final double localPositionY;

  /// The global x position at which the pointer contacted the screen.
  final double globalPositionX;

  /// The global y position at which the pointer contacted the screen.
  final double globalPositionY;

  /// The local position in the coordinate system of the event receiver
  /// at which the pointer contacted the screen.
  Offset get localPosition => _localPosition;

  // Lazily initialized to avoid unnecessary object creation.
  late final _localPosition = Offset(localPositionX, localPositionY);

  /// The global position at which the pointer contacted the screen.
  Offset get globalPosition => _globalPosition;

  // Lazily initialized to avoid unnecessary object creation.
  late final _globalPosition = Offset(globalPositionX, globalPositionY);

  /// Creates a copy of this object but with the given fields
  /// replaced with the new values.
  SheetDragStartDetails copyWith({
    VerticalDirection? axisDirection,
    double? localPositionX,
    double? localPositionY,
    double? globalPositionX,
    double? globalPositionY,
    Duration? sourceTimeStamp,
    PointerDeviceKind? kind,
  }) {
    return SheetDragStartDetails(
      axisDirection: axisDirection ?? this.axisDirection,
      sourceTimeStamp: sourceTimeStamp ?? this.sourceTimeStamp,
      localPositionX: localPositionX ?? this.localPositionX,
      localPositionY: localPositionY ?? this.localPositionY,
      globalPositionX: globalPositionX ?? this.globalPositionX,
      globalPositionY: globalPositionY ?? this.globalPositionY,
      kind: kind ?? this.kind,
    );
  }
}

/// Details about the update of a sheet drag gesture.
///
/// This class contains information about the current state of
/// a sheet drag gesture, such as the position and velocity of the drag.
class SheetDragUpdateDetails extends SheetDragDetails {
  /// Creates details for the update of a sheet drag.
  SheetDragUpdateDetails({
    required super.axisDirection,
    required this.localPositionX,
    required this.localPositionY,
    required this.globalPositionX,
    required this.globalPositionY,
    required this.deltaX,
    required this.deltaY,
    this.sourceTimeStamp,
  });

  /// Recorded timestamp of the source pointer event that
  /// triggered the drag events.
  final Duration? sourceTimeStamp;

  /// The local x position in the coordinate system of the event receiver
  /// at which the pointer contacted the screen.
  final double localPositionX;

  /// The local y position in the coordinate system of the event receiver
  /// at which the pointer contacted the screen.
  final double localPositionY;

  /// The global x position at which the pointer contacted the screen.
  final double globalPositionX;

  /// The global y position at which the pointer contacted the screen.
  final double globalPositionY;

  /// The local position in the coordinate system of the event receiver
  /// at which the pointer contacted the screen.
  Offset get localPosition => _localPosition;

  // Lazily initialized to avoid unnecessary object creation.
  late final _localPosition = Offset(localPositionX, localPositionY);

  /// The global position at which the pointer contacted the screen.
  Offset get globalPosition => _globalPosition;

  // Lazily initialized to avoid unnecessary object creation.
  late final _globalPosition = Offset(globalPositionX, globalPositionY);

  /// The horizontal distance the pointer has moved since the last update.
  final double deltaX;

  /// The vertical distance the pointer has moved since the last update.
  final double deltaY;

  /// The amount the pointer has moved in the coordinate space
  /// of the event receiver since the previous update.
  Offset get delta => _delta;

  // Lazily initialized to avoid unnecessary object creation.
  late final _delta = Offset(deltaX, deltaY);

  /// Creates a copy of this object but with the given fields
  /// replaced with the new values.
  SheetDragUpdateDetails copyWith({
    VerticalDirection? axisDirection,
    Duration? sourceTimeStamp,
    double? localPositionX,
    double? localPositionY,
    double? globalPositionX,
    double? globalPositionY,
    double? deltaX,
    double? deltaY,
  }) {
    return SheetDragUpdateDetails(
      axisDirection: axisDirection ?? this.axisDirection,
      sourceTimeStamp: sourceTimeStamp ?? this.sourceTimeStamp,
      localPositionX: localPositionX ?? this.localPositionX,
      localPositionY: localPositionY ?? this.localPositionY,
      globalPositionX: globalPositionX ?? this.globalPositionX,
      globalPositionY: globalPositionY ?? this.globalPositionY,
      deltaX: deltaX ?? this.deltaX,
      deltaY: deltaY ?? this.deltaY,
    );
  }
}

/// Details for when a sheet drag ends.
///
/// Contains information about the drag end, such as
/// the velocity at which the drag ended.
class SheetDragEndDetails extends SheetDragDetails {
  /// Creates details for the end of a sheet drag.
  SheetDragEndDetails({
    required super.axisDirection,
    required this.velocityX,
    required this.velocityY,
  });

  /// The horizontal velocity at which the pointer was moving
  /// when the drag ended in logical pixels per second.
  final double velocityX;

  /// The vertical velocity at which the pointer was moving
  /// when the drag ended in logical pixels per second.
  final double velocityY;

  /// The velocity the pointer was moving when it stopped contacting the screen.
  Velocity get velocity => _velocity;

  // Lazily initialized to avoid unnecessary object creation.
  late final _velocity = Velocity(
    pixelsPerSecond: Offset(velocityX, velocityY),
  );

  /// Creates a copy of this object but with the given fields
  /// replaced with the new values.
  SheetDragEndDetails copyWith({
    VerticalDirection? axisDirection,
    double? velocityX,
    double? velocityY,
  }) {
    return SheetDragEndDetails(
      axisDirection: axisDirection ?? this.axisDirection,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
    );
  }
}

/// Details for when a sheet drag is canceled.
class SheetDragCancelDetails extends SheetDragDetails {
  /// Creates details for when a sheet drag is canceled.
  SheetDragCancelDetails({required super.axisDirection});
}

@internal
abstract class SheetDragControllerTarget {
  VerticalDirection get dragAxisDirection;

  void onDragUpdate(SheetDragUpdateDetails details);

  void onDragEnd(SheetDragEndDetails details);

  void onDragCancel(SheetDragCancelDetails details);

  /// Returns the minimum number of pixels that the sheet being dragged
  /// will potentially consume for the given drag delta.
  ///
  /// The returned vector must has the same direction as the input [delta],
  /// and its magnitude must be less than or equal to the magnitude of [delta].
  Offset computeMinPotentialDeltaConsumption(Offset delta);
}

/// Handles a drag gesture for a sheet.
@internal
class SheetDragController implements Drag, ScrollActivityDelegate {
  /// Creates an object that scrolls a scroll view as the user drags their
  /// finger across the screen.
  SheetDragController({
    required SheetDragControllerTarget target,
    required SheetDragStartDetails details,
    required VoidCallback onDragCanceled,
    required double? carriedVelocity,
    required double? motionStartDistanceThreshold,
    required this.gestureProxy,
  })  : _target = target,
        _lastDetails = details,
        pointerDeviceKind = details.kind {
    // Actual work is done by this object.
    _impl = ScrollDragController(
      delegate: this,
      onDragCanceled: onDragCanceled,
      carriedVelocity: carriedVelocity,
      motionStartDistanceThreshold: motionStartDistanceThreshold,
      details: DragStartDetails(
        sourceTimeStamp: details.sourceTimeStamp,
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        kind: details.kind,
      ),
    );
  }

  final PointerDeviceKind? pointerDeviceKind;

  /// Proxies [update], [end], and [cancel] to this object
  /// to avoid duplicating the code of [ScrollDragController].
  late final ScrollDragController _impl;

  final SheetDragControllerTarget _target;

  final ValueGetter<SheetGestureProxyMixin?> gestureProxy;

  /// The details of the most recently observed drag event.
  SheetDragDetails get lastDetails => _lastDetails;
  SheetDragDetails _lastDetails;

  /// The most recently observed [DragStartDetails], [DragUpdateDetails], or
  /// [DragEndDetails] object.
  dynamic get lastRawDetails => _impl.lastDetails;

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

  /// Called by the [ScrollDragController] in either [ScrollDragController.end]
  /// or [ScrollDragController.cancel].
  @override
  void goBallistic(double velocity) {
    if (_impl.lastDetails case final DragEndDetails rawDetails) {
      var endDetails = SheetDragEndDetails(
        axisDirection: _target.dragAxisDirection,
        velocityX: rawDetails.velocity.pixelsPerSecond.dx,
        velocityY: -1 * velocity,
      );
      if (gestureProxy() case final proxy?) {
        endDetails = proxy.onDragEnd(endDetails);
      }
      _lastDetails = endDetails;
      _target.onDragEnd(endDetails);
    } else {
      final cancelDetails = SheetDragCancelDetails(
        axisDirection: _target.dragAxisDirection,
      );
      _lastDetails = cancelDetails;
      gestureProxy()?.onDragCancel(cancelDetails);
      _target.onDragCancel(cancelDetails);
    }
  }

  /// Called by the [ScrollDragController] in [Drag.update].
  @override
  void applyUserOffset(double delta) {
    assert(_impl.lastDetails is DragUpdateDetails);
    final rawDetails = _impl.lastDetails as DragUpdateDetails;
    var details = SheetDragUpdateDetails(
      sourceTimeStamp: rawDetails.sourceTimeStamp,
      axisDirection: _target.dragAxisDirection,
      localPositionX: rawDetails.localPosition.dx,
      localPositionY: rawDetails.localPosition.dy,
      globalPositionX: rawDetails.globalPosition.dx,
      globalPositionY: rawDetails.globalPosition.dy,
      deltaX: rawDetails.delta.dx,
      deltaY: delta,
    );

    if (gestureProxy() case final proxy?) {
      final minPotentialDeltaConsumption =
          _target.computeMinPotentialDeltaConsumption(details.delta);
      assert(minPotentialDeltaConsumption.dx.abs() <= details.delta.dx.abs());
      assert(minPotentialDeltaConsumption.dy.abs() <= details.delta.dy.abs());
      details = proxy.onDragUpdate(
        details,
        minPotentialDeltaConsumption,
      );
    }

    _lastDetails = details;
    _target.onDragUpdate(details);
  }

  @override
  AxisDirection get axisDirection {
    return switch (_target.dragAxisDirection) {
      VerticalDirection.up => AxisDirection.up,
      VerticalDirection.down => AxisDirection.down,
    };
  }

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
    _impl.dispose();
  }
}

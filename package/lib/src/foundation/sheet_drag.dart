import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_gesture_tamperer.dart';

/// Represents the details of a drag event on a sheet.
sealed class SheetDragDetails {
  /// Const constructor to allow subclasses to be const.
  const SheetDragDetails({
    required this.axisDirection,
  });

  /// The direction in which the drag is occurring.
  final VerticalDirection axisDirection;
}

/// Details for the start of a sheet drag.
///
/// Contains information about the starting position and velocity of the drag.
class SheetDragStartDetails extends SheetDragDetails
    implements DragStartDetails {
  /// Creates details for the start of a sheet drag.
  const SheetDragStartDetails({
    required super.axisDirection,
    this.sourceTimeStamp,
    required this.globalPosition,
    required this.localPosition,
    this.kind,
  });

  @override
  final Duration? sourceTimeStamp;

  @override
  final Offset globalPosition;

  @override
  final Offset localPosition;

  @override
  final PointerDeviceKind? kind;

  /// Creates a copy of this object but with the given fields
  /// replaced with the new values.
  SheetDragStartDetails copyWith({
    VerticalDirection? axisDirection,
    Duration? sourceTimeStamp,
    Offset? globalPosition,
    Offset? localPosition,
    PointerDeviceKind? kind,
  }) {
    return SheetDragStartDetails(
      axisDirection: axisDirection ?? this.axisDirection,
      sourceTimeStamp: sourceTimeStamp ?? this.sourceTimeStamp,
      globalPosition: globalPosition ?? this.globalPosition,
      localPosition: localPosition ?? this.localPosition,
      kind: kind ?? this.kind,
    );
  }
}

/// Details about the update of a sheet drag gesture.
///
/// This class contains information about the current state of
/// a sheet drag gesture, such as the position and velocity of the drag.
class SheetDragUpdateDetails extends SheetDragDetails
    implements DragUpdateDetails {
  /// Creates details for the update of a sheet drag.
  const SheetDragUpdateDetails({
    required super.axisDirection,
    this.sourceTimeStamp,
    required this.delta,
    required this.primaryDelta,
    required this.globalPosition,
    required this.localPosition,
  });

  @override
  final Duration? sourceTimeStamp;

  @override
  final double primaryDelta;

  @override
  final Offset delta;

  @override
  final Offset globalPosition;

  @override
  final Offset localPosition;

  /// Creates a copy of this object but with the given fields
  /// replaced with the new values.
  SheetDragUpdateDetails copyWith({
    VerticalDirection? axisDirection,
    Duration? sourceTimeStamp,
    double? primaryDelta,
    Offset? delta,
    Offset? globalPosition,
    Offset? localPosition,
    Offset? potentialMinDeltaConsumption,
  }) {
    return SheetDragUpdateDetails(
      axisDirection: axisDirection ?? this.axisDirection,
      sourceTimeStamp: sourceTimeStamp ?? this.sourceTimeStamp,
      primaryDelta: primaryDelta ?? this.primaryDelta,
      delta: delta ?? this.delta,
      globalPosition: globalPosition ?? this.globalPosition,
      localPosition: localPosition ?? this.localPosition,
    );
  }
}

/// Details for when a sheet drag ends.
///
/// Contains information about the drag end, such as
/// the velocity at which the drag ended.
class SheetDragEndDetails extends SheetDragDetails implements DragEndDetails {
  /// Creates details for the end of a sheet drag.
  const SheetDragEndDetails({
    required super.axisDirection,
    required this.velocity,
    required this.primaryVelocity,
    required this.localPosition,
    required this.globalPosition,
  });

  @override
  final Velocity velocity;

  @override
  final double primaryVelocity;

  @override
  final Offset localPosition;

  @override
  final Offset globalPosition;

  /// Creates a copy of this object but with the given fields
  /// replaced with the new values.
  SheetDragEndDetails copyWith({
    VerticalDirection? axisDirection,
    Velocity? velocity,
    double? primaryVelocity,
    Offset? localPosition,
    Offset? globalPosition,
  }) {
    return SheetDragEndDetails(
      axisDirection: axisDirection ?? this.axisDirection,
      velocity: velocity ?? this.velocity,
      primaryVelocity: primaryVelocity ?? this.primaryVelocity,
      localPosition: localPosition ?? this.localPosition,
      globalPosition: globalPosition ?? this.globalPosition,
    );
  }
}

@internal
abstract class SheetDragControllerTarget {
  VerticalDirection get dragAxisDirection;
  void applyUserDragUpdate(Offset offset);
  void applyUserDragEnd(Velocity velocity);

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
    required SheetGestureTamperer? gestureTamperer,
    required SheetDragStartDetails details,
    required VoidCallback onDragCanceled,
    required double? carriedVelocity,
    required double? motionStartDistanceThreshold,
  })  : _target = target,
        _gestureTamperer = gestureTamperer,
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

  SheetDragControllerTarget? _target;
  SheetGestureTamperer? _gestureTamperer;

  SheetDragDetails _lastDetails;
  SheetDragDetails get lastDetails => _lastDetails;

  void updateTarget(SheetDragControllerTarget delegate) {
    _target = delegate;
  }

  void updateGestureTamperer(SheetGestureTamperer? gestureTamperer) {
    _gestureTamperer = gestureTamperer;
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

  /// Called by the [ScrollDragController] in [Drag.end] and [Drag.cancel].
  @override
  void goBallistic(double velocity) {
    assert(_impl.lastDetails is DragEndDetails);
    final rawDetails = _impl.lastDetails as DragEndDetails;
    var details = SheetDragEndDetails(
      axisDirection: _target!.dragAxisDirection,
      localPosition: rawDetails.localPosition,
      globalPosition: rawDetails.globalPosition,
      primaryVelocity: -1 * velocity,
      velocity: Velocity(
        pixelsPerSecond: Offset(
          rawDetails.velocity.pixelsPerSecond.dx,
          -1 * velocity,
        ),
      ),
    );

    if (_gestureTamperer case final tamper?) {
      details = tamper.tamperWithDragEnd(details);
    }

    _lastDetails = details;
    _target!.applyUserDragEnd(details.velocity);
  }

  /// Called by the [ScrollDragController] in [Drag.update].
  @override
  void applyUserOffset(double delta) {
    assert(_impl.lastDetails is DragUpdateDetails);
    final rawDetails = _impl.lastDetails as DragUpdateDetails;
    var details = SheetDragUpdateDetails(
      axisDirection: _target!.dragAxisDirection,
      delta: Offset(rawDetails.delta.dx, delta),
      primaryDelta: delta,
      sourceTimeStamp: rawDetails.sourceTimeStamp,
      globalPosition: rawDetails.globalPosition,
      localPosition: rawDetails.localPosition,
    );

    if (_gestureTamperer case final tamper?) {
      final minPotentialDeltaConsumption =
          _target!.computeMinPotentialDeltaConsumption(details.delta);
      assert(minPotentialDeltaConsumption.dx.abs() <= details.delta.dx.abs());
      assert(minPotentialDeltaConsumption.dy.abs() <= details.delta.dy.abs());
      details = tamper.tamperWithDragUpdate(
        details,
        minPotentialDeltaConsumption,
      );
    }

    _lastDetails = details;
    _target!.applyUserDragUpdate(details.delta);
  }

  @override
  AxisDirection get axisDirection {
    return switch (_target!.dragAxisDirection) {
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
    _target = null;
    _gestureTamperer = null;
    _impl.dispose();
  }
}

// ignore_for_file: omit_local_variable_types, prefer_int_literals, comment_references, lines_longer_than_80_chars, unused_element

/*

 Copied and modified from:
 - https://github.com/flutter/flutter/blob/9e1c857886/packages/flutter/lib/src/gestures/monodrag.dart#L23
 - https://github.com/flutter/flutter/blob/9e1c857886/packages/flutter/lib/src/gestures/monodrag.dart#L70
 - https://github.com/flutter/flutter/blob/9e1c857886/packages/flutter/lib/src/gestures/monodrag.dart#L603
 
 Changes done:
 - Rename `DragGestureRecognizer` to `_DragGestureRecognizer`.
 - Add `globalDistanceMoved` getter to `_DragGestureRecognizer`.
 - Make `_DragGestureRecognizer.hasSufficientGlobalDistanceToAccept` public.
 
 ====================================================================================
 
 Copyright 2014 The Flutter Authors. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above
       copyright notice, this list of conditions and the following
       disclaimer in the documentation and/or other materials provided
       with the distribution.
     * Neither the name of Google Inc. nor the names of its
       contributors may be used to endorse or promote products derived
       from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 ====================================================================================

 */

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

enum _DragState {
  ready,
  possible,
  accepted,
}

abstract class _DragGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Initialize the object.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  _DragGestureRecognizer({
    super.debugOwner,
    this.dragStartBehavior = DragStartBehavior.start,
    this.velocityTrackerBuilder = _defaultBuilder,
    this.onlyAcceptDragOnThreshold = false,
    super.supportedDevices,
    AllowedButtonsFilter? allowedButtonsFilter,
  }) : super(
            allowedButtonsFilter:
                allowedButtonsFilter ?? _defaultButtonAcceptBehavior);

  static VelocityTracker _defaultBuilder(PointerEvent event) =>
      VelocityTracker.withKind(event.kind);

  // Accept the input if, and only if, [kPrimaryButton] is pressed.
  static bool _defaultButtonAcceptBehavior(int buttons) =>
      buttons == kPrimaryButton;

  /// Configure the behavior of offsets passed to [onStart].
  ///
  /// If set to [DragStartBehavior.start], the [onStart] callback will be called
  /// with the position of the pointer at the time this gesture recognizer won
  /// the arena. If [DragStartBehavior.down], [onStart] will be called with
  /// the position of the first detected down event for the pointer. When there
  /// are no other gestures competing with this gesture in the arena, there's
  /// no difference in behavior between the two settings.
  ///
  /// For more information about the gesture arena:
  /// https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// ## Example:
  ///
  /// A [HorizontalDragGestureRecognizer] and a [VerticalDragGestureRecognizer]
  /// compete with each other. A finger presses down on the screen with
  /// offset (500.0, 500.0), and then moves to position (510.0, 500.0) before
  /// the [HorizontalDragGestureRecognizer] wins the arena. With
  /// [dragStartBehavior] set to [DragStartBehavior.down], the [onStart]
  /// callback will be called with position (500.0, 500.0). If it is
  /// instead set to [DragStartBehavior.start], [onStart] will be called with
  /// position (510.0, 500.0).
  DragStartBehavior dragStartBehavior;

  /// A pointer has contacted the screen with a primary button and might begin
  /// to move.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragDownDetails] object.
  ///
  /// See also:
  ///
  ///  * [allowedButtonsFilter], which decides which button will be allowed.
  ///  * [DragDownDetails], which is passed as an argument to this callback.
  GestureDragDownCallback? onDown;

  /// {@template flutter.gestures.monodrag.DragGestureRecognizer.onStart}
  /// A pointer has contacted the screen with a primary button and has begun to
  /// move.
  /// {@endtemplate}
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragStartDetails] object. The [dragStartBehavior]
  /// determines this position.
  ///
  /// See also:
  ///
  ///  * [allowedButtonsFilter], which decides which button will be allowed.
  ///  * [DragStartDetails], which is passed as an argument to this callback.
  GestureDragStartCallback? onStart;

  /// {@template flutter.gestures.monodrag.DragGestureRecognizer.onUpdate}
  /// A pointer that is in contact with the screen with a primary button and
  /// moving has moved again.
  /// {@endtemplate}
  ///
  /// The distance traveled by the pointer since the last update is provided in
  /// the callback's `details` argument, which is a [DragUpdateDetails] object.
  ///
  /// If this gesture recognizer recognizes movement on a single axis (a
  /// [VerticalDragGestureRecognizer] or [HorizontalDragGestureRecognizer]),
  /// then `details` will reflect movement only on that axis and its
  /// [DragUpdateDetails.primaryDelta] will be non-null.
  /// If this gesture recognizer recognizes movement in all directions
  /// (a [PanGestureRecognizer]), then `details` will reflect movement on
  /// both axes and its [DragUpdateDetails.primaryDelta] will be null.
  ///
  /// See also:
  ///
  ///  * [allowedButtonsFilter], which decides which button will be allowed.
  ///  * [DragUpdateDetails], which is passed as an argument to this callback.
  GestureDragUpdateCallback? onUpdate;

  /// {@template flutter.gestures.monodrag.DragGestureRecognizer.onEnd}
  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving is no longer in contact with the screen and was moving
  /// at a specific velocity when it stopped contacting the screen.
  /// {@endtemplate}
  ///
  /// The velocity is provided in the callback's `details` argument, which is a
  /// [DragEndDetails] object.
  ///
  /// If this gesture recognizer recognizes movement on a single axis (a
  /// [VerticalDragGestureRecognizer] or [HorizontalDragGestureRecognizer]),
  /// then `details` will reflect movement only on that axis and its
  /// [DragEndDetails.primaryVelocity] will be non-null.
  /// If this gesture recognizer recognizes movement in all directions
  /// (a [PanGestureRecognizer]), then `details` will reflect movement on
  /// both axes and its [DragEndDetails.primaryVelocity] will be null.
  ///
  /// See also:
  ///
  ///  * [allowedButtonsFilter], which decides which button will be allowed.
  ///  * [DragEndDetails], which is passed as an argument to this callback.
  GestureDragEndCallback? onEnd;

  /// The pointer that previously triggered [onDown] did not complete.
  ///
  /// See also:
  ///
  ///  * [allowedButtonsFilter], which decides which button will be allowed.
  GestureDragCancelCallback? onCancel;

  /// The minimum distance an input pointer drag must have moved
  /// to be considered a fling gesture.
  ///
  /// This value is typically compared with the distance traveled along the
  /// scrolling axis. If null then [kTouchSlop] is used.
  double? minFlingDistance;

  /// The minimum velocity for an input pointer drag to be considered fling.
  ///
  /// This value is typically compared with the magnitude of fling gesture's
  /// velocity along the scrolling axis. If null then [kMinFlingVelocity]
  /// is used.
  double? minFlingVelocity;

  /// Fling velocity magnitudes will be clamped to this value.
  ///
  /// If null then [kMaxFlingVelocity] is used.
  double? maxFlingVelocity;

  /// Whether the drag threshold should be met before dispatching any drag callbacks.
  ///
  /// The drag threshold is met when the global distance traveled by a pointer has
  /// exceeded the defined threshold on the relevant axis, i.e. y-axis for the
  /// [VerticalDragGestureRecognizer], x-axis for the [HorizontalDragGestureRecognizer],
  /// and the entire plane for [PanGestureRecognizer]. The threshold for both
  /// [VerticalDragGestureRecognizer] and [HorizontalDragGestureRecognizer] are
  /// calculated by [computeHitSlop], while [computePanSlop] is used for
  /// [PanGestureRecognizer].
  ///
  /// If true, the drag callbacks will only be dispatched when this recognizer has
  /// won the arena and the drag threshold has been met.
  ///
  /// If false, the drag callbacks will be dispatched immediately when this recognizer
  /// has won the arena.
  ///
  /// This value defaults to false.
  bool onlyAcceptDragOnThreshold;

  /// Determines the type of velocity estimation method to use for a potential
  /// drag gesture, when a new pointer is added.
  ///
  /// To estimate the velocity of a gesture, [DragGestureRecognizer] calls
  /// [velocityTrackerBuilder] when it starts to track a new pointer in
  /// [addAllowedPointer], and add subsequent updates on the pointer to the
  /// resulting velocity tracker, until the gesture recognizer stops tracking
  /// the pointer. This allows you to specify a different velocity estimation
  /// strategy for each allowed pointer added, by changing the type of velocity
  /// tracker this [GestureVelocityTrackerBuilder] returns.
  ///
  /// If left unspecified the default [velocityTrackerBuilder] creates a new
  /// [VelocityTracker] for every pointer added.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker], a velocity tracker that uses least squares estimation
  ///    on the 20 most recent pointer data samples. It's a well-rounded velocity
  ///    tracker and is used by default.
  ///  * [IOSScrollViewFlingVelocityTracker], a specialized velocity tracker for
  ///    determining the initial fling velocity for a [Scrollable] on iOS, to
  ///    match the native behavior on that platform.
  GestureVelocityTrackerBuilder velocityTrackerBuilder;

  _DragState _state = _DragState.ready;
  late OffsetPair _initialPosition;
  late OffsetPair _pendingDragOffset;
  Duration? _lastPendingEventTimestamp;

  /// When asserts are enabled, returns the last tracked pending event timestamp
  /// for this recognizer.
  ///
  /// Otherwise, returns null.
  ///
  /// This getter is intended for use in framework unit tests. Applications must
  /// not depend on its value.
  @visibleForTesting
  Duration? get debugLastPendingEventTimestamp {
    Duration? lastPendingEventTimestamp;
    assert(() {
      lastPendingEventTimestamp = _lastPendingEventTimestamp;
      return true;
    }());
    return lastPendingEventTimestamp;
  }

  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;
  Matrix4? _lastTransform;

  /// Distance moved in the global coordinate space of the screen in drag direction.
  ///
  /// If drag is only allowed along a defined axis, this value may be negative to
  /// differentiate the direction of the drag.
  late double _globalDistanceMoved;

  @protected
  double get globalDistanceMoved => _globalDistanceMoved;

  /// Determines if a gesture is a fling or not based on velocity.
  ///
  /// A fling calls its gesture end callback with a velocity, allowing the
  /// provider of the callback to respond by carrying the gesture forward with
  /// inertia, for example.
  bool isFlingGesture(VelocityEstimate estimate, PointerDeviceKind kind);

  /// Determines if a gesture is a fling or not, and if so its effective velocity.
  ///
  /// A fling calls its gesture end callback with a velocity, allowing the
  /// provider of the callback to respond by carrying the gesture forward with
  /// inertia, for example.
  DragEndDetails? _considerFling(
      VelocityEstimate estimate, PointerDeviceKind kind);

  Offset _getDeltaForDetails(Offset delta);
  double? _getPrimaryValueFromOffset(Offset value);
  bool hasSufficientGlobalDistanceToAccept(
      PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop);
  bool _hasDragThresholdBeenMet = false;

  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (_initialButtons == null) {
      if (onDown == null &&
          onStart == null &&
          onUpdate == null &&
          onEnd == null &&
          onCancel == null) {
        return false;
      }
    } else {
      // There can be multiple drags simultaneously. Their effects are combined.
      if (event.buttons != _initialButtons) {
        return false;
      }
    }
    return super.isPointerAllowed(event as PointerDownEvent);
  }

  void _addPointer(PointerEvent event) {
    _velocityTrackers[event.pointer] = velocityTrackerBuilder(event);
    if (_state == _DragState.ready) {
      _state = _DragState.possible;
      _initialPosition =
          OffsetPair(global: event.position, local: event.localPosition);
      _pendingDragOffset = OffsetPair.zero;
      _globalDistanceMoved = 0.0;
      _lastPendingEventTimestamp = event.timeStamp;
      _lastTransform = event.transform;
      _checkDown();
    } else if (_state == _DragState.accepted) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (_state == _DragState.ready) {
      _initialButtons = event.buttons;
    }
    _addPointer(event);
  }

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    super.addAllowedPointerPanZoom(event);
    startTrackingPointer(event.pointer, event.transform);
    if (_state == _DragState.ready) {
      _initialButtons = kPrimaryButton;
    }
    _addPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _DragState.ready);
    if (!event.synthesized &&
        (event is PointerDownEvent ||
            event is PointerMoveEvent ||
            event is PointerPanZoomStartEvent ||
            event is PointerPanZoomUpdateEvent)) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer]!;
      if (event is PointerPanZoomStartEvent) {
        tracker.addPosition(event.timeStamp, Offset.zero);
      } else if (event is PointerPanZoomUpdateEvent) {
        tracker.addPosition(event.timeStamp, event.pan);
      } else {
        tracker.addPosition(event.timeStamp, event.localPosition);
      }
    }
    if (event is PointerMoveEvent && event.buttons != _initialButtons) {
      _giveUpPointer(event.pointer);
      return;
    }
    if (event is PointerMoveEvent || event is PointerPanZoomUpdateEvent) {
      final Offset delta = (event is PointerMoveEvent)
          ? event.delta
          : (event as PointerPanZoomUpdateEvent).panDelta;
      final Offset localDelta = (event is PointerMoveEvent)
          ? event.localDelta
          : (event as PointerPanZoomUpdateEvent).localPanDelta;
      final Offset position = (event is PointerMoveEvent)
          ? event.position
          : (event.position + (event as PointerPanZoomUpdateEvent).pan);
      final Offset localPosition = (event is PointerMoveEvent)
          ? event.localPosition
          : (event.localPosition +
              (event as PointerPanZoomUpdateEvent).localPan);
      if (_state == _DragState.accepted) {
        _checkUpdate(
          sourceTimeStamp: event.timeStamp,
          delta: _getDeltaForDetails(localDelta),
          primaryDelta: _getPrimaryValueFromOffset(localDelta),
          globalPosition: position,
          localPosition: localPosition,
        );
      } else {
        _pendingDragOffset += OffsetPair(local: localDelta, global: delta);
        _lastPendingEventTimestamp = event.timeStamp;
        _lastTransform = event.transform;
        final Offset movedLocally = _getDeltaForDetails(localDelta);
        final Matrix4? localToGlobalTransform = event.transform == null
            ? null
            : Matrix4.tryInvert(event.transform!);
        _globalDistanceMoved += PointerEvent.transformDeltaViaPositions(
                    transform: localToGlobalTransform,
                    untransformedDelta: movedLocally,
                    untransformedEndPosition: localPosition)
                .distance *
            (_getPrimaryValueFromOffset(movedLocally) ?? 1).sign;
        if (hasSufficientGlobalDistanceToAccept(
            event.kind, gestureSettings?.touchSlop)) {
          _hasDragThresholdBeenMet = true;
          if (_acceptedActivePointers.contains(event.pointer)) {
            _checkDrag(event.pointer);
          } else {
            resolve(GestureDisposition.accepted);
          }
        }
      }
    }
    if (event is PointerUpEvent ||
        event is PointerCancelEvent ||
        event is PointerPanZoomEndEvent) {
      _giveUpPointer(event.pointer);
    }
  }

  final Set<int> _acceptedActivePointers = <int>{};

  @override
  void acceptGesture(int pointer) {
    assert(!_acceptedActivePointers.contains(pointer));
    _acceptedActivePointers.add(pointer);
    if (!onlyAcceptDragOnThreshold || _hasDragThresholdBeenMet) {
      _checkDrag(pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    _giveUpPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    assert(_state != _DragState.ready);
    switch (_state) {
      case _DragState.ready:
        break;

      case _DragState.possible:
        resolve(GestureDisposition.rejected);
        _checkCancel();

      case _DragState.accepted:
        _checkEnd(pointer);
    }
    _hasDragThresholdBeenMet = false;
    _velocityTrackers.clear();
    _initialButtons = null;
    _state = _DragState.ready;
  }

  void _giveUpPointer(int pointer) {
    stopTrackingPointer(pointer);
    // If we never accepted the pointer, we reject it since we are no longer
    // interested in winning the gesture arena for it.
    if (!_acceptedActivePointers.remove(pointer)) {
      resolvePointer(pointer, GestureDisposition.rejected);
    }
  }

  void _checkDown() {
    if (onDown != null) {
      final DragDownDetails details = DragDownDetails(
        globalPosition: _initialPosition.global,
        localPosition: _initialPosition.local,
      );
      invokeCallback<void>('onDown', () => onDown!(details));
    }
  }

  void _checkDrag(int pointer) {
    if (_state == _DragState.accepted) {
      return;
    }
    _state = _DragState.accepted;
    final OffsetPair delta = _pendingDragOffset;
    final Duration? timestamp = _lastPendingEventTimestamp;
    final Matrix4? transform = _lastTransform;
    final Offset localUpdateDelta;
    switch (dragStartBehavior) {
      case DragStartBehavior.start:
        _initialPosition = _initialPosition + delta;
        localUpdateDelta = Offset.zero;
      case DragStartBehavior.down:
        localUpdateDelta = _getDeltaForDetails(delta.local);
    }
    _pendingDragOffset = OffsetPair.zero;
    _lastPendingEventTimestamp = null;
    _lastTransform = null;
    _checkStart(timestamp, pointer);
    if (localUpdateDelta != Offset.zero && onUpdate != null) {
      final Matrix4? localToGlobal =
          transform != null ? Matrix4.tryInvert(transform) : null;
      final Offset correctedLocalPosition =
          _initialPosition.local + localUpdateDelta;
      final Offset globalUpdateDelta = PointerEvent.transformDeltaViaPositions(
        untransformedEndPosition: correctedLocalPosition,
        untransformedDelta: localUpdateDelta,
        transform: localToGlobal,
      );
      final OffsetPair updateDelta =
          OffsetPair(local: localUpdateDelta, global: globalUpdateDelta);
      final OffsetPair correctedPosition = _initialPosition + updateDelta;
      _checkUpdate(
        sourceTimeStamp: timestamp,
        delta: localUpdateDelta,
        primaryDelta: _getPrimaryValueFromOffset(localUpdateDelta),
        globalPosition: correctedPosition.global,
        localPosition: correctedPosition.local,
      );
    }
    // This acceptGesture might have been called only for one pointer, instead
    // of all pointers. Resolve all pointers to `accepted`. This won't cause
    // infinite recursion because an accepted pointer won't be accepted again.
    resolve(GestureDisposition.accepted);
  }

  void _checkStart(Duration? timestamp, int pointer) {
    if (onStart != null) {
      final DragStartDetails details = DragStartDetails(
        sourceTimeStamp: timestamp,
        globalPosition: _initialPosition.global,
        localPosition: _initialPosition.local,
        kind: getKindForPointer(pointer),
      );
      invokeCallback<void>('onStart', () => onStart!(details));
    }
  }

  void _checkUpdate({
    Duration? sourceTimeStamp,
    required Offset delta,
    double? primaryDelta,
    required Offset globalPosition,
    Offset? localPosition,
  }) {
    if (onUpdate != null) {
      final DragUpdateDetails details = DragUpdateDetails(
        sourceTimeStamp: sourceTimeStamp,
        delta: delta,
        primaryDelta: primaryDelta,
        globalPosition: globalPosition,
        localPosition: localPosition,
      );
      invokeCallback<void>('onUpdate', () => onUpdate!(details));
    }
  }

  void _checkEnd(int pointer) {
    if (onEnd == null) {
      return;
    }

    final VelocityTracker tracker = _velocityTrackers[pointer]!;
    final VelocityEstimate? estimate = tracker.getVelocityEstimate();

    DragEndDetails? details;
    final String Function() debugReport;
    if (estimate == null) {
      debugReport = () => 'Could not estimate velocity.';
    } else {
      details = _considerFling(estimate, tracker.kind);
      debugReport = (details != null)
          ? () => '$estimate; fling at ${details!.velocity}.'
          : () => '$estimate; judged to not be a fling.';
    }
    details ??= DragEndDetails(primaryVelocity: 0.0);

    invokeCallback<void>('onEnd', () => onEnd!(details!),
        debugReport: debugReport);
  }

  void _checkCancel() {
    if (onCancel != null) {
      invokeCallback<void>('onCancel', onCancel!);
    }
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        EnumProperty<DragStartBehavior>('start behavior', dragStartBehavior));
  }
}

/// Recognizes movement in the vertical direction.
///
/// Used for vertical scrolling.
///
/// See also:
///
///  * [HorizontalDragGestureRecognizer], for a similar recognizer but for
///    horizontal movement.
///  * [MultiDragGestureRecognizer], for a family of gesture recognizers that
///    track each touch point independently.
class VerticalDragGestureRecognizer extends _DragGestureRecognizer {
  /// Create a gesture recognizer for interactions in the vertical axis.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  VerticalDragGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
  });

  @override
  bool isFlingGesture(VelocityEstimate estimate, PointerDeviceKind kind) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance =
        minFlingDistance ?? computeHitSlop(kind, gestureSettings);
    return estimate.pixelsPerSecond.dy.abs() > minVelocity &&
        estimate.offset.dy.abs() > minDistance;
  }

  @override
  DragEndDetails? _considerFling(
      VelocityEstimate estimate, PointerDeviceKind kind) {
    if (!isFlingGesture(estimate, kind)) {
      return null;
    }
    final double maxVelocity = maxFlingVelocity ?? kMaxFlingVelocity;
    final double dy =
        clampDouble(estimate.pixelsPerSecond.dy, -maxVelocity, maxVelocity);
    return DragEndDetails(
      velocity: Velocity(pixelsPerSecond: Offset(0, dy)),
      primaryVelocity: dy,
    );
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
      PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    return _globalDistanceMoved.abs() >
        computeHitSlop(pointerDeviceKind, gestureSettings);
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => Offset(0.0, delta.dy);

  @override
  double _getPrimaryValueFromOffset(Offset value) => value.dy;

  @override
  String get debugDescription => 'vertical drag';
}

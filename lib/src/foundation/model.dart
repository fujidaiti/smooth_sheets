import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'activity.dart';
import 'context.dart';
import 'controller.dart';
import 'drag.dart';
import 'gesture_proxy.dart';
import 'model_scope.dart';
import 'notification.dart';
import 'physics.dart';
import 'snap_grid.dart';

/// An abstract representation of a sheet's position.
///
/// It is used in various contexts by sheets, for example,
/// to define how much of the sheet is initially visible at the first build
/// or to limit the range within which the sheet can be dragged.
///
/// See also:
/// - [RelativeSheetOffset], which defines the position
///   proportionally to the sheet's content height.
/// - [AbsoluteSheetOffset], which defines the position
///   using a fixed value in pixels.
@immutable
abstract interface class SheetOffset {
  /// {@macro AbsoluteSheetOffset}
  const factory SheetOffset.absolute(double value) = AbsoluteSheetOffset;

  /// {@macro RelativeSheetOffset}
  const factory SheetOffset.relative(double factor) = RelativeSheetOffset;

  /// Resolves the position to an actual value in pixels.
  double resolve(SheetMeasurements measurements);
}

/// A [SheetOffset] that represents a position proportional
/// to the content height of the sheet.
class RelativeSheetOffset implements SheetOffset {
  /// {@template RelativeSheetOffset}
  /// Creates an anchor that positions the sheet
  /// proportionally to its content height.
  ///
  /// The [factor] must be greater than or equal to 0.
  /// This anchor resolves to `contentSize.height * factor`.
  /// For example, `RelativeSheetOffset(0.6)` represents a position
  /// where 60% of the sheet content is visible.
  /// {@endtemplate}
  const RelativeSheetOffset(this.factor) : assert(factor >= 0);

  /// The proportion of the sheet's content height.
  ///
  /// This value is a fraction (e.g., 0.6 for 60% visibility).
  final double factor;

  @override
  double resolve(SheetMeasurements measurements) =>
      measurements.contentSize.height * factor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelativeSheetOffset &&
          runtimeType == other.runtimeType &&
          factor == other.factor);

  @override
  int get hashCode => Object.hash(runtimeType, factor);

  @override
  String toString() => '$RelativeSheetOffset(factor: $factor)';
}

/// A [SheetOffset] that represents a position with a fixed value in pixels.
class AbsoluteSheetOffset implements SheetOffset {
  /// {@template AbsoluteSheetOffset}
  /// Creates an anchor that represents a fixed position in pixels.
  ///
  /// For example, `AbsoluteSheetOffset(200)` represents a position
  /// where 200 pixels from the top of the sheet content are visible.
  /// {@endtemplate}
  const AbsoluteSheetOffset(this.value) : assert(value >= 0);

  /// The position in pixels.
  final double value;

  @override
  double resolve(_) => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AbsoluteSheetOffset &&
          runtimeType == other.runtimeType &&
          value == other.value);

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => '$AbsoluteSheetOffset(value: $value)';
}

/// Read-only view of a [SheetModel].
@internal
abstract class SheetModelView
    with SheetMetrics
    implements ValueListenable<SheetGeometry?> {
  bool get shouldIgnorePointer;

  bool get hasMetrics;
}

/// Manages the position of a sheet.
///
/// This object is much like [ScrollPosition] for scrollable widgets.
/// The [SheetModel.offset] value determines the visible height of a sheet.
/// As this value changes, the sheet translates its position, which changes the
/// visible area of the content. The [SheetModel.minOffset] and
/// [SheetModel.maxOffset] values limit the range of the *pixels*, but it can
/// be outside of the range if the [SheetModel.physics] allows it.
///
/// The current [activity] is responsible for how the *pixels* changes
/// over time, for example, [AnimatedSheetActivity] animates the *pixels* to
/// a target value, and [IdleSheetActivity] keeps the *pixels* unchanged.
/// [SheetModel] starts with [IdleSheetActivity] as the initial activity,
/// and it can be changed by calling [beginActivity].
///
/// This object is a [Listenable] that notifies its listeners when the *pixels*
/// changes, even during build or layout phase. For listeners that can cause
/// any widget to rebuild, consider using [SheetController], which is also
/// [Listenable] of the *pixels*, but avoids notifying listeners during a build.
///
/// See also:
/// - [SheetController], which can be attached to a sheet to observe and control
///   its position.
/// - [SheetPositionScope], which creates a [SheetModel], manages its
///   lifecycle and exposes it to the descendant widgets.
@internal
abstract class SheetModel extends SheetModelView with ChangeNotifier {
  /// Creates an object that manages the position of a sheet.
  SheetModel({
    required this.context,
    required this.initialPosition,
    required SheetPhysics physics,
    required SheetSnapGrid snapGrid,
    this.debugLabel,
    SheetGestureProxyMixin? gestureProxy,
  })  : _physics = physics,
        _snapGrid = snapGrid,
        _gestureProxy = gestureProxy {
    goIdle();
  }

  @override
  SheetGeometry? get value => _geometry;

  SheetGeometry get geometry => _geometry!;
  SheetGeometry? _geometry;

  @protected
  set geometry(SheetGeometry value) {
    if (_geometry != value) {
      _geometry = value;
      notifyListeners();
    }
  }

  @override
  SheetMeasurements get measurements => _measurements!;
  SheetMeasurements? _measurements;

  set measurements(SheetMeasurements value) {
    if (_measurements == value) {
      return;
    }

    final oldMeasurements = _measurements;
    _measurements = value;

    final (minOffset, maxOffset) = snapGrid.getBoundaries(this);
    _boundaries = (minOffset.resolve(value), maxOffset.resolve(value));

    if (oldMeasurements != null) {
      didChangeMeasurements(oldMeasurements);
    } else {
      assert(_geometry == null);
      geometry = SheetGeometry(offset: initialPosition.resolve(value));
    }
  }

  (double, double)? _boundaries;

  @override
  double get maxOffset {
    final (value, _) = _boundaries!;
    return value;
  }

  @override
  double get minOffset {
    final (_, value) = _boundaries!;
    return value;
  }

  @override
  double get offset => geometry.offset;

  @override
  double get devicePixelRatio => context.devicePixelRatio;

  @override
  bool get hasMetrics =>
      _geometry != null && _measurements != null && _boundaries != null;

  @override
  bool get shouldIgnorePointer => activity.shouldIgnorePointer;

  final SheetOffset initialPosition;

  /// A handle to the owner of this object.
  final SheetContext context;

  /// {@template SheetPosition.physics}
  /// How the sheet position should respond to user input.
  ///
  /// This determines how the sheet will behave when over-dragged or
  /// under-dragged, or when the user stops dragging.
  /// {@endtemplate}
  SheetPhysics get physics => _physics;
  SheetPhysics _physics;

  SheetSnapGrid get snapGrid => _snapGrid;
  SheetSnapGrid _snapGrid;

  set snapGrid(SheetSnapGrid snapGrid) {
    _snapGrid = snapGrid;
    final (minOffset, maxOffset) = snapGrid.getBoundaries(this);
    if (_measurements case final it?) {
      _boundaries = (minOffset.resolve(it), maxOffset.resolve(it));
    }
  }

  /// {@template SheetPosition.gestureProxy}
  /// An object that can modify the gesture details of the sheet.
  /// {@endtemplate}
  SheetGestureProxyMixin? get gestureProxy => _gestureProxy;
  SheetGestureProxyMixin? _gestureProxy;

  /// A label that is used to identify this object in debug output.
  final String? debugLabel;

  /// The current activity of the sheet.
  SheetActivity get activity => _activity!;
  SheetActivity? _activity;

  /// The current drag that is currently driving the sheet.
  ///
  /// Intentionally exposed so that a subclass can override
  /// the default implementation of [drag].
  // TODO: Move this to the activity classes.
  @protected
  SheetDragController? currentDrag;

  SheetMetrics get snapshot => SheetMetricsSnapshot(
        offset: offset,
        minOffset: minOffset,
        maxOffset: maxOffset,
        measurements: measurements,
        devicePixelRatio: devicePixelRatio,
      );

  @mustCallSuper
  void takeOver(SheetModel other) {
    assert(currentDrag == null);
    if (other.activity.isCompatibleWith(this)) {
      activity.dispose();
      _activity = other.activity;
      // This is necessary to prevent the activity from being disposed of
      // when `other` is disposed of.
      other._activity = null;
      activity.updateOwner(this);

      if ((other.currentDrag, activity)
          case (final drag?, final SheetDragControllerTarget dragActivity)) {
        currentDrag = drag..updateTarget(dragActivity);
        other.currentDrag = null;
      }
    } else {
      goIdle();
    }
    if (other._geometry case final geometry?) {
      _geometry = geometry;
    }
    if (other._measurements case final measurements?) {
      _measurements = measurements;
    }
  }

  @mustCallSuper
  // TODO: Rename to updateGestureProxy
  void updateGestureProxy(SheetGestureProxyMixin? gestureProxy) {
    if (_gestureProxy != gestureProxy) {
      _gestureProxy = gestureProxy;
      currentDrag?.updateGestureProxy(gestureProxy);
    }
  }

  @mustCallSuper
  // TODO: Convert to a setter.
  void updatePhysics(SheetPhysics physics) {
    _physics = physics;
  }

  @protected
  void didChangeMeasurements(SheetMeasurements oldMeasurements) {}

  @mustCallSuper
  void beginActivity(SheetActivity activity) {
    assert((_activity is SheetDragControllerTarget) == (currentDrag != null));
    currentDrag?.dispose();
    currentDrag = null;

    final oldActivity = _activity;
    // Update the current activity before initialization.
    _activity = activity;
    activity.init(this);
    oldActivity?.dispose();
  }

  void goIdle() {
    beginActivity(IdleSheetActivity());
  }

  void goBallistic(double velocity) {
    final simulation =
        physics.createBallisticSimulation(velocity, this, snapGrid);
    if (simulation != null) {
      goBallisticWith(simulation);
    } else {
      goIdle();
    }
  }

  void goBallisticWith(Simulation simulation) {
    beginActivity(BallisticSheetActivity(simulation: simulation));
  }

  void settleTo(SheetOffset offset, Duration duration) {
    beginActivity(
      SettlingSheetActivity.withDuration(
        duration,
        destination: offset,
      ),
    );
  }

  // TODO: Move this to DraggableScrollableSheetPosition.
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    assert(currentDrag == null);
    final dragActivity = DragSheetActivity();
    var startDetails = SheetDragStartDetails(
      sourceTimeStamp: details.sourceTimeStamp,
      axisDirection: dragActivity.dragAxisDirection,
      localPositionX: details.localPosition.dx,
      localPositionY: details.localPosition.dy,
      globalPositionX: details.globalPosition.dx,
      globalPositionY: details.globalPosition.dy,
      kind: details.kind,
    );
    if (_gestureProxy case final tamperer?) {
      startDetails = tamperer.onDragStart(startDetails);
    }

    final drag = SheetDragController(
      target: dragActivity,
      gestureProxy: _gestureProxy,
      details: startDetails,
      onDragCanceled: dragCancelCallback,
      // TODO: Specify a correct value.
      carriedVelocity: 0,
      motionStartDistanceThreshold: physics.dragStartDistanceMotionThreshold,
    );
    beginActivity(dragActivity);
    currentDrag = drag;
    didDragStart(startDetails);
    return drag;
  }

  @override
  void dispose() {
    _activity?.dispose();
    currentDrag?.dispose();
    _activity = null;
    currentDrag = null;
    super.dispose();
  }

  // TODO: Rename to `setOffset`.
  void setPixels(double pixels) {
    geometry = geometry.copyWith(offset: pixels);
  }

  /// Animates the sheet position to the given value.
  ///
  /// The returned future completes when the animation ends,
  /// whether it completed successfully or whether it was
  /// interrupted prematurely.
  Future<void> animateTo(
    SheetOffset newPosition, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (offset == newPosition.resolve(measurements)) {
      return Future.value();
    } else {
      final activity = AnimatedSheetActivity(
        destination: newPosition,
        duration: duration,
        curve: curve,
      );

      beginActivity(activity);
      return activity.done;
    }
  }

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetMeasurements? measurements,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      measurements: measurements ?? this.measurements,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

  void didUpdateMetrics() {
    SheetUpdateNotification(
      metrics: snapshot,
    ).dispatch(context.notificationContext);
  }

  void didDragStart(SheetDragStartDetails details) {
    SheetDragStartNotification(
      metrics: snapshot,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragEnd(SheetDragEndDetails details) {
    SheetDragEndNotification(
      metrics: snapshot,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragUpdateMetrics(SheetDragUpdateDetails details) {
    SheetDragUpdateNotification(
      metrics: snapshot,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragCancel() {
    SheetDragCancelNotification(
      metrics: snapshot,
    ).dispatch(context.notificationContext);
  }

  void didOverflowBy(double overflow) {
    SheetOverflowNotification(
      metrics: snapshot,
      overflow: overflow,
    ).dispatch(context.notificationContext);
  }
}

/// The metrics of a sheet.
// TODO: Add `baseline` property of type double.
mixin SheetMetrics {
  /// The [FlutterView.devicePixelRatio] of the view that the sheet
  /// associated with this metrics is drawn into.
  double get devicePixelRatio;

  /// Creates a copy of the metrics with the given fields replaced.
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetMeasurements? measurements,
    double? devicePixelRatio,
  });

  /// The current position of the sheet in pixels.
  double get offset;

  /// The minimum position of the sheet in pixels.
  double get minOffset;

  /// The maximum position of the sheet in pixels.
  double get maxOffset;

  SheetMeasurements get measurements;

  /// The visible height of the sheet measured from the bottom of the viewport.
  ///
  /// If the on-screen keyboard is visible, this value is the sum of
  /// [offset] and the keyboard's height. Otherwise, it is equal to [offset].
  double get viewOffset => offset + measurements.viewportInsets.bottom;
}

/// An immutable snapshot of the state of a sheet.
// TODO: Make this private.
@immutable
class SheetMetricsSnapshot with SheetMetrics {
  const SheetMetricsSnapshot({
    required this.offset,
    required this.minOffset,
    required this.maxOffset,
    required this.measurements,
    required this.devicePixelRatio,
  });

  @override
  final double offset;

  @override
  final double minOffset;

  @override
  final double maxOffset;

  @override
  final SheetMeasurements measurements;

  @override
  final double devicePixelRatio;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetMeasurements? measurements,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      measurements: measurements ?? this.measurements,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetMetrics &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          minOffset == other.minOffset &&
          maxOffset == other.maxOffset &&
          measurements == other.measurements &&
          devicePixelRatio == other.devicePixelRatio);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        offset,
        minOffset,
        maxOffset,
        measurements,
        devicePixelRatio,
      );
}

@immutable
class SheetGeometry {
  const SheetGeometry({
    required this.offset,
  });

  final double offset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SheetGeometry && other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        offset,
      );

  SheetGeometry copyWith({
    double? offset,
  }) {
    return SheetGeometry(
      offset: offset ?? this.offset,
    );
  }
}

@immutable
class SheetMeasurements {
  const SheetMeasurements({
    required this.contentSize,
    required this.viewportSize,
    required this.viewportInsets,
  });

  final Size contentSize;
  final Size viewportSize;
  final EdgeInsets viewportInsets;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SheetMeasurements &&
        other.contentSize == contentSize &&
        other.viewportSize == viewportSize &&
        other.viewportInsets == viewportInsets;
  }

  @override
  int get hashCode => Object.hash(
        contentSize,
        viewportSize,
        viewportInsets,
      );

  SheetMeasurements copyWith({
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
  }) {
    return SheetMeasurements(
      contentSize: contentSize ?? this.contentSize,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportInsets: viewportInsets ?? this.viewportInsets,
    );
  }
}

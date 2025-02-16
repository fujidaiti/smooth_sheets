import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'activity.dart';
import 'controller.dart';
import 'drag.dart';
import 'gesture_proxy.dart';
import 'model_owner.dart';
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
  double resolve(Measurements measurements);
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
  double resolve(Measurements measurements) =>
      measurements.contentExtent * factor + measurements.contentBaseline;

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

/// A [SheetOffset] that represents a position with a fixed value in offset.
class AbsoluteSheetOffset implements SheetOffset {
  /// {@template AbsoluteSheetOffset}
  /// Creates an anchor that represents a fixed position in offset.
  ///
  /// For example, `AbsoluteSheetOffset(200)` represents a position
  /// where 200 offset from the top of the sheet content are visible.
  /// {@endtemplate}
  const AbsoluteSheetOffset(this.value) : assert(value >= 0);

  /// The position in offset.
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

/// An interface that provides a set of dependencies
/// required by [SheetModel].
@internal
abstract class SheetContext {
  TickerProvider get vsync;

  BuildContext? get notificationContext;

  double get devicePixelRatio;
}

/// Read-only view of a [SheetModel].
@internal
abstract class SheetModelView with SheetMetrics implements Listenable {
  bool get shouldIgnorePointer;
  bool get hasMetrics;
}

/// Manages the position of a sheet.
///
/// This object is much like [ScrollPosition] for scrollable widgets.
/// The [SheetModel.offset] value determines the visible height of a sheet.
/// As this value changes, the sheet translates its position, which changes the
/// visible area of the content. The [SheetModel.minOffset] and
/// [SheetModel.maxOffset] values limit the range of the *offset*, but it can
/// be outside of the range if the [SheetModel.physics] allows it.
///
/// The current [activity] is responsible for how the *offset* changes
/// over time, for example, [AnimatedSheetActivity] animates the *offset* to
/// a target value, and [IdleSheetActivity] keeps the *offset* unchanged.
/// [SheetModel] starts with [IdleSheetActivity] as the initial activity,
/// and it can be changed by calling [beginActivity].
///
/// This object is a [Listenable] that notifies its listeners when the *offset*
/// changes, even during build or layout phase. For listeners that can cause
/// any widget to rebuild, consider using [SheetController], which is also
/// [Listenable] of the *offset*, but avoids notifying listeners during a build.
///
/// See also:
/// - [SheetController], which can be attached to a sheet to observe and control
///   its position.
/// - [SheetModelOwner], which creates a [SheetModel], manages its
///   lifecycle and exposes it to the descendant widgets.
@internal
abstract class SheetModel extends SheetModelView with ChangeNotifier {
  /// Creates an object that manages the position of a sheet.
  SheetModel({
    required this.context,
    required this.physics,
    required SheetSnapGrid snapGrid,
    this.gestureProxy,
  }) : _snapGrid = snapGrid {
    goIdle();
  }

  @override
  Measurements get measurements => _measurements!;
  Measurements? _measurements;
  set measurements(Measurements value) {
    if (_measurements == value) {
      return;
    }

    final oldMeasurements = _measurements;
    _measurements = value;
    final (minOffset, maxOffset) = snapGrid.getBoundaries(value);
    _minOffset = minOffset.resolve(value);
    _maxOffset = maxOffset.resolve(value);

    if (_offset == null) {
      offset = initialOffset.resolve(value);
    }

    assert(hasMetrics);

    if (oldMeasurements != null) {
      activity.didChangeMeasurements(oldMeasurements);
    }
  }

  @override
  double get maxOffset => _maxOffset!;
  double? _maxOffset;

  @override
  double get minOffset => _minOffset!;
  double? _minOffset;

  @override
  double get offset => _offset!;
  double? _offset;
  set offset(double value) {
    if (value != _offset) {
      _offset = value;
      notifyListeners();
    }
  }

  @override
  double get devicePixelRatio => context.devicePixelRatio;

  @override
  bool get hasMetrics =>
      _measurements != null &&
      _minOffset != null &&
      _maxOffset != null &&
      _offset != null;

  @override
  bool get shouldIgnorePointer => activity.shouldIgnorePointer;

  SheetOffset get initialOffset;

  /// A handle to the owner of this object.
  final SheetContext context;

  /// {@template SheetPosition.physics}
  /// How the sheet position should respond to user input.
  ///
  /// This determines how the sheet will behave when over-dragged or
  /// under-dragged, or when the user stops dragging.
  /// {@endtemplate}
  SheetPhysics physics;

  SheetSnapGrid get snapGrid => _snapGrid;
  SheetSnapGrid _snapGrid;

  set snapGrid(SheetSnapGrid snapGrid) {
    _snapGrid = snapGrid;
    if (hasMetrics) {
      final (minOffset, maxOffset) = snapGrid.getBoundaries(measurements);
      _minOffset = minOffset.resolve(measurements);
      _maxOffset = maxOffset.resolve(measurements);
    }
  }

  /// {@template SheetPosition.gestureProxy}
  /// An object that can modify the gesture details of the sheet.
  /// {@endtemplate}
  SheetGestureProxyMixin? gestureProxy;

  /// The current activity of the sheet.
  @protected
  SheetActivity get activity => _activity!;
  SheetActivity? _activity;

  SheetMetrics get snapshot => SheetMetricsSnapshot(
        offset: offset,
        minOffset: minOffset,
        maxOffset: maxOffset,
        measurements: measurements,
        devicePixelRatio: devicePixelRatio,
      );

  @mustCallSuper
  @protected
  void beginActivity(SheetActivity activity) {
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

  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final dragActivity = DragSheetActivity(
      startDetails: details,
      cancelCallback: dragCancelCallback,
    );
    beginActivity(dragActivity);
    return dragActivity.drag;
  }

  @override
  void dispose() {
    _activity?.dispose();
    _activity = null;
    super.dispose();
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
    Measurements? measurements,
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

  void didUpdateGeometry() {
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
mixin SheetMetrics {
  /// The [FlutterView.devicePixelRatio] of the view that the sheet
  /// associated with this metrics is drawn into.
  double get devicePixelRatio;

  /// Creates a copy of the metrics with the given fields replaced.
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Measurements? measurements,
    double? devicePixelRatio,
  });

  /// The current position of the sheet in pixels.
  double get offset;

  /// The minimum position of the sheet in pixels.
  double get minOffset;

  /// The maximum position of the sheet in pixels.
  double get maxOffset;

  Measurements get measurements;
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
  final Measurements measurements;

  @override
  final double devicePixelRatio;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Measurements? measurements,
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
class Measurements {
  const Measurements({
    required this.viewportExtent,
    required this.contentExtent,
    required this.contentBaseline,
    required this.baseline,
  });

  final double viewportExtent;

  final double contentExtent;

  final double contentBaseline;

  final double baseline;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Measurements &&
        other.viewportExtent == viewportExtent &&
        other.contentExtent == contentExtent &&
        other.contentBaseline == contentBaseline &&
        other.baseline == baseline;
  }

  @override
  int get hashCode => Object.hash(
        contentExtent,
        viewportExtent,
        contentBaseline,
        baseline,
      );

  Measurements copyWith({
    double? contentExtent,
    double? viewportExtent,
    double? contentBaseline,
    double? baseline,
  }) {
    return Measurements(
      contentExtent: contentExtent ?? this.contentExtent,
      viewportExtent: viewportExtent ?? this.viewportExtent,
      contentBaseline: contentBaseline ?? this.contentBaseline,
      baseline: baseline ?? this.baseline,
    );
  }
}

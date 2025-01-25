import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../internal/float_comp.dart';
import 'sheet_activity.dart';
import 'sheet_context.dart';
import 'sheet_controller.dart';
import 'sheet_drag.dart';
import 'sheet_gesture_tamperer.dart';
import 'sheet_notification.dart';
import 'sheet_physics.dart';
import 'sheet_position_scope.dart';
import 'sheet_status.dart';
import 'snap_grid.dart';

/// An abstract representation of a sheet's position.
///
/// It is used in various contexts by sheets, for example,
/// to define how much of the sheet is initially visible at the first build
/// or to limit the range within which the sheet can be dragged.
///
/// See also:
/// - [ProportionalSheetAnchor], which defines the position
///   proportionally to the sheet's content height.
/// - [FixedSheetAnchor], which defines the position
///   using a fixed value in pixels.
// TODO: Rename to SheetOffset.
abstract interface class SheetAnchor {
  /// {@macro FixedSheetAnchor}
  // TODO: Rename to `absolute`.
  const factory SheetAnchor.pixels(double pixels) = FixedSheetAnchor;

  /// {@macro ProportionalSheetAnchor}
  // TODO: Rename to `relative`.
  const factory SheetAnchor.proportional(double size) = ProportionalSheetAnchor;

  /// Resolves the position to an actual value in pixels.
  ///
  /// The [contentSize] parameter should not be cached
  /// as it may change over time.
  double resolve(Size contentSize);
}

/// A [SheetAnchor] that represents a position proportional
/// to the content height of the sheet.
class ProportionalSheetAnchor implements SheetAnchor {
  /// {@template ProportionalSheetAnchor}
  /// Creates an anchor that positions the sheet
  /// proportionally to its content height.
  ///
  /// The [factor] must be greater than or equal to 0.
  /// This anchor resolves to `contentSize.height * factor`.
  /// For example, `ProportionalSheetAnchor(0.6)` represents a position
  /// where 60% of the sheet content is visible.
  /// {@endtemplate}
  const ProportionalSheetAnchor(this.factor) : assert(factor >= 0);

  /// The proportion of the sheet's content height.
  ///
  /// This value is a fraction (e.g., 0.6 for 60% visibility).
  final double factor;

  @override
  double resolve(Size contentSize) => contentSize.height * factor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProportionalSheetAnchor &&
          runtimeType == other.runtimeType &&
          factor == other.factor);

  @override
  int get hashCode => Object.hash(runtimeType, factor);

  @override
  String toString() => '$ProportionalSheetAnchor(factor: $factor)';
}

/// A [SheetAnchor] that represents a position with a fixed value in pixels.
class FixedSheetAnchor implements SheetAnchor {
  /// {@template FixedSheetAnchor}
  /// Creates an anchor that represents a fixed position in pixels.
  ///
  /// For example, `FixedSheetAnchor(200)` represents a position
  /// where 200 pixels from the top of the sheet content are visible.
  /// {@endtemplate}
  const FixedSheetAnchor(this.pixels) : assert(pixels >= 0);

  /// The position in pixels.
  final double pixels;

  @override
  double resolve(Size contentSize) => pixels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixedSheetAnchor &&
          runtimeType == other.runtimeType &&
          pixels == other.pixels);

  @override
  int get hashCode => Object.hash(runtimeType, pixels);

  @override
  String toString() => '$FixedSheetAnchor(pixels: $pixels)';
}

/// Read-only view of a [SheetPosition].
abstract interface class SheetModelView implements ValueListenable<double?> {
  bool get shouldIgnorePointer;
}

// Manages the position of a sheet.
///
/// This object is much like [ScrollPosition] for scrollable widgets.
/// The [SheetPosition.offset] value determines the visible height of a sheet.
/// As this value changes, the sheet translates its position, which changes the
/// visible area of the content. The [SheetPosition.minOffset] and
/// [SheetPosition.maxOffset] values limit the range of the *pixels*, but it can
/// be outside of the range if the [SheetPosition.physics] allows it.
///
/// The current [activity] is responsible for how the *pixels* changes
/// over time, for example, [AnimatedSheetActivity] animates the *pixels* to
/// a target value, and [IdleSheetActivity] keeps the *pixels* unchanged.
/// [SheetPosition] starts with [IdleSheetActivity] as the initial activity,
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
/// - [SheetPositionScope], which creates a [SheetPosition], manages its
///   lifecycle and exposes it to the descendant widgets.
@internal
@optionalTypeArgs
// TODO: Rename to SheetGeometryController.
// ignore: lines_longer_than_80_chars
// TODO: Implement ValueListenable<SheetGeometry> instead of ValueListenable<double?>.
// TODO: Implement SheetModelView.
abstract class SheetPosition extends ChangeNotifier
    with SheetMetrics
    implements SheetModelView {
  /// Creates an object that manages the position of a sheet.
  SheetPosition({
    required this.context,
    required this.initialPosition,
    required SheetPhysics physics,
    required SnapGrid snapGrid,
    this.debugLabel,
    SheetGestureProxyMixin? gestureTamperer,
  })  : _physics = physics,
        _snapGrid = snapGrid,
        _gestureTamperer = gestureTamperer {
    goIdle();
  }

  bool get hasGeometry => _geometry != null;

  SheetGeometry get geometry => _geometry!;
  SheetGeometry? _geometry;

  @protected
  set geometry(SheetGeometry value) {
    if (_geometry != value) {
      _geometry = value;
      notifyListeners();
    }
  }

  SheetMeasurements get measurements => _measurements!;
  SheetMeasurements? _measurements;

  set measurements(SheetMeasurements value) {
    if (_measurements != value) {
      final oldMeasurements = _measurements;
      _measurements = value;
      if (oldMeasurements != null) {
        activity.didChangeDimensions(
          oldContentSize: oldMeasurements.contentSize,
          oldViewportSize: oldMeasurements.viewportSize,
          oldViewportInsets: oldMeasurements.viewportInsets,
        );
      }

      final (minOffset, maxOffset) = snapGrid.getBoundaries(
        copyWith(
          contentSize: value.contentSize,
          viewportSize: value.viewportSize,
          viewportInsets: value.viewportInsets,
        ),
      );

      geometry = SheetGeometry(
        offset: _geometry?.offset ?? initialPosition.resolve(value.contentSize),
        minOffset: minOffset.resolve(value.contentSize),
        maxOffset: maxOffset.resolve(value.contentSize),
      );
    }
  }

  @override
  double? get value => _geometry?.offset;

  @override
  double get offset => geometry.offset;

  @override
  double get maxOffset => geometry.maxOffset;

  @override
  double get minOffset => geometry.minOffset;

  @override
  Size get contentSize => measurements.contentSize;

  @override
  Size get viewportSize => measurements.viewportSize;

  @override
  EdgeInsets get viewportInsets => measurements.viewportInsets;

  @override
  double get devicePixelRatio => context.devicePixelRatio;

  SheetStatus get status => activity.status;

  @override
  bool get shouldIgnorePointer => activity.shouldIgnorePointer;

  final SheetAnchor initialPosition;

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

  SnapGrid get snapGrid => _snapGrid;
  SnapGrid _snapGrid;

  set snapGrid(SnapGrid snapGrid) {
    _snapGrid = snapGrid;
    final (minOffset, maxOffset) = snapGrid.getBoundaries(this);
    geometry = geometry.copyWith(
      minOffset: minOffset.resolve(contentSize),
      maxOffset: maxOffset.resolve(contentSize),
    );
  }

  /// {@template SheetPosition.gestureTamperer}
  /// An object that can modify the gesture details of the sheet.
  /// {@endtemplate}
  SheetGestureProxyMixin? get gestureTamperer => _gestureTamperer;
  SheetGestureProxyMixin? _gestureTamperer;

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
        contentSize: contentSize,
        viewportSize: viewportSize,
        viewportInsets: viewportInsets,
        devicePixelRatio: devicePixelRatio,
      );

  @mustCallSuper
  void takeOver(SheetPosition other) {
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
  void updateGestureTamperer(SheetGestureProxyMixin? gestureTamperer) {
    if (_gestureTamperer != gestureTamperer) {
      _gestureTamperer = gestureTamperer;
      currentDrag?.updateGestureTamperer(gestureTamperer);
    }
  }

  @mustCallSuper
  // TODO: Convert to a setter.
  void updatePhysics(SheetPhysics physics) {
    _physics = physics;
  }

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

  void settleTo(SheetAnchor offset, Duration duration) {
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
    if (_gestureTamperer case final tamperer?) {
      startDetails = tamperer.onDragStart(startDetails);
    }

    final drag = SheetDragController(
      target: dragActivity,
      gestureTamperer: _gestureTamperer,
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
    SheetAnchor newPosition, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (offset == newPosition.resolve(contentSize)) {
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
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      contentSize: contentSize ?? this.contentSize,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportInsets: viewportInsets ?? this.viewportInsets,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

  void didUpdateMetrics() {
    SheetUpdateNotification(
      metrics: snapshot,
      status: status,
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
      status: status,
      overflow: overflow,
    ).dispatch(context.notificationContext);
  }
}

/// The metrics of a sheet.
// TODO: Add `baseline` property of type double.
mixin SheetMetrics {
  /// The [FlutterView.devicePixelRatio] of the view that the sheet
  /// associated with this metrics is drawn into.
  // TODO: Move this to SheetContext.
  double get devicePixelRatio;

  /// Creates a copy of the metrics with the given fields replaced.
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  });

  /// The current position of the sheet in pixels.
  double get offset;

  /// The minimum position of the sheet in pixels.
  double get minOffset;

  /// The maximum position of the sheet in pixels.
  double get maxOffset;

  /// The size of the sheet's content.
  Size get contentSize;

  /// The size of the viewport that hosts the sheet.
  Size get viewportSize;

  EdgeInsets get viewportInsets;

  /// Whether the sheet is within the range of [minOffset] and [maxOffset]
  /// (inclusive of both bounds).
  bool get isPixelsInBounds => FloatComp.distance(devicePixelRatio)
      .isInBounds(offset, minOffset, maxOffset);

  /// Whether the sheet is outside the range of [minOffset] and [maxOffset].
  bool get isPixelsOutOfBounds => !isPixelsInBounds;

  /// The visible height of the sheet measured from the bottom of the viewport.
  ///
  /// If the on-screen keyboard is visible, this value is the sum of
  /// [offset] and the keyboard's height. Otherwise, it is equal to [offset].
  double get viewOffset => offset + viewportInsets.bottom;
}

/// An immutable snapshot of the state of a sheet.
// TODO: Make this private.
@immutable
class SheetMetricsSnapshot with SheetMetrics {
  const SheetMetricsSnapshot({
    required this.offset,
    required this.minOffset,
    required this.maxOffset,
    required this.contentSize,
    required this.viewportSize,
    required this.viewportInsets,
    required this.devicePixelRatio,
  });

  @override
  final double offset;

  @override
  final double minOffset;

  @override
  final double maxOffset;

  @override
  final Size contentSize;

  @override
  final Size viewportSize;

  @override
  final EdgeInsets viewportInsets;

  @override
  final double devicePixelRatio;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      contentSize: contentSize ?? this.contentSize,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportInsets: viewportInsets ?? this.viewportInsets,
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
          contentSize == other.contentSize &&
          viewportSize == other.viewportSize &&
          viewportInsets == other.viewportInsets &&
          devicePixelRatio == other.devicePixelRatio);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        offset,
        minOffset,
        maxOffset,
        contentSize,
        viewportSize,
        viewportInsets,
        devicePixelRatio,
      );
}

@immutable
class SheetGeometry {
  const SheetGeometry({
    required this.offset,
    required this.minOffset,
    required this.maxOffset,
  });

  final double offset;
  final double minOffset;
  final double maxOffset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SheetGeometry &&
        other.offset == offset &&
        other.minOffset == minOffset &&
        other.maxOffset == maxOffset;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        minOffset,
        maxOffset,
      );

  SheetGeometry copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
  }) {
    return SheetGeometry(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
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

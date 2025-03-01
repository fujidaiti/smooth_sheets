import 'dart:math';

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
  double resolve(SheetLayoutMeasurements measurements);
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
  double resolve(SheetLayoutMeasurements measurements) =>
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

@internal
@immutable
abstract class SheetModelConfig {
  const SheetModelConfig({
    required this.physics,
    required this.snapGrid,
    required this.gestureProxy,
  });

  final SheetPhysics physics;
  final SheetSnapGrid snapGrid;
  final SheetGestureProxyMixin? gestureProxy;

  SheetModelConfig copyWith({
    SheetPhysics? physics,
    SheetSnapGrid? snapGrid,
    SheetGestureProxyMixin? gestureProxy,
  });
}

/// Read-only view of a [SheetModel].
@internal
abstract class SheetModelView implements SheetMetrics, Listenable {
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
abstract class SheetModel<C extends SheetModelConfig> extends SheetModelView
    with ChangeNotifier {
  /// Creates an object that manages the position of a sheet.
  SheetModel(this.context, C config) : _config = config {
    goIdle();
  }

  @override
  SheetLayoutMeasurements get measurements => _measurements!;
  SheetLayoutMeasurements? _measurements;
  set measurements(SheetLayoutMeasurements value) {
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

  C get config => _config;
  C _config;

  @mustCallSuper
  set config(C value) {
    final oldConfig = _config;
    _config = value;

    if (value.snapGrid != oldConfig.snapGrid && hasMetrics) {
      final (newMinOffset, newMaxOffset) =
          value.snapGrid.getBoundaries(measurements);
      _minOffset = newMinOffset.resolve(measurements);
      _maxOffset = newMaxOffset.resolve(measurements);
    }
  }

  /// {@template SheetPosition.physics}
  /// How the sheet position should respond to user input.
  ///
  /// This determines how the sheet will behave when over-dragged or
  /// under-dragged, or when the user stops dragging.
  /// {@endtemplate}
  SheetPhysics get physics => config.physics;

  SheetSnapGrid get snapGrid => config.snapGrid;

  /// {@template SheetPosition.gestureProxy}
  /// An object that can modify the gesture details of the sheet.
  /// {@endtemplate}
  SheetGestureProxyMixin? get gestureProxy => config.gestureProxy;

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
      beginActivity(BallisticSheetActivity(simulation: simulation));
    } else {
      goIdle();
    }
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
    SheetLayoutMeasurements? measurements,
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
abstract interface class SheetMetrics {
  /// The current position of the sheet in pixels.
  double get offset;

  /// The minimum position of the sheet in pixels.
  double get minOffset;

  /// The maximum position of the sheet in pixels.
  double get maxOffset;

  /// The [FlutterView.devicePixelRatio] of the view that the sheet
  /// associated with this metrics is drawn into.
  double get devicePixelRatio;

  SheetLayoutMeasurements get measurements;

  /// Creates a copy of the metrics with the given fields replaced.
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetLayoutMeasurements? measurements,
    double? devicePixelRatio,
  });
}

/// An immutable snapshot of the state of a sheet.
@immutable
class SheetMetricsSnapshot implements SheetMetrics {
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
  final SheetLayoutMeasurements measurements;

  @override
  final double devicePixelRatio;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetLayoutMeasurements? measurements,
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

/// Geometry of the viewport and the layout constraints
/// used to lay out the sheet and its content.
@immutable
class SheetLayoutSpec {
  /// Creates a layout specification for the sheet and its content.
  const SheetLayoutSpec({
    required this.viewportSize,
    required this.viewportPadding,
    required this.viewportDynamicOverlap,
    required this.viewportStaticOverlap,
    required this.resizeContentToAvoidBottomOverlap,
  });

  /// {@template SheetLayoutSpec.viewportSize}
  /// The size of the *viewport*, which is the rectangle
  /// where the sheet is laid out.
  /// {@endtemplate}
  final Size viewportSize;

  /// {@template SheetLayoutSpec.viewportPadding}
  /// The padding by which the viewport insets the sheet.
  /// {@endtemplate}
  final EdgeInsets viewportPadding;

  /// {@template SheetLayoutSpec.viewportDynamicOverlap}
  /// The parts of the viewport that are partially overlapped
  /// by system UI elements that may dynamically change in size,
  /// such as the on-screen keyboard.
  /// {@endtemplate}
  final EdgeInsets viewportDynamicOverlap;

  /// {@template SheetLayoutSpec.viewportStaticOverlap}
  /// The parts of the viewport that are partially overlapped
  /// by system UI elements that do not change in size,
  /// such as hardware display notches or the system status bar.
  /// {@endtemplate}
  final EdgeInsets viewportStaticOverlap;

  /// Whether to shrink the sheet's content to avoid
  /// overlapping with the bottom of the viewport,
  /// as described by [viewportDynamicOverlap].
  final bool resizeContentToAvoidBottomOverlap;

  /// {@template SheetLayoutSpec.maxSheetRect}
  /// The maximum rectangle that can be occupied by the sheet.
  ///
  /// The width and the bottom of the rectangle are fixed, so only
  /// the height can be adjusted within the constraint.
  /// {@endtemplate}
  Rect get maxSheetRect => Rect.fromLTRB(
        viewportPadding.left,
        viewportPadding.top,
        viewportSize.width - viewportPadding.right,
        viewportSize.height - viewportPadding.bottom,
      );

  /// The maximum rectangle that can be occupied by the sheet's content.
  ///
  /// This area may be reduced due to the bottom inset of the viewport,
  /// as described by [viewportDynamicOverlap],
  /// if [resizeContentToAvoidBottomOverlap] is true.
  /// Otherwise, it matches [maxSheetRect].
  ///
  /// The width and the bottom of the rectangle are fixed, so only
  /// the height can be adjusted within the constraint.
  Rect get maxContentRect {
    final maxSheetRect = this.maxSheetRect;
    final shrunkRectBottom =
        viewportSize.height - viewportDynamicOverlap.bottom;
    if (resizeContentToAvoidBottomOverlap &&
        shrunkRectBottom < maxSheetRect.bottom) {
      return Rect.fromLTRB(
        maxSheetRect.left,
        maxSheetRect.top,
        maxSheetRect.right,
        shrunkRectBottom,
      );
    } else {
      return maxSheetRect;
    }
  }

  /// The maximum amounts of overlap that each side of the sheet can have
  /// with static system UI elements, such as the system status bar or
  /// hardware display notches.
  EdgeInsets get maxSheetStaticOverlap {
    final maxRect = maxSheetRect;
    final staticSafeArea =
        viewportStaticOverlap.deflateRect(Offset.zero & viewportSize);
    return EdgeInsets.fromLTRB(
      max(staticSafeArea.left - maxRect.left, 0),
      max(staticSafeArea.top - maxRect.top, 0),
      max(maxRect.right - staticSafeArea.right, 0),
      max(maxRect.bottom - staticSafeArea.bottom, 0),
    );
  }

  /// The maximum amounts of overlap that each side of the sheet can have
  /// with dynamic system UI elements, such as the on-screen keyboard.
  EdgeInsets get maxSheetDynamicOverlap {
    final maxRect = maxSheetRect;
    final dynamicSafeArea =
        viewportDynamicOverlap.deflateRect(Offset.zero & viewportSize);
    return EdgeInsets.fromLTRB(
      max(dynamicSafeArea.left - maxRect.left, 0),
      max(dynamicSafeArea.top - maxRect.top, 0),
      max(maxRect.right - dynamicSafeArea.right, 0),
      max(maxRect.bottom - dynamicSafeArea.bottom, 0),
    );
  }

  /// The maximum amounts of overlap that each side of the sheet's content
  /// can have with dynamic system UI elements, such as the on-screen keyboard.
  EdgeInsets get maxContentDynamicOverlap {
    final maxRect = maxContentRect;
    final dynamicSafeArea =
        viewportDynamicOverlap.deflateRect(Offset.zero & viewportSize);
    return EdgeInsets.fromLTRB(
      max(dynamicSafeArea.left - maxRect.left, 0),
      max(dynamicSafeArea.top - maxRect.top, 0),
      max(maxRect.right - dynamicSafeArea.right, 0),
      max(maxRect.bottom - dynamicSafeArea.bottom, 0),
    );
  }

  /// The maximum amounts of overlap that each side of the sheet's content
  /// can have with static system UI elements, such as the system status bar or
  /// hardware display notches.
  EdgeInsets get maxContentStaticOverlap {
    final maxRect = maxContentRect;
    final staticSafeArea =
        viewportStaticOverlap.deflateRect(Offset.zero & viewportSize);
    return EdgeInsets.fromLTRB(
      max(staticSafeArea.left - maxRect.left, 0),
      max(staticSafeArea.top - maxRect.top, 0),
      max(maxRect.right - staticSafeArea.right, 0),
      max(maxRect.bottom - staticSafeArea.bottom, 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SheetLayoutSpec &&
          viewportSize == other.viewportSize &&
          viewportPadding == other.viewportPadding &&
          viewportDynamicOverlap == other.viewportDynamicOverlap &&
          viewportStaticOverlap == other.viewportStaticOverlap &&
          resizeContentToAvoidBottomOverlap ==
              other.resizeContentToAvoidBottomOverlap;

  @override
  int get hashCode => Object.hash(
        viewportSize,
        viewportPadding,
        viewportDynamicOverlap,
        viewportStaticOverlap,
        resizeContentToAvoidBottomOverlap,
      );
}

@immutable
class SheetLayoutMeasurements {
  const SheetLayoutMeasurements({
    required SheetLayoutSpec layoutSpec,
    required this.contentExtent,
  }) : _layoutSpec = layoutSpec;

  final SheetLayoutSpec _layoutSpec;

  // TODO: Rename to `contentHeight`.
  final double contentExtent;

  /// {@macro SheetLayoutSpec.viewportSize}
  Size get viewportSize => _layoutSpec.viewportSize;

  /// {@macro SheetLayoutSpec.viewportPadding}
  EdgeInsets get viewportPadding => _layoutSpec.viewportPadding;

  /// {@macro SheetLayoutSpec.viewportDynamicOverlap}
  EdgeInsets get viewportDynamicOverlap => _layoutSpec.viewportDynamicOverlap;

  /// {@macro SheetLayoutSpec.viewportStaticOverlap}
  EdgeInsets get viewportStaticOverlap => _layoutSpec.viewportStaticOverlap;

  /// The rectangle that bounds the content of the sheet.
  Rect get contentRect {
    final maxContentRect = _layoutSpec.maxContentRect;
    return Rect.fromLTRB(
      maxContentRect.left,
      maxContentRect.bottom - contentExtent,
      maxContentRect.right,
      maxContentRect.bottom,
    );
  }

  /// The minimum height that the sheet can have.
  double get minSheetHeight =>
      max(_layoutSpec.maxSheetRect.bottom - contentRect.top, 0);

  /// The maximum height that the sheet can have.
  double get maxSheetHeight =>
      _layoutSpec.maxSheetRect.size.height;

  // TODO: Remove this field.
  double get baseline =>
      _layoutSpec.viewportSize.height - _layoutSpec.maxSheetRect.bottom;

  /// The distance from the bottom of the viewport to the bottom of the content.
  double get contentBaseline =>
      viewportSize.height - _layoutSpec.maxContentRect.bottom;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SheetLayoutMeasurements &&
        other._layoutSpec == _layoutSpec &&
        other.contentExtent == contentExtent;
  }

  @override
  int get hashCode => Object.hash(_layoutSpec, contentExtent);

  SheetLayoutMeasurements copyWith({
    SheetLayoutSpec? layoutSpec,
    double? contentExtent,
  }) {
    return SheetLayoutMeasurements(
      layoutSpec: layoutSpec ?? _layoutSpec,
      contentExtent: contentExtent ?? this.contentExtent,
    );
  }
}

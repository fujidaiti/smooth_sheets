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
// TODO: Rename to SheetPosition.
abstract interface class SheetAnchor {
  /// {@macro FixedSheetAnchor}
  const factory SheetAnchor.pixels(double pixels) = FixedSheetAnchor;

  /// {@macro ProportionalSheetAnchor}
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

/// Manages the position of a sheet.
///
/// This object is much like [ScrollPosition] for scrollable widgets.
/// The [SheetPosition.pixels] value determines the visible height of a sheet.
/// As this value changes, the sheet translates its position, which changes the
/// visible area of the content. The [SheetPosition.minPixels] and
/// [SheetPosition.maxPixels] values limit the range of the *pixels*, but it can
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
abstract class SheetPosition extends ChangeNotifier
    with SheetMetrics
    implements ValueListenable<double?> {
  /// Creates an object that manages the position of a sheet.
  SheetPosition({
    required this.context,
    required SheetAnchor minPosition,
    required SheetAnchor maxPosition,
    required SheetPhysics physics,
    this.debugLabel,
    SheetGestureProxyMixin? gestureTamperer,
  })  : _physics = physics,
        _gestureTamperer = gestureTamperer,
        _snapshot = SheetMetrics.empty.copyWith(
          minPosition: minPosition,
          maxPosition: maxPosition,
        ) {
    goIdle();
  }

  @override
  double? get value => snapshot.maybePixels;

  @override
  double? get maybePixels => snapshot.maybePixels;

  @override
  SheetAnchor? get maybeMinPosition => snapshot.maybeMinPosition;

  @override
  SheetAnchor? get maybeMaxPosition => snapshot.maybeMaxPosition;

  @override
  Size? get maybeContentSize => snapshot.maybeContentSize;

  @override
  Size? get maybeViewportSize => snapshot.maybeViewportSize;

  @override
  EdgeInsets? get maybeViewportInsets => snapshot.maybeViewportInsets;

  @override
  double get devicePixelRatio => context.devicePixelRatio;

  SheetStatus get status => activity.status;

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
  @protected
  SheetDragController? currentDrag;

  /// Snapshot of the current sheet's state.
  SheetMetrics get snapshot => _snapshot;
  SheetMetrics _snapshot;

  /// Updates the metrics with the given values.
  ///
  /// Use this method instead of directly updating the metrics
  /// to ensure that the [SheetMetrics.devicePixelRatio] is always up-to-date.
  void _updateMetrics({
    double? pixels,
    SheetAnchor? minPosition,
    SheetAnchor? maxPosition,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
  }) {
    _snapshot = SheetMetricsSnapshot(
      pixels: pixels ?? maybePixels,
      minPosition: minPosition ?? maybeMinPosition,
      maxPosition: maxPosition ?? maybeMaxPosition,
      contentSize: contentSize ?? maybeContentSize,
      viewportSize: viewportSize ?? maybeViewportSize,
      viewportInsets: viewportInsets ?? maybeViewportInsets,
      // Ensure that the devicePixelRatio is always up-to-date.
      devicePixelRatio: context.devicePixelRatio,
    );
  }

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
    if (other.maybePixels case final pixels?) {
      correctPixels(pixels);
    }
    applyNewBoundaryConstraints(other.minPosition, other.maxPosition);
    applyNewViewportSize(other.viewportSize);
    applyNewViewportInsets(other.viewportInsets);
    applyNewContentSize(other.contentSize);
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
  void updatePhysics(SheetPhysics physics) {
    _physics = physics;
  }

  @mustCallSuper
  void applyNewContentSize(Size contentSize) {
    if (maybeContentSize != contentSize) {
      _oldContentSize = maybeContentSize;
      _updateMetrics(contentSize: contentSize);
      activity.didChangeContentSize(_oldContentSize);
    }
  }

  @mustCallSuper
  void applyNewViewportSize(Size size) {
    if (maybeViewportSize != size) {
      _oldViewportSize = maybeViewportSize;
      _updateMetrics(viewportSize: size);
      activity.didChangeViewportDimensions(_oldViewportSize);
    }
  }

  @mustCallSuper
  void applyNewViewportInsets(EdgeInsets insets) {
    if (maybeViewportInsets != insets) {
      _oldViewportInsets = maybeViewportInsets;
      _updateMetrics(viewportInsets: insets);
      activity.didChangeViewportInsets(_oldViewportInsets);
    }
  }

  @mustCallSuper
  void applyNewBoundaryConstraints(
    SheetAnchor minPosition,
    SheetAnchor maxPosition,
  ) {
    if (minPosition != this.minPosition || maxPosition != this.maxPosition) {
      final oldMinPosition = maybeMinPosition;
      final oldMaxPosition = maybeMaxPosition;
      _updateMetrics(minPosition: minPosition, maxPosition: maxPosition);
      activity.didChangeBoundaryConstraints(oldMinPosition, oldMaxPosition);
    }
  }

  Size? _oldContentSize;
  Size? _oldViewportSize;
  EdgeInsets? _oldViewportInsets;

  @mustCallSuper
  void finalizePosition() {
    assert(
      hasDimensions,
      _debugMessage(
        'All the dimension values must be finalized '
        'at the time finalizePosition() is called.',
      ),
    );

    _activity!.finalizePosition(
      _oldContentSize,
      _oldViewportSize,
      _oldViewportInsets,
    );

    _oldContentSize = null;
    _oldViewportSize = null;
    _oldViewportInsets = null;
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
    assert(hasDimensions);
    final simulation = physics.createBallisticSimulation(velocity, snapshot);
    if (simulation != null) {
      goBallisticWith(simulation);
    } else {
      goIdle();
    }
  }

  void goBallisticWith(Simulation simulation) {
    beginActivity(BallisticSheetActivity(simulation: simulation));
  }

  void settleTo(SheetAnchor detent, Duration duration) {
    beginActivity(
      SettlingSheetActivity.withDuration(
        duration,
        destination: detent,
      ),
    );
  }

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

  void setPixels(double pixels) {
    final oldPixels = maybePixels;
    correctPixels(pixels);
    if (oldPixels != pixels) {
      notifyListeners();
    }
  }

  void correctPixels(double pixels) {
    if (maybePixels != pixels) {
      _updateMetrics(pixels: pixels);
    }
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
    assert(hasDimensions);
    if (pixels == newPosition.resolve(contentSize)) {
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
    double? pixels,
    SheetAnchor? minPosition,
    SheetAnchor? maxPosition,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return snapshot.copyWith(
      pixels: pixels,
      minPosition: minPosition,
      maxPosition: maxPosition,
      contentSize: contentSize,
      viewportSize: viewportSize,
      viewportInsets: viewportInsets,
      devicePixelRatio: devicePixelRatio,
    );
  }

  void didUpdateMetrics() {
    if (hasDimensions) {
      SheetUpdateNotification(
        metrics: snapshot,
        status: status,
      ).dispatch(context.notificationContext);
    }
  }

  void didDragStart(SheetDragStartDetails details) {
    assert(hasDimensions);
    SheetDragStartNotification(
      metrics: snapshot,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragEnd(SheetDragEndDetails details) {
    assert(hasDimensions);
    SheetDragEndNotification(
      metrics: snapshot,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragUpdateMetrics(SheetDragUpdateDetails details) {
    assert(hasDimensions);
    SheetDragUpdateNotification(
      metrics: snapshot,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragCancel() {
    assert(hasDimensions);
    SheetDragCancelNotification(
      metrics: snapshot,
    ).dispatch(context.notificationContext);
  }

  void didOverflowBy(double overflow) {
    assert(hasDimensions);
    SheetOverflowNotification(
      metrics: snapshot,
      status: status,
      overflow: overflow,
    ).dispatch(context.notificationContext);
  }

  String _debugMessage(String message) {
    return switch (debugLabel) {
      null => message,
      final debugLabel => '$debugLabel: $message',
    };
  }
}

/// The metrics of a sheet.
// TODO: Rename to SheetGeometry.
// TODO: Add `baseline` property of type double.
mixin SheetMetrics {
  /// An empty metrics object with all values set to null.
  static const SheetMetrics empty = SheetMetricsSnapshot(
    pixels: null,
    minPosition: null,
    maxPosition: null,
    contentSize: null,
    viewportSize: null,
    viewportInsets: null,
  );

  double? get maybePixels;

  SheetAnchor? get maybeMinPosition;

  SheetAnchor? get maybeMaxPosition;

  Size? get maybeContentSize;

  Size? get maybeViewportSize;

  EdgeInsets? get maybeViewportInsets;

  /// The [FlutterView.devicePixelRatio] of the view that the sheet
  /// associated with this metrics is drawn into.
  // TODO: Move this to SheetContext.
  double get devicePixelRatio;

  /// Creates a copy of the metrics with the given fields replaced.
  SheetMetrics copyWith({
    double? pixels,
    SheetAnchor? minPosition,
    SheetAnchor? maxPosition,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  });

  double? get maybeMinPixels => switch ((maybeMinPosition, maybeContentSize)) {
        (final minPosition?, final contentSize?) =>
          minPosition.resolve(contentSize),
        _ => null,
      };

  double? get maybeMaxPixels => switch ((maybeMaxPosition, maybeContentSize)) {
        (final maxPosition?, final contentSize?) =>
          maxPosition.resolve(contentSize),
        _ => null,
      };

  /// The current position of the sheet in pixels.
  // TODO: Rename to `offset`.
  double get pixels {
    assert(_debugAssertHasProperty('pixels', maybePixels));
    return maybePixels!;
  }

  /// The minimum position of the sheet in pixels.
  double get minPixels {
    assert(_debugAssertHasProperty('minPixels', maybeMinPixels));
    return maybeMinPixels!;
  }

  /// The maximum position of the sheet in pixels.
  double get maxPixels {
    assert(_debugAssertHasProperty('maxPixels', maybeMaxPixels));
    return maybeMaxPixels!;
  }

  /// The minimum position of the sheet.
  SheetAnchor get minPosition {
    assert(_debugAssertHasProperty('minPosition', maybeMinPosition));
    return maybeMinPosition!;
  }

  /// The maximum position of the sheet.
  SheetAnchor get maxPosition {
    assert(_debugAssertHasProperty('maxPosition', maybeMaxPosition));
    return maybeMaxPosition!;
  }

  /// The size of the sheet's content.
  Size get contentSize {
    assert(_debugAssertHasProperty('contentSize', maybeContentSize));
    return maybeContentSize!;
  }

  /// The size of the viewport that hosts the sheet.
  Size get viewportSize {
    assert(_debugAssertHasProperty('viewportSize', maybeViewportSize));
    return maybeViewportSize!;
  }

  EdgeInsets get viewportInsets {
    assert(_debugAssertHasProperty('viewportInsets', maybeViewportInsets));
    return maybeViewportInsets!;
  }

  /// The visible height of the sheet measured from the bottom of the viewport.
  ///
  /// If the on-screen keyboard is visible, this value is the sum of
  /// [pixels] and the keyboard's height. Otherwise, it is equal to [pixels].
  double get viewPixels => pixels + viewportInsets.bottom;

  double? get maybeViewPixels => hasDimensions ? viewPixels : null;

  /// The minimum visible height of the sheet measured from the bottom
  /// of the viewport.
  double get minViewPixels => minPixels + viewportInsets.bottom;

  double? get maybeMinViewPixels => hasDimensions ? minViewPixels : null;

  /// The maximum visible height of the sheet measured from the bottom
  /// of the viewport.
  double get maxViewPixels => maxPixels + viewportInsets.bottom;

  double? get maybeMaxViewPixels => hasDimensions ? maxViewPixels : null;

  /// Whether the all metrics are available.
  ///
  /// Returns true if all of [maybePixels], [maybeMinPixels], [maybeMaxPixels],
  /// [maybeContentSize], [maybeViewportSize], and [maybeViewportInsets] are not
  /// null.
  bool get hasDimensions =>
      maybePixels != null &&
      maybeMinPosition != null &&
      maybeMaxPosition != null &&
      maybeContentSize != null &&
      maybeViewportSize != null &&
      maybeViewportInsets != null;

  /// Whether the sheet is within the range of [minPixels] and [maxPixels]
  /// (inclusive of both bounds).
  bool get isPixelsInBounds =>
      hasDimensions &&
      FloatComp.distance(devicePixelRatio)
          .isInBounds(pixels, minPixels, maxPixels);

  /// Whether the sheet is outside the range of [minPixels] and [maxPixels].
  bool get isPixelsOutOfBounds => !isPixelsInBounds;

  bool _debugAssertHasProperty(String name, Object? value) {
    assert(() {
      if (value == null) {
        throw FlutterError(
          '$runtimeType.$name cannot be accessed before the value is set. '
          'Consider using the corresponding $runtimeType.maybe* getter '
          'to handle the case when the value is null. $runtimeType.hasPixels '
          'is also useful to check if all the metrics values are set '
          'before accessing them.',
        );
      }
      return true;
    }());
    return true;
  }
}

/// An immutable snapshot of the state of a sheet.
class SheetMetricsSnapshot with SheetMetrics {
  /// Creates an immutable snapshot of the state of a sheet.
  const SheetMetricsSnapshot({
    required double? pixels,
    required SheetAnchor? minPosition,
    required SheetAnchor? maxPosition,
    required Size? contentSize,
    required Size? viewportSize,
    required EdgeInsets? viewportInsets,
    this.devicePixelRatio = 1.0,
  })  : maybePixels = pixels,
        maybeMinPosition = minPosition,
        maybeMaxPosition = maxPosition,
        maybeContentSize = contentSize,
        maybeViewportSize = viewportSize,
        maybeViewportInsets = viewportInsets;

  @override
  final double? maybePixels;

  @override
  final SheetAnchor? maybeMinPosition;

  @override
  final SheetAnchor? maybeMaxPosition;

  @override
  final Size? maybeContentSize;

  @override
  final Size? maybeViewportSize;

  @override
  final EdgeInsets? maybeViewportInsets;

  @override
  final double devicePixelRatio;

  @override
  SheetMetricsSnapshot copyWith({
    double? pixels,
    SheetAnchor? minPosition,
    SheetAnchor? maxPosition,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      pixels: pixels ?? maybePixels,
      minPosition: minPosition ?? maybeMinPosition,
      maxPosition: maxPosition ?? maybeMaxPosition,
      contentSize: contentSize ?? maybeContentSize,
      viewportSize: viewportSize ?? maybeViewportSize,
      viewportInsets: viewportInsets ?? maybeViewportInsets,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetMetrics &&
          runtimeType == other.runtimeType &&
          maybePixels == other.maybePixels &&
          maybeMinPosition == other.maybeMinPosition &&
          maybeMaxPosition == other.maybeMaxPosition &&
          maybeContentSize == other.maybeContentSize &&
          maybeViewportSize == other.maybeViewportSize &&
          maybeViewportInsets == other.maybeViewportInsets &&
          devicePixelRatio == other.devicePixelRatio);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        maybePixels,
        maybeMinPosition,
        maybeMaxPosition,
        maybeContentSize,
        maybeViewportSize,
        maybeViewportInsets,
        devicePixelRatio,
      );

  @override
  String toString() => (
        hasPixels: hasDimensions,
        pixels: maybePixels,
        minPixels: maybeMinPixels,
        maxPixels: maybeMaxPixels,
        viewPixels: maybeViewPixels,
        minViewPixels: maybeMinViewPixels,
        maxViewPixels: maybeMaxViewPixels,
        minPosition: maybeMinPosition,
        maxPosition: maybeMaxPosition,
        contentSize: maybeContentSize,
        viewportSize: maybeViewportSize,
        viewportInsets: maybeViewportInsets,
        devicePixelRatio: devicePixelRatio,
      ).toString();
}

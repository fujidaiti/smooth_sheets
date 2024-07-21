import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../internal/double_utils.dart';
import 'sheet_activity.dart';
import 'sheet_controller.dart';
import 'sheet_drag.dart';
import 'sheet_extent_scope.dart';
import 'sheet_gesture_tamperer.dart';
import 'sheet_notification.dart';
import 'sheet_physics.dart';
import 'sheet_status.dart';

/// A representation of a visible height of the sheet.
///
/// It is used in a variety of situations, for example, to specify
/// how much area of a sheet is initially visible at first build,
/// or to limit the range of sheet dragging.
///
/// See also:
/// - [ProportionalExtent], which is proportional to the content height.
/// - [FixedExtent], which is defined by a concrete value in pixels.
abstract interface class Extent {
  /// {@macro fixed_extent}
  const factory Extent.pixels(double pixels) = FixedExtent;

  /// {@macro proportional_extent}
  const factory Extent.proportional(double size) = ProportionalExtent;

  /// Resolves the extent to a concrete value in pixels.
  ///
  /// Do not cache the value of [contentSize] because
  /// it may change over time.
  double resolve(Size contentSize);
}

/// An extent that is proportional to the content height.
class ProportionalExtent implements Extent {
  /// {@template proportional_extent}
  /// Creates an extent that is proportional to the content height.
  ///
  /// The [factor] must be greater than or equal to 0.
  /// This extent will resolve to `contentSize.height * factor`.
  /// {@endtemplate}
  const ProportionalExtent(this.factor) : assert(factor >= 0);

  /// The fraction of the content height.
  final double factor;

  @override
  double resolve(Size contentSize) => contentSize.height * factor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProportionalExtent &&
          runtimeType == other.runtimeType &&
          factor == other.factor);

  @override
  int get hashCode => Object.hash(runtimeType, factor);
}

/// An extent that has an concrete value in pixels.
class FixedExtent implements Extent {
  /// {@template fixed_extent}
  /// Creates an extent from a concrete value in pixels.
  /// {@endtemplate}
  const FixedExtent(this.pixels) : assert(pixels >= 0);

  /// The value in pixels.
  final double pixels;

  @override
  double resolve(Size contentSize) => pixels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixedExtent &&
          runtimeType == other.runtimeType &&
          pixels == other.pixels);

  @override
  int get hashCode => Object.hash(runtimeType, pixels);
}

/// Manages the extent of a sheet.
///
/// This object is much like [ScrollPosition] for scrollable widgets.
/// The [SheetMetrics.pixels] value determines the visible height of a sheet.
/// As this value changes, the sheet translates its position, which changes the
/// visible area of the content. The [SheetMetrics.minPixels] and
/// [SheetMetrics.maxPixels] values limit the range of the *pixels*, but it can
/// be outside of the range if the [SheetExtent.physics] allows it.
///
/// The current [activity] is responsible for how the *pixels* changes
/// over time, for example, [AnimatedSheetActivity] animates the *pixels* to
/// a target value, and [IdleSheetActivity] keeps the *pixels* unchanged.
/// [SheetExtent] starts with [IdleSheetActivity] as the initial activity,
/// and it can be changed by calling [beginActivity].
///
/// This object is [Listenable] that notifies its listeners when *pixels*
/// changes, even during build or layout phase. For listeners that can cause
/// any widget to rebuild, consider using [SheetController], which is also
/// [Listenable] of the extent, but only notifies its listeners between frames.
///
/// See also:
/// - [SheetController], which can be attached to a sheet to control its extent.
/// - [SheetExtentScope], which creates a [SheetExtent], manages its lifecycle,
///   and exposes it to the descendant widgets.
@internal
@optionalTypeArgs
abstract class SheetExtent extends ChangeNotifier
    implements ValueListenable<SheetMetrics> {
  /// Creates an object that manages the extent of a sheet.
  SheetExtent({
    required this.context,
    required Extent minExtent,
    required Extent maxExtent,
    required SheetPhysics physics,
    this.debugLabel,
    SheetGestureTamperer? gestureTamperer,
  })  : _gestureTamperer = gestureTamperer,
        _minExtent = minExtent,
        _maxExtent = maxExtent,
        _physics = physics {
    goIdle();
  }

  @override
  SheetMetrics get value => metrics;

  SheetStatus get status => activity.status;

  /// A handle to the owner of this object.
  final SheetContext context;

  /// {@template SheetExtent.minExtent}
  /// The minimum extent of the sheet.
  ///
  /// The sheet may below this extent if the [physics] allows it.
  /// {@endtemplate}
  Extent get minExtent => _minExtent;
  Extent _minExtent;

  /// {@template SheetExtent.maxExtent}
  /// The maximum extent of the sheet.
  ///
  /// The sheet may exceed this extent if the [physics] allows it.
  /// {@endtemplate}
  Extent get maxExtent => _maxExtent;
  Extent _maxExtent;

  /// {@template SheetExtent.physics}
  /// How the sheet extent should respond to user input.
  ///
  /// This determines how the sheet will behave when over-dragged or
  /// under-dragged, or when the user stops dragging.
  /// {@endtemplate}
  SheetPhysics get physics => _physics;
  SheetPhysics _physics;

  /// {@template SheetExtent.gestureTamperer}
  /// An object that can modify the gesture details of the sheet.
  /// {@endtemplate}
  SheetGestureTamperer? get gestureTamperer => _gestureTamperer;
  SheetGestureTamperer? _gestureTamperer;

  /// A label that is used to identify this object in debug output.
  final String? debugLabel;

  /// Snapshot of the current sheet's state.
  SheetMetrics get metrics => _metrics;
  SheetMetrics _metrics = SheetMetrics.empty;

  /// The current activity of the sheet.
  SheetActivity get activity => _activity!;
  SheetActivity? _activity;

  /// The current drag that is currently driving the sheet.
  ///
  /// Intentionally exposed so that a subclass can override
  /// the default implementation of [drag].
  @protected
  SheetDragController? currentDrag;

  @mustCallSuper
  void takeOver(SheetExtent other) {
    assert(currentDrag == null);
    if (other.activity.isCompatibleWith(this)) {
      activity.dispose();
      _activity = other.activity;
      // This is necessary to prevent the activity from being disposed of
      // when `other` extent is disposed of.
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
    if (other.metrics.maybePixels case final pixels?) {
      correctPixels(pixels);
    }
    applyNewBoundaryConstraints(other.minExtent, other.maxExtent);
    applyNewViewportDimensions(
      other.metrics.viewportSize,
      other.metrics.viewportInsets,
    );
    applyNewContentSize(other.metrics.contentSize);
  }

  @mustCallSuper
  void updateGestureTamperer(SheetGestureTamperer? gestureTamperer) {
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
    if (metrics.maybeContentSize != contentSize) {
      final oldMaxPixels = metrics.maybeMaxPixels;
      final oldMinPixels = metrics.maybeMinPixels;
      _oldContentSize = metrics.maybeContentSize;
      _metrics = metrics.copyWith(
        contentSize: contentSize,
        minPixels: minExtent.resolve(contentSize),
        maxPixels: maxExtent.resolve(contentSize),
      );
      activity.didChangeContentSize(_oldContentSize);
      if (oldMinPixels != metrics.minPixels ||
          oldMaxPixels != metrics.maxPixels) {
        activity.didChangeBoundaryConstraints(oldMinPixels, oldMaxPixels);
      }
    }
  }

  @mustCallSuper
  void applyNewViewportDimensions(Size size, EdgeInsets insets) {
    if (metrics.maybeViewportSize != size ||
        metrics.maybeViewportInsets != insets) {
      _oldViewportSize = metrics.maybeViewportSize;
      _oldViewportInsets = metrics.maybeViewportInsets;
      _metrics = metrics.copyWith(viewportSize: size, viewportInsets: insets);
      activity.didChangeViewportDimensions(
        _oldViewportSize,
        _oldViewportInsets,
      );
    }
  }

  @mustCallSuper
  void applyNewBoundaryConstraints(Extent minExtent, Extent maxExtent) {
    if (minExtent != _minExtent || maxExtent != _maxExtent) {
      _minExtent = minExtent;
      _maxExtent = maxExtent;
      if (metrics.maybeContentSize case final contentSize?) {
        final newMinPixels = minExtent.resolve(contentSize);
        final newMaxPixels = maxExtent.resolve(contentSize);
        if (newMinPixels != metrics.maybeMinPixels ||
            newMaxPixels != metrics.maybeMaxPixels) {
          final oldMinPixels = metrics.maybeMinPixels;
          final oldMaxPixels = metrics.maybeMaxPixels;
          _metrics = metrics.copyWith(
            minPixels: newMinPixels,
            maxPixels: newMaxPixels,
          );
          activity.didChangeBoundaryConstraints(oldMinPixels, oldMaxPixels);
        }
      }
    }
  }

  Size? _oldContentSize;
  Size? _oldViewportSize;
  EdgeInsets? _oldViewportInsets;
  int _markAsDimensionsWillChangeCallCount = 0;

  @mustCallSuper
  void markAsDimensionsWillChange() {
    assert(() {
      if (_markAsDimensionsWillChangeCallCount == 0) {
        // Ensure that the number of calls to markAsDimensionsWillChange()
        // matches the number of calls to markAsDimensionsChanged().
        WidgetsBinding.instance.addPostFrameCallback((_) {
          assert(
            _markAsDimensionsWillChangeCallCount == 0,
            _markAsDimensionsWillChangeCallCount > 0
                ? _debugMessage(
                    'markAsDimensionsWillChange() was called more times '
                    'than markAsDimensionsChanged() in a frame.',
                  )
                : _debugMessage(
                    'markAsDimensionsChanged() was called more times '
                    'than markAsDimensionsWillChange() in a frame.',
                  ),
          );
        });
      }
      return true;
    }());

    if (_markAsDimensionsWillChangeCallCount == 0) {
      _oldContentSize = null;
      _oldViewportSize = null;
      _oldViewportInsets = null;
    }

    _markAsDimensionsWillChangeCallCount++;
  }

  @mustCallSuper
  void markAsDimensionsChanged() {
    assert(
      _markAsDimensionsWillChangeCallCount > 0,
      _debugMessage(
        'markAsDimensionsChanged() called without '
        'a matching call to markAsDimensionsWillChange().',
      ),
    );

    _markAsDimensionsWillChangeCallCount--;
    if (_markAsDimensionsWillChangeCallCount == 0) {
      onDimensionsFinalized();
    }
  }

  @mustCallSuper
  void onDimensionsFinalized() {
    assert(
      _markAsDimensionsWillChangeCallCount == 0,
      _debugMessage(
        'Do not call this method until all dimensions changes are finalized.',
      ),
    );
    assert(
      metrics.hasDimensions,
      _debugMessage(
        'All the dimension values must be finalized '
        'at the time onDimensionsFinalized() is called.',
      ),
    );

    _activity!.didFinalizeDimensions(
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
    final oldActivity = _activity;
    // Update the current activity before initialization.
    _activity = activity;
    activity.init(this);

    if (oldActivity == null) {
      return;
    }

    final wasDragging = oldActivity.status == SheetStatus.dragging;
    final isDragging = activity.status == SheetStatus.dragging;

    // TODO: Make more typesafe
    assert(() {
      final wasActuallyDragging =
          currentDrag != null && oldActivity is SheetDragControllerTarget;
      final isActuallyDragging =
          currentDrag != null && activity is SheetDragControllerTarget;
      return wasDragging == wasActuallyDragging &&
          isDragging == isActuallyDragging;
    }());

    if (wasDragging && isDragging) {
      currentDrag!.updateTarget(activity as SheetDragControllerTarget);
    } else if (wasDragging && !isDragging) {
      currentDrag!.dispose();
      currentDrag = null;
    }

    oldActivity.dispose();
  }

  void goIdle() {
    beginActivity(IdleSheetActivity());
  }

  void goBallistic(double velocity) {
    assert(metrics.hasDimensions);
    final simulation = physics.createBallisticSimulation(velocity, metrics);
    if (simulation != null) {
      goBallisticWith(simulation);
    } else {
      goIdle();
    }
  }

  void goBallisticWith(Simulation simulation) {
    beginActivity(BallisticSheetActivity(simulation: simulation));
  }

  void settle() {
    assert(metrics.hasDimensions);
    final simulation = physics.createSettlingSimulation(metrics);
    if (simulation != null) {
      // TODO: Begin a SettlingSheetActivity
      goBallisticWith(simulation);
    } else {
      goIdle();
    }
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
      startDetails = tamperer.tamperWithDragStart(startDetails);
    }

    final drag = currentDrag = SheetDragController(
      target: dragActivity,
      gestureTamperer: _gestureTamperer,
      details: startDetails,
      onDragCanceled: dragCancelCallback,
      // TODO: Specify a correct value.
      carriedVelocity: 0,
      motionStartDistanceThreshold: physics.dragStartDistanceMotionThreshold,
    );
    beginActivity(dragActivity);
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
    final oldPixels = metrics.maybePixels;
    correctPixels(pixels);
    if (oldPixels != pixels) {
      notifyListeners();
    }
  }

  void correctPixels(double pixels) {
    if (metrics.maybePixels != pixels) {
      _metrics = metrics.copyWith(pixels: pixels);
    }
  }

  /// Animates the extent to the given value.
  ///
  /// The returned future completes when the animation ends,
  /// whether it completed successfully or whether it was
  /// interrupted prematurely.
  Future<void> animateTo(
    Extent newExtent, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    assert(metrics.hasDimensions);
    if (metrics.pixels == newExtent.resolve(metrics.contentSize)) {
      return Future.value();
    } else {
      final activity = AnimatedSheetActivity(
        destination: newExtent,
        duration: duration,
        curve: curve,
      );

      beginActivity(activity);
      return activity.done;
    }
  }

  void didUpdateMetrics() {
    if (metrics.hasDimensions) {
      SheetUpdateNotification(
        metrics: metrics,
        status: status,
      ).dispatch(context.notificationContext);
    }
  }

  void didDragStart(SheetDragStartDetails details) {
    assert(metrics.hasDimensions);
    SheetDragStartNotification(
      metrics: metrics,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragEnd(SheetDragEndDetails details) {
    assert(metrics.hasDimensions);
    SheetDragEndNotification(
      metrics: metrics,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragUpdateMetrics(SheetDragUpdateDetails details) {
    assert(metrics.hasDimensions);
    SheetDragUpdateNotification(
      metrics: metrics,
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragCancel() {
    assert(metrics.hasDimensions);
    SheetDragCancelNotification(
      metrics: metrics,
    ).dispatch(context.notificationContext);
  }

  void didOverflowBy(double overflow) {
    assert(metrics.hasDimensions);
    SheetOverflowNotification(
      metrics: metrics,
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

/// An immutable snapshot of the sheet's state.
class SheetMetrics {
  /// Creates an immutable snapshot of the sheet's state.
  const SheetMetrics({
    required double? pixels,
    required double? minPixels,
    required double? maxPixels,
    required Size? contentSize,
    required Size? viewportSize,
    required EdgeInsets? viewportInsets,
  })  : maybePixels = pixels,
        maybeMinPixels = minPixels,
        maybeMaxPixels = maxPixels,
        maybeContentSize = contentSize,
        maybeViewportSize = viewportSize,
        maybeViewportInsets = viewportInsets;

  static const empty = SheetMetrics(
    pixels: null,
    minPixels: null,
    maxPixels: null,
    contentSize: null,
    viewportSize: null,
    viewportInsets: null,
  );

  final double? maybePixels;
  final double? maybeMinPixels;
  final double? maybeMaxPixels;
  final Size? maybeContentSize;
  final Size? maybeViewportSize;
  final EdgeInsets? maybeViewportInsets;

  /// The current extent of the sheet.
  double get pixels {
    assert(_debugAssertHasProperty('pixels', maybePixels));
    return maybePixels!;
  }

  /// The minimum extent of the sheet.
  double get minPixels {
    assert(_debugAssertHasProperty('minPixels', maybeMinPixels));
    return maybeMinPixels!;
  }

  /// The maximum extent of the sheet.
  double get maxPixels {
    assert(_debugAssertHasProperty('maxPixels', maybeMaxPixels));
    return maybeMaxPixels!;
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
  /// Returns true if all of [pixels], [minPixels], [maxPixels],
  /// [contentSize], [viewportInsets], and [viewportSize] are not null.
  bool get hasDimensions =>
      maybePixels != null &&
      maybeMinPixels != null &&
      maybeMaxPixels != null &&
      maybeContentSize != null &&
      maybeViewportSize != null &&
      maybeViewportInsets != null;

  /// Whether the sheet is within the range of [minPixels] and [maxPixels]
  /// (inclusive of both bounds).
  bool get isPixelsInBounds =>
      hasDimensions && pixels.isInBounds(minPixels, maxPixels);

  /// Whether the sheet is outside the range of [minPixels] and [maxPixels].
  bool get isPixelsOutOfBounds => !isPixelsInBounds;

  bool _debugAssertHasProperty(String name, Object? value) {
    assert(() {
      if (value == null) {
        throw FlutterError(
          'SheetMetrics.$name cannot be accessed before the value is set. '
          'Consider using the corresponding SheetMetrics.maybe* getter '
          'to handle the case when the value is null. SheetMetrics.hasPixels '
          'is also useful to check if all the metrics values are set '
          'before accessing them.',
        );
      }
      return true;
    }());
    return true;
  }

  /// Creates a copy of this object with the given fields replaced.
  SheetMetrics copyWith({
    SheetStatus? status,
    double? pixels,
    double? minPixels,
    double? maxPixels,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
  }) {
    return SheetMetrics(
      pixels: pixels ?? maybePixels,
      minPixels: minPixels ?? maybeMinPixels,
      maxPixels: maxPixels ?? maybeMaxPixels,
      contentSize: contentSize ?? maybeContentSize,
      viewportSize: viewportSize ?? maybeViewportSize,
      viewportInsets: viewportInsets ?? maybeViewportInsets,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetMetrics &&
          runtimeType == other.runtimeType &&
          maybePixels == other.pixels &&
          maybeMinPixels == other.minPixels &&
          maybeMaxPixels == other.maxPixels &&
          maybeContentSize == other.contentSize &&
          maybeViewportSize == other.viewportSize &&
          maybeViewportInsets == other.viewportInsets);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        maybePixels,
        maybeMinPixels,
        maybeMaxPixels,
        maybeContentSize,
        maybeViewportSize,
        maybeViewportInsets,
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
        contentSize: maybeContentSize,
        viewportSize: maybeViewportSize,
        viewportInsets: maybeViewportInsets,
      ).toString();
}

/// An interface that provides the necessary context to a [SheetExtent].
///
/// Typically, [State]s that host a [SheetExtent] will implement this interface.
@internal
abstract class SheetContext {
  TickerProvider get vsync;
  BuildContext? get notificationContext;
}

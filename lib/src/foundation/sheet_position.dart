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
import 'sheet_extent_scope.dart';
import 'sheet_gesture_tamperer.dart';
import 'sheet_notification.dart';
import 'sheet_physics.dart';
import 'sheet_status.dart';

/// Abstracted representation of a sheet position.
///
/// It is used in a variety of situations by sheets, for example,
/// to specify how much area of a sheet is initially visible at first build,
/// or to limit the range of sheet dragging.
///
/// See also:
/// - [ProportionalSheetAnchor], which is proportional to the content height.
/// - [FixedExtent], which is defined by a concrete value in pixels.
abstract interface class SheetAnchor {
  /// {@macro fixed_extent}
  const factory SheetAnchor.pixels(double pixels) = FixedExtent;

  /// {@macro proportional_extent}
  const factory SheetAnchor.proportional(double size) = ProportionalSheetAnchor;

  /// Resolves the extent to a concrete value in pixels.
  ///
  /// Do not cache the value of [contentSize] because
  /// it may change over time.
  double resolve(Size contentSize);
}

/// An [SheetAnchor] that is proportional to the content height.
class ProportionalSheetAnchor implements SheetAnchor {
  /// {@template proportional_extent}
  /// Creates an extent that is proportional to the content height.
  ///
  /// The [factor] must be greater than or equal to 0.
  /// This extent will resolve to `contentSize.height * factor`.
  /// {@endtemplate}
  const ProportionalSheetAnchor(this.factor) : assert(factor >= 0);

  /// The fraction of the content height.
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

/// An extent that has an concrete value in pixels.
class FixedExtent implements SheetAnchor {
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

  @override
  String toString() => '$FixedExtent(pixels: $pixels)';
}

/// Manages the extent of a sheet.
///
/// This object is much like [ScrollPosition] for scrollable widgets.
/// The [SheetMetrics.pixels] value determines the visible height of a sheet.
/// As this value changes, the sheet translates its position, which changes the
/// visible area of the content. The [SheetMetrics.minPixels] and
/// [SheetMetrics.maxPixels] values limit the range of the *pixels*, but it can
/// be outside of the range if the [SheetPosition.physics] allows it.
///
/// The current [activity] is responsible for how the *pixels* changes
/// over time, for example, [AnimatedSheetActivity] animates the *pixels* to
/// a target value, and [IdleSheetActivity] keeps the *pixels* unchanged.
/// [SheetPosition] starts with [IdleSheetActivity] as the initial activity,
/// and it can be changed by calling [beginActivity].
///
/// This object is [Listenable] that notifies its listeners when *pixels*
/// changes, even during build or layout phase. For listeners that can cause
/// any widget to rebuild, consider using [SheetController], which is also
/// [Listenable] of the extent, but only notifies its listeners between frames.
///
/// See also:
/// - [SheetController], which can be attached to a sheet to control its extent.
/// - [SheetExtentScope], which creates a [SheetPosition], manages its lifecycle
///   and exposes it to the descendant widgets.
@internal
@optionalTypeArgs
abstract class SheetPosition extends ChangeNotifier
    with SheetMetrics
    implements ValueListenable<double?> {
  /// Creates an object that manages the extent of a sheet.
  SheetPosition({
    required this.context,
    required SheetAnchor minExtent,
    required SheetAnchor maxExtent,
    required SheetPhysics physics,
    this.debugLabel,
    SheetGestureProxyMixin? gestureTamperer,
  })  : _physics = physics,
        _gestureTamperer = gestureTamperer,
        _snapshot = SheetMetrics.empty.copyWith(
          minExtent: minExtent,
          maxExtent: maxExtent,
        ) {
    goIdle();
  }

  @override
  double? get value => snapshot.maybePixels;

  @override
  double? get maybePixels => snapshot.maybePixels;

  @override
  SheetAnchor? get maybeMinExtent => snapshot.maybeMinExtent;

  @override
  SheetAnchor? get maybeMaxExtent => snapshot.maybeMaxExtent;

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
    SheetAnchor? minExtent,
    SheetAnchor? maxExtent,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
  }) {
    _snapshot = SheetMetricsSnapshot(
      pixels: pixels ?? maybePixels,
      minExtent: minExtent ?? maybeMinExtent,
      maxExtent: maxExtent ?? maybeMaxExtent,
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
    if (other.maybePixels case final pixels?) {
      correctPixels(pixels);
    }
    applyNewBoundaryConstraints(other.minExtent, other.maxExtent);
    applyNewViewportDimensions(
      other.viewportSize,
      other.viewportInsets,
    );
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
  void applyNewViewportDimensions(Size size, EdgeInsets insets) {
    if (maybeViewportSize != size || maybeViewportInsets != insets) {
      _oldViewportSize = maybeViewportSize;
      _oldViewportInsets = maybeViewportInsets;
      _updateMetrics(viewportSize: size, viewportInsets: insets);
      activity.didChangeViewportDimensions(
        _oldViewportSize,
        _oldViewportInsets,
      );
    }
  }

  @mustCallSuper
  void applyNewBoundaryConstraints(
      SheetAnchor minExtent, SheetAnchor maxExtent) {
    if (minExtent != this.minExtent || maxExtent != this.maxExtent) {
      final oldMinExtent = maybeMinExtent;
      final oldMaxExtent = maybeMaxExtent;
      _updateMetrics(minExtent: minExtent, maxExtent: maxExtent);
      activity.didChangeBoundaryConstraints(oldMinExtent, oldMaxExtent);
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
      hasDimensions,
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

  /// Animates the extent to the given value.
  ///
  /// The returned future completes when the animation ends,
  /// whether it completed successfully or whether it was
  /// interrupted prematurely.
  Future<void> animateTo(
    SheetAnchor newExtent, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    assert(hasDimensions);
    if (pixels == newExtent.resolve(contentSize)) {
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

  @override
  SheetMetrics copyWith({
    double? pixels,
    SheetAnchor? minExtent,
    SheetAnchor? maxExtent,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return snapshot.copyWith(
      pixels: pixels,
      minExtent: minExtent,
      maxExtent: maxExtent,
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
mixin SheetMetrics {
  /// An empty metrics object with all values set to null.
  static const SheetMetrics empty = SheetMetricsSnapshot(
    pixels: null,
    minExtent: null,
    maxExtent: null,
    contentSize: null,
    viewportSize: null,
    viewportInsets: null,
  );

  double? get maybePixels;
  SheetAnchor? get maybeMinExtent;
  SheetAnchor? get maybeMaxExtent;
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
    SheetAnchor? minExtent,
    SheetAnchor? maxExtent,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  });

  double? get maybeMinPixels => switch ((maybeMinExtent, maybeContentSize)) {
        (final minExtent?, final contentSize?) =>
          minExtent.resolve(contentSize),
        _ => null,
      };

  double? get maybeMaxPixels => switch ((maybeMaxExtent, maybeContentSize)) {
        (final maxExtent?, final contentSize?) =>
          maxExtent.resolve(contentSize),
        _ => null,
      };

  /// The current extent of the sheet in pixels.
  double get pixels {
    assert(_debugAssertHasProperty('pixels', maybePixels));
    return maybePixels!;
  }

  /// The minimum extent of the sheet in pixels.
  double get minPixels {
    assert(_debugAssertHasProperty('minPixels', maybeMinPixels));
    return maybeMinPixels!;
  }

  /// The maximum extent of the sheet in pixels.
  double get maxPixels {
    assert(_debugAssertHasProperty('maxPixels', maybeMaxPixels));
    return maybeMaxPixels!;
  }

  /// The minimum extent of the sheet.
  SheetAnchor get minExtent {
    assert(_debugAssertHasProperty('minExtent', maybeMinExtent));
    return maybeMinExtent!;
  }

  /// The maximum extent of the sheet.
  SheetAnchor get maxExtent {
    assert(_debugAssertHasProperty('maxExtent', maybeMaxExtent));
    return maybeMaxExtent!;
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
      maybeMinExtent != null &&
      maybeMaxExtent != null &&
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
    required SheetAnchor? minExtent,
    required SheetAnchor? maxExtent,
    required Size? contentSize,
    required Size? viewportSize,
    required EdgeInsets? viewportInsets,
    this.devicePixelRatio = 1.0,
  })  : maybePixels = pixels,
        maybeMinExtent = minExtent,
        maybeMaxExtent = maxExtent,
        maybeContentSize = contentSize,
        maybeViewportSize = viewportSize,
        maybeViewportInsets = viewportInsets;

  @override
  final double? maybePixels;

  @override
  final SheetAnchor? maybeMinExtent;

  @override
  final SheetAnchor? maybeMaxExtent;

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
    SheetAnchor? minExtent,
    SheetAnchor? maxExtent,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportInsets,
    double? devicePixelRatio,
  }) {
    return SheetMetricsSnapshot(
      pixels: pixels ?? maybePixels,
      minExtent: minExtent ?? maybeMinExtent,
      maxExtent: maxExtent ?? maybeMaxExtent,
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
          maybeMinExtent == other.maybeMinExtent &&
          maybeMaxExtent == other.maybeMaxExtent &&
          maybeContentSize == other.maybeContentSize &&
          maybeViewportSize == other.maybeViewportSize &&
          maybeViewportInsets == other.maybeViewportInsets &&
          devicePixelRatio == other.devicePixelRatio);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        maybePixels,
        maybeMinExtent,
        maybeMaxExtent,
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
        minExtent: maybeMinExtent,
        maxExtent: maybeMaxExtent,
        contentSize: maybeContentSize,
        viewportSize: maybeViewportSize,
        viewportInsets: maybeViewportInsets,
        devicePixelRatio: devicePixelRatio,
      ).toString();
}

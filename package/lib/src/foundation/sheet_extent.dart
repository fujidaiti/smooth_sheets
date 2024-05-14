import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../internal/double_utils.dart';
import 'activities.dart';
import 'drag_controller.dart';
import 'notifications.dart';
import 'physics.dart';
import 'sheet_controller.dart';
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
/// be outside of the range if the [SheetExtentConfig.physics] allows it.
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
abstract class SheetExtent extends ChangeNotifier
    implements ValueListenable<SheetMetrics> {
  /// Creates an object that manages the extent of a sheet.
  SheetExtent({
    required this.context,
    required SheetExtentConfig config,
  }) : _config = config {
    goIdle();
  }

  @override
  SheetMetrics get value => metrics;

  SheetStatus get status => activity.status;

  /// A handle to the owner of this object.
  final SheetContext context;

  SheetExtentConfig get config => _config;
  SheetExtentConfig _config;

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
          case (final drag?, final SheetDragDelegate dragActivity)) {
        currentDrag = drag..updateDelegate(dragActivity);
        other.currentDrag = null;
      }
    } else {
      goIdle();
    }
    if (other.metrics.maybePixels case final pixels?) {
      correctPixels(pixels);
    }
    applyNewViewportDimensions(
      other.metrics.viewportSize,
      other.metrics.viewportInsets,
    );
    applyNewContentSize(other.metrics.contentSize);
  }

  @mustCallSuper
  void applyNewContentSize(Size contentSize) {
    if (metrics.maybeContentSize != contentSize) {
      final oldMaxPixels = metrics.maybeMaxPixels;
      final oldMinPixels = metrics.maybeMinPixels;
      _oldContentSize = metrics.maybeContentSize;
      _metrics = metrics.copyWith(
        contentSize: contentSize,
        minPixels: config.minExtent.resolve(contentSize),
        maxPixels: config.maxExtent.resolve(contentSize),
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
  void applyNewConfig(SheetExtentConfig config) {
    if (_config != config) {
      _config = config;
      final oldMaxPixels = metrics.maxPixels;
      final oldMinPixels = metrics.minPixels;
      _metrics = metrics.copyWith(
        minPixels: config.minExtent.resolve(metrics.contentSize),
        maxPixels: config.maxExtent.resolve(metrics.contentSize),
      );
      if (oldMinPixels != metrics.minPixels ||
          oldMaxPixels != metrics.maxPixels) {
        activity.didChangeBoundaryConstraints(oldMinPixels, oldMaxPixels);
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
    switch ((wasDragging, isDragging)) {
      case (true, true):
        assert(currentDrag != null);
        assert(activity is SheetDragDelegate);
        currentDrag!.updateDelegate(activity as SheetDragDelegate);

      case (true, false):
        assert(currentDrag != null);
        dispatchDragEndNotification(activity.velocity);
        currentDrag!.dispose();
        currentDrag = null;

      case (false, true):
        assert(currentDrag != null);
        dispatchDragStartNotification();

      case (false, false):
        assert(currentDrag == null);
    }

    oldActivity.dispose();
  }

  void goIdle() {
    beginActivity(IdleSheetActivity());
  }

  void goBallistic(double velocity) {
    assert(metrics.hasDimensions);
    final simulation =
        config.physics.createBallisticSimulation(velocity, metrics);
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
    final simulation = config.physics.createSettlingSimulation(metrics);
    if (simulation != null) {
      // TODO: Begin a SettlingSheetActivity
      goBallisticWith(simulation);
    } else {
      goIdle();
    }
  }

  Drag drag(
    DragStartDetails details,
    VoidCallback dragCancelCallback,
  ) {
    assert(currentDrag == null);
    final dragActivity = DragSheetActivity();
    final drag = currentDrag = SheetDragController(
      delegate: dragActivity,
      details: details,
      onDragCanceled: dragCancelCallback,
      // TODO: Specify a correct value.
      carriedVelocity: 0,
      motionStartDistanceThreshold:
          config.physics.dragStartDistanceMotionThreshold,
    );
    beginActivity(dragActivity);
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
      if (oldPixels != null && status == SheetStatus.dragging) {
        dispatchDragUpdateNotification(pixels - oldPixels);
      } else {
        dispatchUpdateNotification();
      }
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
    final destination = newExtent.resolve(metrics.contentSize);
    if (metrics.pixels == destination) {
      return Future.value();
    } else {
      final activity = AnimatedSheetActivity(
        from: metrics.pixels,
        to: destination,
        duration: duration,
        curve: curve,
      );

      beginActivity(activity);
      return activity.done;
    }
  }

  void dispatchUpdateNotification() {
    if (metrics.hasDimensions) {
      _dispatchNotification(
        SheetUpdateNotification(
          metrics: metrics,
          status: status,
        ),
      );
    }
  }

  void dispatchDragStartNotification() {
    if (metrics.hasDimensions) {
      final details = currentDrag?.lastDetails;
      assert(details is DragStartDetails);
      _dispatchNotification(
        SheetDragStartNotification(
          metrics: metrics,
          dragDetails: details as DragStartDetails,
        ),
      );
    }
  }

  void dispatchDragEndNotification(double velocity) {
    if (metrics.hasDimensions) {
      final details = currentDrag?.lastDetails;
      assert(details == null || details is DragEndDetails);
      _dispatchNotification(
        SheetDragEndNotification(
          metrics: metrics,
          dragDetails: details as DragEndDetails?,
        ),
      );
    }
  }

  void dispatchDragUpdateNotification(double delta) {
    if (metrics.hasDimensions) {
      final details = currentDrag?.lastDetails;
      assert(details is DragUpdateDetails);
      _dispatchNotification(
        SheetDragUpdateNotification(
          metrics: metrics,
          delta: delta,
          dragDetails: details as DragUpdateDetails,
        ),
      );
    }
  }

  void dispatchOverflowNotification(double overflow) {
    if (metrics.hasDimensions) {
      _dispatchNotification(
        SheetOverflowNotification(
          metrics: metrics,
          status: status,
          overflow: overflow,
        ),
      );
    }
  }

  void _dispatchNotification(SheetNotification notification) {
    // Avoid dispatching a notification in the middle of a build.
    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.postFrameCallbacks:
        notification.dispatch(context.notificationContext);
      case SchedulerPhase.idle:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
      case SchedulerPhase.transientCallbacks:
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notification.dispatch(context.notificationContext);
        });
    }
  }

  String _debugMessage(String message) {
    return switch (config.debugLabel) {
      null => message,
      final debugLabel => '$debugLabel: $message',
    };
  }
}

class SheetExtentConfig {
  const SheetExtentConfig({
    required this.minExtent,
    required this.maxExtent,
    required this.physics,
    this.debugLabel,
  });

  /// {@template SheetExtentConfig.minExtent}
  /// The minimum extent of the sheet.
  ///
  /// The sheet may below this extent if the [physics] allows it.
  /// {@endtemplate}
  final Extent minExtent;

  /// {@template SheetExtentConfig.maxExtent}
  /// The maximum extent of the sheet.
  ///
  /// The sheet may exceed this extent if the [physics] allows it.
  /// {@endtemplate}
  final Extent maxExtent;

  /// {@template SheetExtentConfig.physics}
  /// How the sheet extent should respond to user input.
  ///
  /// This determines how the sheet will behave when over-dragged or
  /// under-dragged, or when the user stops dragging.
  /// {@endtemplate}
  final SheetPhysics physics;

  final String? debugLabel;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SheetExtentConfig &&
            runtimeType == other.runtimeType &&
            minExtent == other.minExtent &&
            maxExtent == other.maxExtent &&
            physics == other.physics &&
            debugLabel == other.debugLabel);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        minExtent,
        maxExtent,
        physics,
        debugLabel,
      );
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
abstract class SheetContext {
  TickerProvider get vsync;
  BuildContext? get notificationContext;
}

@optionalTypeArgs
class SheetExtentScopeKey<T extends SheetExtent>
    extends LabeledGlobalKey<_SheetExtentScopeState> {
  SheetExtentScopeKey({String? debugLabel}) : super(debugLabel);

  final List<VoidCallback> _onCreatedListeners = [];

  T? get maybeCurrentExtent =>
      switch (currentState?._extent) { final T extent => extent, _ => null };

  T get currentExtent => maybeCurrentExtent!;

  void addOnCreatedListener(VoidCallback listener) {
    _onCreatedListeners.add(listener);
    // Immediately notify the listener if the extent is already created.
    if (maybeCurrentExtent != null) {
      listener();
    }
  }

  void removeOnCreatedListener(VoidCallback listener) {
    _onCreatedListeners.remove(listener);
  }

  void removeAllOnCreatedListeners() {
    _onCreatedListeners.clear();
  }

  void _notifySheetExtentCreation() {
    for (final listener in _onCreatedListeners) {
      listener();
    }
  }
}

abstract class SheetExtentFactory {
  const SheetExtentFactory();

  @factory
  SheetExtent createSheetExtent({
    required SheetContext context,
    required SheetExtentConfig config,
  });
}

/// A widget that creates a [SheetExtent], manages its lifecycle,
/// and exposes it to the descendant widgets.
class SheetExtentScope extends StatefulWidget {
  /// Creates a widget that hosts a [SheetExtent].
  const SheetExtentScope({
    super.key,
    required this.controller,
    required this.config,
    required this.factory,
    this.isPrimary = true,
    required this.child,
  });

  /// The [SheetController] that will be attached to the created [SheetExtent].
  final SheetController controller;

  final SheetExtentConfig config;

  /// The factory that creates the [SheetExtent].
  final SheetExtentFactory factory;

  final bool isPrimary;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<SheetExtentScope> createState() => _SheetExtentScopeState();

  /// Retrieves the [SheetExtent] from the closest [SheetExtentScope]
  /// that encloses the given context, if any.
  ///
  /// Use of this method will cause the given context to rebuild any time
  /// that the [config] property of the ancestor [SheetExtentScope] changes.
  // TODO: Add 'useRoot' option.
  // TODO: Add generic type parameter T that extends SheetExtent.
  static SheetExtent? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedSheetExtentScope>()
        ?.extent;
  }

  /// Retrieves the [SheetExtent] from the closest [SheetExtentScope]
  /// that encloses the given context.
  ///
  /// Use of this method will cause the given context to rebuild any time
  /// that the [config] property of the ancestor [SheetExtentScope] changes.
  static SheetExtent of(BuildContext context) {
    return maybeOf(context)!;
  }
}

class _SheetExtentScopeState extends State<SheetExtentScope>
    with TickerProviderStateMixin
    implements SheetContext {
  late SheetExtent _extent;

  @override
  TickerProvider get vsync => this;

  @override
  BuildContext? get notificationContext => mounted ? context : null;

  SheetExtentScopeKey? get _scopeKey => switch (widget.key) {
        final SheetExtentScopeKey key => key,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _extent = _createExtent();
    _scopeKey?._notifySheetExtentCreation();
  }

  @override
  void dispose() {
    _discard(_extent);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _invalidateExtentOwnership();
  }

  @override
  void didUpdateWidget(SheetExtentScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldExtent = _extent;
    if (widget.factory != oldWidget.factory) {
      _extent = _createExtent()..takeOver(oldExtent);
      _scopeKey?._notifySheetExtentCreation();
      _discard(oldExtent);
    } else if (widget.config != oldWidget.config) {
      _extent.applyNewConfig(widget.config);
    }
    _invalidateExtentOwnership();
  }

  SheetExtent _createExtent() {
    return widget.factory.createSheetExtent(
      context: this,
      config: widget.config,
    );
  }

  void _discard(SheetExtent extent) {
    widget.controller.detach(extent);
    extent.dispose();
  }

  void _invalidateExtentOwnership() {
    assert(_debugAssertExtentOwnership());

    if (widget.isPrimary) {
      widget.controller.attach(_extent);
    } else {
      widget.controller.detach(_extent);
    }
  }

  bool _debugAssertExtentOwnership() {
    assert(
      () {
        final parentScope = context
            .dependOnInheritedWidgetOfExactType<_InheritedSheetExtentScope>();
        if (!widget.isPrimary ||
            parentScope == null ||
            !parentScope.isPrimary) {
          return true;
        }

        throw FlutterError(
          'Nesting SheetExtentScope widgets that are marked as primary '
          'is not allowed. Typically, this error occurs when you try to nest '
          'sheet widgets such as DraggableSheet or ScrollableSheet.',
        );
      }(),
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSheetExtentScope(
      extent: _extent,
      isPrimary: widget.isPrimary,
      child: widget.child,
    );
  }
}

class _InheritedSheetExtentScope extends InheritedWidget {
  const _InheritedSheetExtentScope({
    required this.extent,
    required this.isPrimary,
    required super.child,
  });

  final SheetExtent extent;
  final bool isPrimary;

  @override
  bool updateShouldNotify(_InheritedSheetExtentScope oldWidget) =>
      extent != oldWidget.extent || isPrimary != oldWidget.isPrimary;
}

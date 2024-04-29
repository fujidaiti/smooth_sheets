import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../internal/double_utils.dart';
import 'activities.dart';
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
  /// Do not cache the value of [contentDimensions] because
  /// it may change over time.
  double resolve(Size contentDimensions);
}

/// An extent that is proportional to the content height.
class ProportionalExtent implements Extent {
  /// {@template proportional_extent}
  /// Creates an extent that is proportional to the content height.
  ///
  /// The [factor] must be greater than or equal to 0.
  /// This extent will resolve to `contentDimensions.height * factor`.
  /// {@endtemplate}
  const ProportionalExtent(this.factor) : assert(factor >= 0);

  /// The fraction of the content height.
  final double factor;

  @override
  double resolve(Size contentDimensions) => contentDimensions.height * factor;

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
  double resolve(Size contentDimensions) => pixels;

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
/// The [pixels] value determines the visible height of a sheet. As this value
/// changes, the sheet translates its position, which changes the visible area
/// of the content. The [minPixels] and [maxPixels] values limit the range of
/// the [pixels], but it can be outside of the range if the [physics] allows it.
///
/// The current [activity] is responsible for how the [pixels] changes
/// over time, for example, [AnimatedSheetActivity] animates the [pixels] to
/// a target value, and [IdleSheetActivity] keeps the [pixels] unchanged.
/// [SheetExtent] starts with [IdleSheetActivity] as the initial activity,
/// and it can be changed by calling [beginActivity].
///
/// This object is [Listenable] that notifies its listeners when [pixels]
/// changes, even during build or layout phase. For listeners that can cause
/// any widget to rebuild, consider using [SheetController], which is also
/// [Listenable] of the extent, but only notifies its listeners between frames.
///
/// See also:
/// - [SheetController], which can be attached to a sheet to control its extent.
/// - [SheetExtentScope], which creates a [SheetExtent], manages its lifecycle,
///   and exposes it to the descendant widgets.
// TODO: Reimplement this class as ValueListenable<SheetMetrics?>
class SheetExtent with ChangeNotifier, MaybeSheetMetrics {
  /// Creates an object that manages the extent of a sheet.
  SheetExtent({
    required this.context,
    required this.delegate,
    required SheetExtentConfig config,
  }) : _config = config {
    _metrics = _SheetMetricsRef(this);
    goIdle();
  }

  /// A handle to the owner of this object.
  final SheetContext context;

  SheetExtentConfig get config => _config;
  SheetExtentConfig _config;

  /// {@template SheetExtent.physics}
  /// How the sheet extent should respond to user input.
  ///
  /// This determines how the sheet will behave when over-dragged or
  /// under-dragged, or when the user stops dragging.
  /// {@endtemplate}
  SheetPhysics get physics => config.physics;

  /// {@template SheetExtent.minExtent}
  /// The minimum extent of the sheet.
  ///
  /// The sheet may below this extent if the [physics] allows it.
  /// {@endtemplate}
  Extent get minExtent => config.minExtent;

  /// {@template SheetExtent.maxExtent}
  /// The maximum extent of the sheet.
  ///
  /// The sheet may exceed this extent if the [physics] allows it.
  /// {@endtemplate}
  Extent get maxExtent => config.maxExtent;

  final SheetExtentDelegate delegate;

  SheetActivity? _activity;
  double? _minPixels;
  double? _maxPixels;
  Size? _contentDimensions;
  ViewportDimensions? _viewportDimensions;

  /// A view of [SheetMetrics] backed by this object.
  ///
  /// Useful for treating this object as a [SheetMetrics] without
  /// creating an intermediate object.
  SheetMetrics get metrics => _metrics;
  late final _SheetMetricsRef _metrics;

  /// A snapshot of the current metrics.
  SheetMetricsSnapshot get snapshot {
    assert(hasPixels);
    return SheetMetricsSnapshot.from(metrics);
  }

  @override
  SheetStatus get status => _activity!.status;

  @override
  double? get pixels => _activity!.pixels;

  @override
  double? get minPixels => _minPixels;

  @override
  double? get maxPixels => _maxPixels;

  @override
  Size? get contentDimensions => _contentDimensions;

  @override
  ViewportDimensions? get viewportDimensions => _viewportDimensions;

  /// The current activity of the sheet.
  SheetActivity get activity => _activity!;

  void _invalidateBoundaryConditions() {
    _minPixels = minExtent.resolve(contentDimensions!);
    _maxPixels = maxExtent.resolve(contentDimensions!);
  }

  @mustCallSuper
  void takeOver(SheetExtent other) {
    if (other.viewportDimensions != null) {
      applyNewViewportDimensions(other.viewportDimensions!);
    }
    if (other.contentDimensions != null) {
      applyNewContentDimensions(other.contentDimensions!);
    }

    _activity!.takeOver(other._activity!);
  }

  @mustCallSuper
  void applyNewContentDimensions(Size contentDimensions) {
    if (_contentDimensions != contentDimensions) {
      _oldContentDimensions = _contentDimensions;
      _contentDimensions = contentDimensions;
      _invalidateBoundaryConditions();
      _activity!.didChangeContentDimensions(_oldContentDimensions);
    }
  }

  @mustCallSuper
  void applyNewViewportDimensions(ViewportDimensions viewportDimensions) {
    if (_viewportDimensions != viewportDimensions) {
      final oldPixels = pixels;
      final oldViewPixels = viewPixels;
      _oldViewportDimensions = _viewportDimensions;
      _viewportDimensions = viewportDimensions;
      _activity!.didChangeViewportDimensions(_oldViewportDimensions);
      if (oldPixels != pixels || oldViewPixels != viewPixels) {
        notifyListeners();
      }
    }
  }

  @mustCallSuper
  void applyNewConfig(SheetExtentConfig config) {
    if (_config != config) {
      final oldMinPixels = minPixels;
      final oldMaxPixels = maxPixels;
      _config = config;
      _invalidateBoundaryConditions();
      if (oldMinPixels != minPixels || oldMaxPixels != maxPixels) {
        _activity!.didChangeContentDimensions(_oldContentDimensions);
      }
    }
  }

  Size? _oldContentDimensions;
  ViewportDimensions? _oldViewportDimensions;
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

    _activity!.didFinalizeDimensions(
      _oldContentDimensions,
      _oldViewportDimensions,
    );

    _oldContentDimensions = null;
    _oldViewportDimensions = null;
  }

  @mustCallSuper
  void beginActivity(SheetActivity activity) {
    final oldActivity = _activity?..removeListener(notifyListeners);
    // Update the current activity before initialization.
    _activity = activity;

    activity
      ..initWith(this)
      ..addListener(notifyListeners);

    if (oldActivity != null) {
      activity.takeOver(oldActivity);
      oldActivity.dispose();
    }
  }

  void goIdle() {
    beginActivity(delegate.createIdleActivity());
  }

  void goBallistic(double velocity) {
    assert(hasPixels);
    final simulation = physics.createBallisticSimulation(velocity, metrics);
    if (simulation != null) {
      goBallisticWith(simulation);
    } else {
      goIdle();
    }
  }

  void goBallisticWith(Simulation simulation) {
    beginActivity(delegate.createBallisticActivity(simulation));
  }

  void settle() {
    assert(hasPixels);
    final simulation = physics.createSettlingSimulation(metrics);
    if (simulation != null) {
      // TODO: Begin a SettlingSheetActivity
      goBallisticWith(simulation);
    } else {
      goIdle();
    }
  }

  @override
  void dispose() {
    activity
      ..removeListener(notifyListeners)
      ..dispose();

    super.dispose();
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
    assert(hasPixels);
    final destination = newExtent.resolve(contentDimensions!);
    if (pixels == destination) {
      return Future.value();
    } else {
      final activity = AnimatedSheetActivity(
        from: pixels!,
        to: destination,
        duration: duration,
        curve: curve,
      );

      beginActivity(activity);
      return activity.done;
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

  final Extent minExtent;
  final Extent maxExtent;
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

mixin class SheetExtentDelegate {
  const SheetExtentDelegate();

  SheetActivity createBallisticActivity(Simulation simulation) {
    return BallisticSheetActivity(simulation: simulation);
  }

  SheetActivity createIdleActivity() {
    return IdleSheetActivity();
  }
}

/// The dimensions of the viewport that hosts the sheet.
class ViewportDimensions {
  const ViewportDimensions({
    required this.width,
    required this.height,
    required this.insets,
  });

  /// The width of the viewport.
  final double width;

  /// The height of the viewport.
  final double height;

  /// The insets of the viewport.
  ///
  /// This is the same as [MediaQueryData.viewInsets].
  final EdgeInsets insets;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewportDimensions &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          insets == other.insets);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        width,
        height,
        insets,
      );
}

/// A description of the state of a sheet.
mixin MaybeSheetMetrics {
  /// The current status of the sheet.
  SheetStatus get status;

  /// The current extent of the sheet.
  double? get pixels;

  /// The minimum extent of the sheet.
  double? get minPixels;

  /// The maximum extent of the sheet.
  double? get maxPixels;

  /// The dimensions of the sheet's content.
  Size? get contentDimensions;

  /// The dimensions of the viewport that hosts the sheet.
  ViewportDimensions? get viewportDimensions;

  /// The visible height of the sheet measured from the bottom of the viewport.
  ///
  /// If the on-screen keyboard is visible, this value is the sum of
  /// [pixels] and the keyboard's height. Otherwise, it is equal to [pixels].
  double? get viewPixels => switch ((pixels, viewportDimensions)) {
        (final pixels?, final viewport?) => pixels + viewport.insets.bottom,
        _ => null,
      };

  /// The minimum visible height of the sheet measured from the bottom
  /// of the viewport.
  double? get minViewPixels => switch ((minPixels, viewportDimensions)) {
        (final minPixels?, final viewport?) =>
          minPixels + viewport.insets.bottom,
        _ => null,
      };

  /// The maximum visible height of the sheet measured from the bottom
  /// of the viewport.
  double? get maxViewPixels => switch ((maxPixels, viewportDimensions)) {
        (final maxPixels?, final viewport?) =>
          maxPixels + viewport.insets.bottom,
        _ => null,
      };

  /// Whether the all metrics are available.
  ///
  /// Returns `true` if all of [pixels], [minPixels], [maxPixels],
  /// [contentDimensions] and [viewportDimensions] are not `null`.
  bool get hasPixels =>
      pixels != null &&
      minPixels != null &&
      maxPixels != null &&
      contentDimensions != null &&
      viewportDimensions != null;

  /// Whether the sheet is within the range of [minPixels] and [maxPixels]
  /// (inclusive of both bounds).
  bool get isPixelsInBounds =>
      hasPixels && pixels!.isInBounds(minPixels!, maxPixels!);

  /// Whether the sheet is outside the range of [minPixels] and [maxPixels].
  bool get isPixelsOutOfBounds => !isPixelsInBounds;

  @override
  String toString() => (
        hasPixels: hasPixels,
        pixels: pixels,
        minPixels: minPixels,
        maxPixels: maxPixels,
        viewPixels: viewPixels,
        minViewPixels: minViewPixels,
        maxViewPixels: maxViewPixels,
        contentDimensions: contentDimensions,
        viewportDimensions: viewportDimensions,
      ).toString();
}

/// Non-nullable version of [MaybeSheetMetrics].
mixin SheetMetrics on MaybeSheetMetrics {
  @override
  double get pixels;

  @override
  double get minPixels;

  @override
  double get maxPixels;

  @override
  Size get contentDimensions;

  @override
  ViewportDimensions get viewportDimensions;

  @override
  double get viewPixels => super.viewPixels!;

  @override
  double get minViewPixels => super.minViewPixels!;

  @override
  double get maxViewPixels => super.maxViewPixels!;
}

/// An immutable object that implements [SheetMetrics].
class SheetMetricsSnapshot with MaybeSheetMetrics, SheetMetrics {
  /// Creates an immutable description of the sheet's state.
  const SheetMetricsSnapshot({
    required this.status,
    required this.pixels,
    required this.minPixels,
    required this.maxPixels,
    required this.contentDimensions,
    required this.viewportDimensions,
  });

  /// Creates a snapshot of the given [SheetMetrics].
  factory SheetMetricsSnapshot.from(SheetMetrics other) {
    return SheetMetricsSnapshot(
      status: other.status,
      pixels: other.pixels,
      minPixels: other.minPixels,
      maxPixels: other.maxPixels,
      contentDimensions: other.contentDimensions,
      viewportDimensions: other.viewportDimensions,
    );
  }

  @override
  final SheetStatus status;

  @override
  final double pixels;

  @override
  final double minPixels;

  @override
  final double maxPixels;

  @override
  final Size contentDimensions;

  @override
  final ViewportDimensions viewportDimensions;

  @override
  bool get hasPixels => true;

  /// Creates a copy of this object with the given fields replaced.

  SheetMetricsSnapshot copyWith({
    SheetStatus? status,
    double? pixels,
    double? minPixels,
    double? maxPixels,
    Size? contentDimensions,
    ViewportDimensions? viewportDimensions,
  }) {
    return SheetMetricsSnapshot(
      status: status ?? this.status,
      pixels: pixels ?? this.pixels,
      minPixels: minPixels ?? this.minPixels,
      maxPixels: maxPixels ?? this.maxPixels,
      contentDimensions: contentDimensions ?? this.contentDimensions,
      viewportDimensions: viewportDimensions ?? this.viewportDimensions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SheetMetricsSnapshot &&
        other.runtimeType == runtimeType &&
        other.pixels == pixels &&
        other.minPixels == minPixels &&
        other.maxPixels == maxPixels &&
        other.contentDimensions == contentDimensions &&
        other.viewportDimensions == viewportDimensions;
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        pixels,
        minPixels,
        maxPixels,
        contentDimensions,
        viewportDimensions,
      );

  @override
  String toString() => (
        pixels: pixels,
        minPixels: minPixels,
        maxPixels: maxPixels,
        contentDimensions: contentDimensions,
        viewportDimensions: viewportDimensions,
      ).toString();
}

class _SheetMetricsRef with MaybeSheetMetrics, SheetMetrics {
  _SheetMetricsRef(this._source);

  final MaybeSheetMetrics _source;

  @override
  SheetStatus get status => _source.status;

  @override
  double get pixels => _source.pixels!;

  @override
  double get minPixels => _source.minPixels!;

  @override
  double get maxPixels => _source.maxPixels!;

  @override
  Size get contentDimensions => _source.contentDimensions!;

  @override
  ViewportDimensions get viewportDimensions => _source.viewportDimensions!;
}

/// An interface that provides the necessary context to a [SheetExtent].
///
/// Typically, [State]s that host a [SheetExtent] will implement this interface.
abstract class SheetContext {
  TickerProvider get vsync;
  BuildContext? get notificationContext;
}

// /// Configuration of a [SheetExtent].
// abstract class SheetExtentConfig {
//   const SheetExtentConfig();
//   SheetExtent build(BuildContext context, SheetContext sheetContext);
//   bool shouldRebuild(BuildContext context, SheetExtent oldExtent);
// }

typedef SheetExtentInitializer = SheetExtent Function(SheetExtent);

/// A widget that creates a [SheetExtent], manages its lifecycle,
/// and exposes it to the descendant widgets.
class SheetExtentScope extends StatefulWidget {
  /// Creates a widget that hosts a [SheetExtent].
  const SheetExtentScope({
    super.key,
    required this.controller,
    this.initializer,
    this.isPrimary = true,
    required this.config,
    this.delegate = const SheetExtentDelegate(),
    required this.child,
  });

  /// The [SheetController] that will be attached to the created [SheetExtent].
  final SheetController controller;

  final SheetExtentConfig config;

  final SheetExtentDelegate delegate;

  final SheetExtentInitializer? initializer;

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
  // TODO: Add 'useRoot' option
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

  @override
  void initState() {
    super.initState();
    _extent = _createExtent();
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
    if (widget.controller != oldWidget.controller ||
        widget.delegate != oldWidget.delegate) {
      _extent = _createExtent()..takeOver(oldExtent);
      _discard(oldExtent);
    } else if (widget.config != oldWidget.config) {
      _extent.applyNewConfig(widget.config);
    }
    _invalidateExtentOwnership();
  }

  SheetExtent _createExtent() {
    final extent = widget.controller.createSheetExtent(
      context: this,
      config: widget.config,
      delegate: widget.delegate,
    );

    return switch (widget.initializer) {
      null => extent,
      final initializer => initializer(extent),
    };
  }

  void _discard(SheetExtent extent) {
    widget.controller.detach(extent);
    extent.dispose();
  }

  void _invalidateExtentOwnership() {
    assert(
      () {
        final parentScope = context
            .dependOnInheritedWidgetOfExactType<_InheritedSheetExtentScope>();
        return !widget.isPrimary ||
            parentScope == null ||
            !parentScope.isPrimary;
      }(),
      'Nesting SheetExtentScope widgets that are marked as primary '
      'is not allowed. Typically, this error occurs when you try to nest '
      'sheet widgets such as DraggableSheet or ScrollableSheet.',
    );

    if (widget.isPrimary) {
      widget.controller.attach(_extent);
    } else {
      widget.controller.detach(_extent);
    }
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

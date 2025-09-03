import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// TODO: Remove this import after the minimum sdk version is bumped to 3.35.0
//
// @internal annotation has been included in flutter/foundation.dart since 3.35.0.
// See: https://github.com/flutter/flutter/commit/5706259791de29a27cb68e9b95d6319ba863e366
// ignore: unnecessary_import
import 'package:meta/meta.dart';

import '../smooth_sheets.dart';
import 'activity.dart';
import 'gesture_proxy.dart';
import 'model_owner.dart';

/// An abstract representation of a sheet's position.
///
/// It is used in various contexts by sheets, for example,
/// to define how much of the sheet is initially visible at the first build
/// or to limit the range within which the sheet can be dragged.
@immutable
abstract interface class SheetOffset {
  /// {@macro RelativeSheetOffset}
  const factory SheetOffset(double factor) = RelativeSheetOffset;

  /// {@macro AbsoluteSheetOffset}
  const factory SheetOffset.absolute(double value) = AbsoluteSheetOffset;

  /// {@macro ViewportRelativeSheetOffset}
  const factory SheetOffset.proportionalToViewport(double factor) =
      ProportionalToViewportSheetOffset;

  /// {@macro ExpressionSheetOffset}
  const factory SheetOffset.expression(
          double Function(ViewportLayout metrics) expression) =
      ExpressionSheetOffset;

  /// Resolves the position to an actual value in pixels.
  double resolve(ViewportLayout metrics);
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
  double resolve(ViewportLayout metrics) =>
      metrics.contentSize.height * factor + metrics.contentBaseline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelativeSheetOffset &&
          runtimeType == other.runtimeType &&
          factor == other.factor);

  @override
  int get hashCode => Object.hash(runtimeType, factor);

  @override
  String toString() => 'RelativeSheetOffset(factor: $factor)';
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
  String toString() => 'AbsoluteSheetOffset(value: $value)';
}

/// A [SheetOffset] that is defined by a factor of the viewport size.
class ProportionalToViewportSheetOffset implements SheetOffset {
  const ProportionalToViewportSheetOffset(this.factor);

  final double factor;

  @override
  double resolve(ViewportLayout metrics) =>
      metrics.viewportSize.height * factor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProportionalToViewportSheetOffset &&
          runtimeType == other.runtimeType &&
          factor == other.factor);

  @override
  int get hashCode => Object.hash(runtimeType, factor);

  @override
  String toString() => 'ViewportRelativeSheetOffset(factor: $factor)';
}

/// A [SheetOffset] that evaluates an expression against [ViewportLayout].
class ExpressionSheetOffset implements SheetOffset {
  const ExpressionSheetOffset(this.expression);

  final double Function(ViewportLayout metrics) expression;

  @override
  double resolve(ViewportLayout metrics) => expression(metrics);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpressionSheetOffset &&
          runtimeType == other.runtimeType &&
          expression == other.expression);

  @override
  int get hashCode => Object.hash(runtimeType, expression);

  @override
  String toString() => 'ExpressionSheetOffset(expression: $expression)';
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
abstract class SheetModelView with SheetMetrics implements Listenable {
  bool get shouldIgnorePointer;
  bool get hasMetrics;

  /// Registers a [listener] that will be called every time
  /// the [rect] may have changed.
  void addRectListener(VoidCallback listener);

  /// Unregisters a [listener] that was previously registered
  /// with [addRectListener].
  void removeRectListener(VoidCallback listener);
}

/// Manages the position of a sheet.
///
/// This object is much like [ScrollPosition] for scrollable widgets.
/// The [offset] value determines the visible height of a sheet.
/// As this value changes, the sheet translates its position, which changes the
/// visible area of the content. The [minOffset] and
/// [maxOffset] values limit the range of the [offset], but it can
/// be outside of the range if the [physics] allows it.
///
/// The current [activity] is responsible for how the [offset] changes
/// over time, for example, [AnimatedSheetActivity] animates the [offset] to
/// a target value, and [IdleSheetActivity] keeps the [offset] unchanged.
/// [SheetModel] starts with [IdleSheetActivity] as the initial activity,
/// and it can be changed by calling [beginActivity].
///
/// This object is a [Listenable] that notifies its listeners when the [offset]
/// changes, even during build or layout phase. For listeners that can cause
/// any widget to rebuild, consider using [SheetController], which is also
/// [Listenable] of the [offset], but avoids notifying listeners during a build.
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
  Size get viewportSize => _layout!.viewportSize;

  @override
  EdgeInsets get viewportPadding => _layout!.viewportPadding;

  @override
  EdgeInsets get viewportDynamicOverlap => _layout!.viewportDynamicOverlap;

  @override
  EdgeInsets get viewportStaticOverlap => _layout!.viewportStaticOverlap;

  @override
  Size get contentSize => _layout!.contentSize;

  @override
  double get contentBaseline => _layout!.contentBaseline;

  @override
  Size get size => _layout!.size;

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
      _rectNotifier.notifyListeners();
    }
  }

  @override
  double get devicePixelRatio => context.devicePixelRatio;

  @override
  bool get hasMetrics =>
      _layout != null &&
      _minOffset != null &&
      _maxOffset != null &&
      _offset != null;

  @override
  bool get shouldIgnorePointer => activity.shouldIgnorePointer;

  // ignore: lines_longer_than_80_chars
  // TODO: Remote this field. The initial offset should be determined by the activity.
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
      final (newMinOffset, newMaxOffset) = value.snapGrid.getBoundaries(this);
      _minOffset = newMinOffset.resolve(this);
      _maxOffset = newMaxOffset.resolve(this);
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

  @mustCallSuper
  @protected
  void beginActivity(SheetActivity activity) {
    final oldActivity = _activity;
    // Update the current activity before initialization.
    _activity = activity;
    activity.init(this);
    oldActivity?.dispose();
  }

  SheetLayout? _layout;

  void applyNewLayout(SheetLayout layout) {
    if (layout == _layout) {
      return;
    }

    final oldLayout = _layout;
    _layout = layout;
    final (minOffset, maxOffset) = snapGrid.getBoundaries(layout);
    _minOffset = minOffset.resolve(layout);
    _maxOffset = maxOffset.resolve(layout);
    if (_offset == null) {
      offset = initialOffset.resolve(layout);
    }
    assert(hasMetrics);

    final oldOffset = offset;
    if (oldLayout != null) {
      activity.applyNewLayout(oldLayout);
    }
    assert(
      offset == dryApplyNewLayout(layout),
      'applyNewLayout must update the offset to the value '
      'that dryApplyLayout would return.',
    );

    // Notify the rect listeners only when the layout has changed
    // without changing the offset to avoid duplicate notifications,
    // because otherwise the listeners would already be notified.
    if (layout != oldLayout && oldOffset == offset) {
      _rectNotifier.notifyListeners();
    }
  }

  /// Returns an offset that the model would have if
  /// [applyNewLayout] was called with the given [layout].
  ///
  /// This method is "dry" because it does not change the state
  /// of the model.
  ///
  /// Called by the render object of the sheet **before**
  /// laying out the sheet so that its [size] can depend
  /// on the model's offset.
  /// After the sheet is laid out, [applyNewLayout] is called
  /// with the same [layout] and it must ensure that the model's
  /// [offset] is updated to the value that this method returns.
  @nonVirtual
  double dryApplyNewLayout(ViewportLayout layout) {
    if (!hasMetrics) {
      return initialOffset.resolve(layout);
    }

    SheetMetrics? oldMetrics;
    SheetActivity? oldActivity;
    assert(() {
      oldMetrics = copyWith();
      oldActivity = activity;
      return true;
    }());

    final result = activity.dryApplyNewLayout(layout);
    assert(
      (oldMetrics == null || oldMetrics == copyWith()) &&
          (oldActivity == null || identical(oldActivity, activity)),
      'SheetActivity.dryApplyNewLayout must not change the state of the model.',
    );
    return result;
  }

  final _rectNotifier = ChangeNotifier();

  @override
  void addRectListener(VoidCallback listener) {
    _rectNotifier.addListener(listener);
  }

  @override
  void removeRectListener(VoidCallback listener) {
    _rectNotifier.removeListener(listener);
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
    _rectNotifier.dispose();
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
    if (offset == newPosition.resolve(this)) {
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
    Size? size,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportPadding,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportStaticOverlap,
    double? contentBaseline,
    double? devicePixelRatio,
  }) {
    return ImmutableSheetMetrics(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      size: size ?? this.size,
      contentSize: contentSize ?? this.contentSize,
      contentBaseline: contentBaseline ?? this.contentBaseline,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      viewportDynamicOverlap:
          viewportDynamicOverlap ?? this.viewportDynamicOverlap,
      viewportPadding: viewportPadding ?? this.viewportPadding,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportStaticOverlap:
          viewportStaticOverlap ?? this.viewportStaticOverlap,
    );
  }

  void didUpdateMetrics() {
    SheetUpdateNotification(
      metrics: copyWith(),
    ).dispatch(context.notificationContext);
  }

  void didDragStart(SheetDragStartDetails details) {
    SheetDragStartNotification(
      metrics: copyWith(),
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragEnd(SheetDragEndDetails details) {
    SheetDragEndNotification(
      metrics: copyWith(),
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragUpdateMetrics(SheetDragUpdateDetails details) {
    SheetDragUpdateNotification(
      metrics: copyWith(),
      dragDetails: details,
    ).dispatch(context.notificationContext);
  }

  void didDragCancel() {
    SheetDragCancelNotification(
      metrics: copyWith(),
    ).dispatch(context.notificationContext);
  }

  void didOverflowBy(double overflow) {
    SheetOverflowNotification(
      metrics: copyWith(),
      overflow: overflow,
    ).dispatch(context.notificationContext);
  }
}

abstract interface class ViewportLayout {
  /// {@template ViewportLayout.viewportSize}
  /// The size of the *viewport*, which is the rectangle
  /// where the sheet is laid out.
  /// {@endtemplate}
  Size get viewportSize;

  /// {@template ViewportLayout.contentSize}
  /// The size of the sheet's content.
  /// {@endtemplate}
  Size get contentSize;

  /// {@template ViewportLayout.viewportPadding}
  /// The padding by which the viewport insets the sheet.
  /// {@endtemplate}
  EdgeInsets get viewportPadding;

  /// {@template ViewportLayout.viewportDynamicOverlap}
  /// The parts of the viewport that are partially overlapped
  /// by system UI elements that may dynamically change in size,
  /// such as the on-screen keyboard.
  /// {@endtemplate}
  EdgeInsets get viewportDynamicOverlap;

  /// {@template ViewportLayout.viewportStaticOverlap}
  /// The parts of the viewport that are partially overlapped
  /// by system UI elements that do not change in size,
  /// such as hardware display notches or the system status bar.
  /// {@endtemplate}
  EdgeInsets get viewportStaticOverlap;

  /// {@template ViewportLayout.contentBaseline}
  /// The minimum distance from the bottom of the viewport
  /// to the bottom of the content area.
  /// {@endtemplate}
  double get contentBaseline;
}

abstract interface class SheetLayout extends ViewportLayout {
  /// The size of the sheet.
  Size get size;
}

/// The metrics of a sheet.
mixin SheetMetrics implements SheetLayout {
  /// The current position of the sheet in pixels.
  double get offset;

  /// The minimum position of the sheet in pixels.
  double get minOffset;

  /// The maximum position of the sheet in pixels.
  double get maxOffset;

  /// The [FlutterView.devicePixelRatio] of the view that the sheet
  /// associated with this metrics is drawn into.
  // TODO: Remove this field.
  double get devicePixelRatio;

  /// The rectangle that bounds the sheet within the viewport.
  Rect get rect {
    final size = this.size;
    return Rect.fromLTWH(
      viewportPadding.left,
      viewportSize.height - offset,
      size.width,
      size.height,
    );
  }

  /// The part of the sheet's [rect] that is visible within the viewport.
  ///
  /// Returns `null` if the [rect] is outside of the viewport.
  Rect? get visibleRect {
    final viewportRect = Offset.zero & viewportSize;
    final rect = this.rect;
    return viewportRect.overlaps(rect) ? viewportRect.intersect(rect) : null;
  }

  /// The rectangle that bounds the sheet's content within the viewport.
  Rect get contentRect => rect.topLeft & contentSize;

  /// The part of the sheet's [contentRect] that is visible within the viewport.
  ///
  /// Returns `null` if the [contentRect] is outside of the viewport.
  Rect? get visibleContentRect {
    final viewportRect = Offset.zero & viewportSize;
    final contentRect = this.contentRect;
    return viewportRect.overlaps(contentRect)
        ? viewportRect.intersect(contentRect)
        : null;
  }

  /// The amount of overlap that the sheet has with static system UI elements,
  /// such as the system status bar or hardware display notches.
  EdgeInsets get staticOverlap {
    final vpStaticOverlap = viewportStaticOverlap;
    final safeArea = vpStaticOverlap.deflateRect(Offset.zero & viewportSize);
    final rect = this.rect;
    return EdgeInsets.fromLTRB(
      clampDouble(safeArea.left - rect.left, 0, vpStaticOverlap.left),
      clampDouble(safeArea.top - rect.top, 0, vpStaticOverlap.top),
      clampDouble(rect.right - safeArea.right, 0, vpStaticOverlap.right),
      clampDouble(rect.bottom - safeArea.bottom, 0, vpStaticOverlap.bottom),
    );
  }

  /// The amount of overlap that the sheet has with dynamic system UI elements,
  /// such as the on-screen keyboard.
  EdgeInsets get dynamicOverlap {
    final vpDynamicOverlap = viewportDynamicOverlap;
    final safeArea = vpDynamicOverlap.deflateRect(Offset.zero & viewportSize);
    final rect = this.rect;
    return EdgeInsets.fromLTRB(
      clampDouble(safeArea.left - rect.left, 0, vpDynamicOverlap.left),
      clampDouble(safeArea.top - rect.top, 0, vpDynamicOverlap.top),
      clampDouble(rect.right - safeArea.right, 0, vpDynamicOverlap.right),
      clampDouble(rect.bottom - safeArea.bottom, 0, vpDynamicOverlap.bottom),
    );
  }

  /// The amount of overlap that the sheet's content has with
  /// dynamic system UI elements, such as the on-screen keyboard.
  EdgeInsets get contentDynamicOverlap {
    final vpDynamicOverlap = viewportDynamicOverlap;
    final safeArea = vpDynamicOverlap.deflateRect(Offset.zero & viewportSize);
    final rect = this.rect;
    return EdgeInsets.fromLTRB(
      clampDouble(safeArea.left - rect.left, 0, vpDynamicOverlap.left),
      clampDouble(safeArea.top - rect.top, 0, vpDynamicOverlap.top),
      clampDouble(rect.right - safeArea.right, 0, vpDynamicOverlap.right),
      clampDouble(rect.bottom - safeArea.bottom, 0, vpDynamicOverlap.bottom),
    );
  }

  /// The amount of overlap that the sheet's content has with
  /// static system UI elements, such as the system status bar or
  /// hardware display notches.
  EdgeInsets get contentStaticOverlap {
    final vpStaticOverlap = viewportStaticOverlap;
    final safeArea = vpStaticOverlap.deflateRect(Offset.zero & viewportSize);
    final rect = this.rect;
    return EdgeInsets.fromLTRB(
      clampDouble(safeArea.left - rect.left, 0, vpStaticOverlap.left),
      clampDouble(safeArea.top - rect.top, 0, vpStaticOverlap.top),
      clampDouble(rect.right - safeArea.right, 0, vpStaticOverlap.right),
      clampDouble(rect.bottom - safeArea.bottom, 0, vpStaticOverlap.bottom),
    );
  }

  /// Creates a copy of the metrics with the given fields replaced.
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? size,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportPadding,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportStaticOverlap,
    double? contentBaseline,
    double? devicePixelRatio,
  });
}

@immutable
@internal
class ImmutableViewportLayout implements ViewportLayout {
  const ImmutableViewportLayout({
    required this.viewportSize,
    required this.contentSize,
    required this.viewportPadding,
    required this.viewportDynamicOverlap,
    required this.viewportStaticOverlap,
    required this.contentBaseline,
  });

  @override
  final Size viewportSize;

  @override
  final Size contentSize;

  @override
  final EdgeInsets viewportPadding;

  @override
  final EdgeInsets viewportDynamicOverlap;

  @override
  final EdgeInsets viewportStaticOverlap;

  @override
  final double contentBaseline;

  ImmutableViewportLayout copyWith({
    Size? viewportSize,
    Size? contentSize,
    EdgeInsets? viewportPadding,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportStaticOverlap,
    double? contentBaseline,
  }) {
    return ImmutableViewportLayout(
      viewportSize: viewportSize ?? this.viewportSize,
      contentSize: contentSize ?? this.contentSize,
      viewportPadding: viewportPadding ?? this.viewportPadding,
      viewportDynamicOverlap:
          viewportDynamicOverlap ?? this.viewportDynamicOverlap,
      viewportStaticOverlap:
          viewportStaticOverlap ?? this.viewportStaticOverlap,
      contentBaseline: contentBaseline ?? this.contentBaseline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewportLayout &&
          viewportSize == other.viewportSize &&
          contentSize == other.contentSize &&
          viewportPadding == other.viewportPadding &&
          viewportDynamicOverlap == other.viewportDynamicOverlap &&
          viewportStaticOverlap == other.viewportStaticOverlap &&
          contentBaseline == other.contentBaseline;

  @override
  int get hashCode => Object.hash(
        viewportSize,
        contentSize,
        viewportPadding,
        viewportDynamicOverlap,
        viewportStaticOverlap,
        contentBaseline,
      );
}

@immutable
@internal
class ImmutableSheetLayout implements SheetLayout {
  const ImmutableSheetLayout({
    required this.size,
    required this.contentBaseline,
    required this.contentSize,
    required this.viewportDynamicOverlap,
    required this.viewportPadding,
    required this.viewportSize,
    required this.viewportStaticOverlap,
  });

  factory ImmutableSheetLayout.from({
    required ViewportLayout viewportLayout,
    required Size size,
  }) {
    return ImmutableSheetLayout(
      size: size,
      contentBaseline: viewportLayout.contentBaseline,
      contentSize: viewportLayout.contentSize,
      viewportDynamicOverlap: viewportLayout.viewportDynamicOverlap,
      viewportPadding: viewportLayout.viewportPadding,
      viewportSize: viewportLayout.viewportSize,
      viewportStaticOverlap: viewportLayout.viewportStaticOverlap,
    );
  }

  @override
  final Size size;

  @override
  final double contentBaseline;

  @override
  final Size contentSize;

  @override
  final EdgeInsets viewportDynamicOverlap;

  @override
  final EdgeInsets viewportPadding;

  @override
  final Size viewportSize;

  @override
  final EdgeInsets viewportStaticOverlap;

  ImmutableSheetLayout copyWith({
    double? contentBaseline,
    Size? contentSize,
    Size? size,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportPadding,
    Size? viewportSize,
    EdgeInsets? viewportStaticOverlap,
  }) {
    return ImmutableSheetLayout(
      contentBaseline: contentBaseline ?? this.contentBaseline,
      contentSize: contentSize ?? this.contentSize,
      size: size ?? this.size,
      viewportDynamicOverlap:
          viewportDynamicOverlap ?? this.viewportDynamicOverlap,
      viewportPadding: viewportPadding ?? this.viewportPadding,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportStaticOverlap:
          viewportStaticOverlap ?? this.viewportStaticOverlap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImmutableSheetLayout &&
          contentBaseline == other.contentBaseline &&
          contentSize == other.contentSize &&
          size == other.size &&
          viewportDynamicOverlap == other.viewportDynamicOverlap &&
          viewportPadding == other.viewportPadding &&
          viewportSize == other.viewportSize &&
          viewportStaticOverlap == other.viewportStaticOverlap;

  @override
  int get hashCode => Object.hash(
        contentBaseline,
        contentSize,
        size,
        viewportDynamicOverlap,
        viewportPadding,
        viewportSize,
        viewportStaticOverlap,
      );
}

@immutable
@internal
class ImmutableSheetMetrics with SheetMetrics {
  const ImmutableSheetMetrics({
    required this.offset,
    required this.minOffset,
    required this.maxOffset,
    required this.devicePixelRatio,
    required this.contentBaseline,
    required this.contentSize,
    required this.size,
    required this.viewportDynamicOverlap,
    required this.viewportPadding,
    required this.viewportSize,
    required this.viewportStaticOverlap,
  });

  @override
  final double offset;

  @override
  final double minOffset;

  @override
  final double maxOffset;

  @override
  final double devicePixelRatio;

  @override
  final Size size;

  @override
  final double contentBaseline;

  @override
  final Size contentSize;

  @override
  final Size viewportSize;

  @override
  final EdgeInsets viewportPadding;

  @override
  final EdgeInsets viewportDynamicOverlap;

  @override
  final EdgeInsets viewportStaticOverlap;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? size,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportPadding,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportStaticOverlap,
    double? contentBaseline,
    double? devicePixelRatio,
  }) {
    return ImmutableSheetMetrics(
      offset: offset ?? this.offset,
      minOffset: minOffset ?? this.minOffset,
      maxOffset: maxOffset ?? this.maxOffset,
      size: size ?? this.size,
      contentSize: contentSize ?? this.contentSize,
      contentBaseline: contentBaseline ?? this.contentBaseline,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      viewportDynamicOverlap:
          viewportDynamicOverlap ?? this.viewportDynamicOverlap,
      viewportPadding: viewportPadding ?? this.viewportPadding,
      viewportSize: viewportSize ?? this.viewportSize,
      viewportStaticOverlap:
          viewportStaticOverlap ?? this.viewportStaticOverlap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImmutableSheetMetrics &&
          offset == other.offset &&
          minOffset == other.minOffset &&
          maxOffset == other.maxOffset &&
          devicePixelRatio == other.devicePixelRatio &&
          contentBaseline == other.contentBaseline &&
          contentSize == other.contentSize &&
          size == other.size &&
          viewportDynamicOverlap == other.viewportDynamicOverlap &&
          viewportPadding == other.viewportPadding &&
          viewportSize == other.viewportSize &&
          viewportStaticOverlap == other.viewportStaticOverlap;

  @override
  int get hashCode => Object.hash(
        offset,
        minOffset,
        maxOffset,
        devicePixelRatio,
        contentBaseline,
        contentSize,
        size,
        viewportDynamicOverlap,
        viewportPadding,
        viewportSize,
        viewportStaticOverlap,
      );
}

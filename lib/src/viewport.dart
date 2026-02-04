/// @docImport 'decorations.dart';
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// TODO: Remove this import after the minimum sdk version is bumped to 3.35.0
//
// @internal annotation has been included in flutter/foundation.dart since 3.35.0.
// See: https://github.com/flutter/flutter/commit/5706259791de29a27cb68e9b95d6319ba863e366
// ignore: unnecessary_import
import 'package:meta/meta.dart';

import 'model.dart';

/// Geometry of the viewport and the layout constraints
/// used to lay out the sheet and its content.
@immutable
class SheetLayoutSpec {
  /// Creates a layout specification for the sheet and its content.
  const SheetLayoutSpec({
    required this.viewportSize,
    required this.viewportPadding,
    required this.contentMargin,
  });

  /// {@macro ViewportLayout.viewportSize}
  final Size viewportSize;

  /// {@macro ViewportLayout.viewportPadding}
  final EdgeInsets viewportPadding;

  /// {@macro ViewportLayout.contentMargin}
  final EdgeInsets contentMargin;

  /// The maximum rectangle that the sheet can occupy within the viewport.
  ///
  /// The width and bottom of the rectangle are fixed, so only
  /// the height can be adjusted within the constraints.
  ///
  /// The rectangle may extend into the area defined by [viewportPadding] along
  /// the vertical axis, depending on the [SheetDecoration.preferredExtent]
  /// returned by [BareSheet.decoration]. This allows the sheet to
  /// stretch vertically in response to user gestures.
  Rect get maxSheetRect => Rect.fromLTWH(
        viewportPadding.left,
        0,
        viewportSize.width - viewportPadding.horizontal,
        // TODO: Reduce the height by the viewportPadding.vertical
        viewportSize.height,
      );

  /// The maximum rectangle that the sheet's content can occupy
  /// within the viewport.
  ///
  /// Note that this rectangle does not contain the [contentMargin].
  ///
  /// The width and the bottom of the rectangle are fixed, so only
  /// the height can be adjusted within the constraint.
  Rect get maxContentRect => Rect.fromLTWH(
        maxSheetRect.left + contentMargin.left,
        viewportPadding.top + contentMargin.top,
        viewportSize.width -
            viewportPadding.horizontal -
            contentMargin.horizontal,
        viewportSize.height - viewportPadding.vertical - contentMargin.vertical,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SheetLayoutSpec &&
          viewportSize == other.viewportSize &&
          viewportPadding == other.viewportPadding &&
          contentMargin == other.contentMargin;

  @override
  int get hashCode => Object.hash(
        viewportSize,
        viewportPadding,
        contentMargin,
      );
}

typedef SheetLayoutListenable = ValueListenable<SheetLayout?>;

/// Stores the geometry of the viewport and the layout constraints
/// used to lay out the sheet and its content.
///
/// Also reduces the inherited [MediaQueryData.viewPadding],
/// [MediaQueryData.viewInsets], and [MediaQueryData.padding] by
/// the [SheetLayoutSpec.viewportPadding] and [SheetLayoutSpec.contentMargin]
///specified in the [layoutSpec]. This enables the descendant widgets to read
/// that information using [layoutSpecOf] and use it to determine their own
/// layout.
///
/// Intended to be the child of a sheet, and the parent of its content.
class SheetMediaQuery extends StatelessWidget {
  @visibleForTesting
  const SheetMediaQuery({
    super.key,
    required this.layoutSpec,
    required this.layoutNotifier,
    required this.child,
  });

  final SheetLayoutSpec layoutSpec;
  final SheetLayoutListenable layoutNotifier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inheritedMediaQuery = MediaQuery.maybeOf(context);
    final viewportViewPadding =
        inheritedMediaQuery?.viewPadding ?? EdgeInsets.zero;
    final viewPaddingForChild = EdgeInsets.fromLTRB(
      max(
        viewportViewPadding.left -
            layoutSpec.viewportPadding.left -
            layoutSpec.contentMargin.left,
        0.0,
      ),
      max(
        viewportViewPadding.top -
            layoutSpec.viewportPadding.top -
            layoutSpec.contentMargin.top,
        0.0,
      ),
      max(
        viewportViewPadding.right -
            layoutSpec.viewportPadding.right -
            layoutSpec.contentMargin.right,
        0.0,
      ),
      max(
        viewportViewPadding.bottom -
            layoutSpec.viewportPadding.bottom -
            layoutSpec.contentMargin.bottom,
        0.0,
      ),
    );

    final viewportViewInsets =
        inheritedMediaQuery?.viewInsets ?? EdgeInsets.zero;
    final viewInsetsForChild = EdgeInsets.fromLTRB(
      max(
        viewportViewInsets.left -
            layoutSpec.viewportPadding.left -
            layoutSpec.contentMargin.left,
        0.0,
      ),
      max(
        viewportViewInsets.top -
            layoutSpec.viewportPadding.top -
            layoutSpec.contentMargin.top,
        0.0,
      ),
      max(
        viewportViewInsets.right -
            layoutSpec.viewportPadding.right -
            layoutSpec.contentMargin.right,
        0.0,
      ),
      max(
        viewportViewInsets.bottom -
            layoutSpec.viewportPadding.bottom -
            layoutSpec.contentMargin.bottom,
        0.0,
      ),
    );

    final paddingForChild = EdgeInsets.fromLTRB(
      max(viewPaddingForChild.left - viewInsetsForChild.left, 0),
      max(viewPaddingForChild.top - viewInsetsForChild.top, 0),
      max(viewPaddingForChild.right - viewInsetsForChild.right, 0),
      max(viewPaddingForChild.bottom - viewInsetsForChild.bottom, 0),
    );

    return _InheritedSheetMediaQuery(
      layoutSpec: layoutSpec,
      layoutNotifier: layoutNotifier,
      child: MediaQuery(
        data: switch (inheritedMediaQuery) {
          null => MediaQueryData(
              viewPadding: viewPaddingForChild,
              viewInsets: viewInsetsForChild,
              padding: paddingForChild,
            ),
          final inheritedData => inheritedData.copyWith(
              viewPadding: viewPaddingForChild,
              viewInsets: viewInsetsForChild,
              padding: paddingForChild,
            ),
        },
        child: child,
      ),
    );
  }

  /// Reads the [SheetLayoutSpec] from the closest ancestor
  /// [SheetMediaQuery].
  static SheetLayoutSpec layoutSpecOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedSheetMediaQuery>()!
        .layoutSpec;
  }

  /// Reads a [ValueListenable] of [SheetLayout] from the closest ancestor
  /// [SheetMediaQuery].
  static SheetLayoutListenable layoutNotifierOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedSheetMediaQuery>()!
        .layoutNotifier;
  }
}

class _InheritedSheetMediaQuery extends InheritedWidget {
  const _InheritedSheetMediaQuery({
    required this.layoutSpec,
    required this.layoutNotifier,
    required super.child,
  });

  final SheetLayoutSpec layoutSpec;
  final SheetLayoutListenable layoutNotifier;

  @override
  bool updateShouldNotify(_InheritedSheetMediaQuery oldWidget) =>
      layoutSpec != oldWidget.layoutSpec ||
      layoutNotifier != oldWidget.layoutNotifier;
}

class SheetViewport extends StatefulWidget {
  const SheetViewport({
    super.key,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  final EdgeInsets padding;
  final Widget child;

  @override
  State<SheetViewport> createState() => SheetViewportState();
}

@internal
class SheetViewportState extends State<SheetViewport> {
  late final _LazySheetModelView _modelView;

  SheetModelView get model => _modelView;

  void setModel(SheetModel? model) {
    _modelView.setModel(model);
  }

  @override
  void initState() {
    super.initState();
    _modelView = _LazySheetModelView();
  }

  @override
  void dispose() {
    _modelView.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      final ancestorViewport = of(context);
      if (ancestorViewport == null) {
        return true;
      }
      final routeForAncestorViewport = ModalRoute.of(ancestorViewport.context);
      if (ModalRoute.of(context) != routeForAncestorViewport) {
        return true;
      }
      throw AssertionError(
        'Only one SheetViewport widget can exist in the same route.',
      );
    }());

    return _InheritedSheetViewport(
      state: this,
      child: _SheetTranslate(
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }

  static SheetViewportState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedSheetViewport>()
        ?.state;
  }
}

class _InheritedSheetViewport extends InheritedWidget {
  const _InheritedSheetViewport({
    required this.state,
    required super.child,
  });

  final SheetViewportState state;

  @override
  bool updateShouldNotify(_InheritedSheetViewport oldWidget) => true;
}

class _SheetTranslate extends SingleChildRenderObjectWidget {
  const _SheetTranslate({
    required super.child,
    required this.padding,
  });

  final EdgeInsets padding;
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetTranslate(
      model: SheetViewportState.of(context)!._modelView,
      padding: padding,
      viewInsets: MediaQuery.viewInsetsOf(context),
      viewPadding: MediaQuery.viewPaddingOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetTranslate)
      ..model = SheetViewportState.of(context)!._modelView
      ..padding = padding
      ..viewInsets = MediaQuery.viewInsetsOf(context)
      ..viewPadding = MediaQuery.viewPaddingOf(context);
  }
}

class _RenderSheetTranslate extends RenderTransform {
  _RenderSheetTranslate({
    required SheetModelView model,
    required EdgeInsets padding,
    required EdgeInsets viewInsets,
    required EdgeInsets viewPadding,
  })  : _model = model,
        _padding = padding,
        _viewInsets = viewInsets,
        _viewPadding = viewPadding,
        super(
          transform: Matrix4.zero()..setIdentity(),
          transformHitTests: true,
        ) {
    model.addRectListener(_invalidateTransformMatrix);
    _invalidateTransformMatrix();
  }

  SheetModelView _model;

  // ignore: avoid_setters_without_getters
  set model(_LazySheetModelView value) {
    if (value != _model) {
      _model.removeRectListener(_invalidateTransformMatrix);
      _model = value..addRectListener(_invalidateTransformMatrix);
      _invalidateTransformMatrix();
    }
  }

  EdgeInsets _padding;
  // ignore: avoid_setters_without_getters
  set padding(EdgeInsets value) {
    if (_padding != value) {
      _padding = value;
      markNeedsLayout();
    }
  }

  EdgeInsets _viewInsets;
  // ignore: avoid_setters_without_getters
  set viewInsets(EdgeInsets value) {
    if (_viewInsets != value) {
      _viewInsets = value;
      markNeedsLayout();
    }
  }

  EdgeInsets _viewPadding;
  // ignore: avoid_setters_without_getters
  set viewPadding(EdgeInsets value) {
    if (_viewPadding != value) {
      _viewPadding = value;
      markNeedsLayout();
    }
  }

  late Size _lastMeasuredSize;
  @override
  set size(Size value) {
    _lastMeasuredSize = value;
    super.size = value;
  }

  @override
  void performLayout() {
    assert(
      constraints.biggest.isFinite,
      'The SheetViewport must be given a finite constraint.',
    );

    size = constraints.biggest;
    child!.layout(
      _SheetConstraints(
        viewportSize: size,
        viewportInsets: _viewInsets,
        viewportPadding: _padding,
        viewportViewPadding: _viewPadding,
      ),
    );
  }

  void _invalidateTransformMatrix() {
    if (_model.hasMetrics) {
      final dy = _lastMeasuredSize.height - _model.offset;
      // Update the translation value and mark this render object
      // as needing to be repainted.
      transform = Matrix4.translationValues(_padding.left, dy, 0);
    }
  }

  // Mirrors `super._transform` as there is no public getter for it.
  // This should be initialized before the first call to hitTest().
  late Matrix4 _transform;

  @override
  set transform(Matrix4 value) {
    super.transform = value;
    _transform = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_model.shouldIgnorePointer) {
      final invTransform = Matrix4.tryInvert(
        PointerEvent.removePerspectiveTransform(_transform),
      );
      return invTransform != null &&
          size.contains(MatrixUtils.transformPoint(invTransform, position));
    }

    return super.hitTest(result, position: position);
  }

  @override
  void dispose() {
    _model.removeRectListener(_invalidateTransformMatrix);
    super.dispose();
  }
}

@immutable
class _SheetConstraints extends BoxConstraints {
  _SheetConstraints({
    required this.viewportSize,
    required this.viewportInsets,
    required this.viewportPadding,
    required this.viewportViewPadding,
  }) : super(
          maxWidth: viewportSize.width,
          maxHeight: viewportSize.height,
        );

  final Size viewportSize;
  final EdgeInsets viewportInsets;
  final EdgeInsets viewportPadding;
  final EdgeInsets viewportViewPadding;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return super == other &&
        other is _SheetConstraints &&
        viewportSize == other.viewportSize &&
        viewportInsets == other.viewportInsets &&
        viewportPadding == other.viewportPadding &&
        viewportViewPadding == other.viewportViewPadding;
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        viewportSize,
        viewportInsets,
        viewportPadding,
        viewportViewPadding,
      );
}

@immutable
abstract interface class SheetDecoration {
  double preferredExtent(double offset, ViewportLayout layout);
  Widget build(BuildContext context, Widget child);
}

@internal
class DefaultSheetDecoration implements SheetDecoration {
  const DefaultSheetDecoration();

  @override
  double preferredExtent(double offset, ViewportLayout layout) {
    // Returning 0 forces the sheet to size itself to be as small as possible.
    return 0;
  }

  @override
  Widget build(BuildContext context, Widget child) => child;
}

class _DebugAssertSheetDecorationUsage extends SingleChildRenderObjectWidget {
  const _DebugAssertSheetDecorationUsage({
    required this.sheetDecorationType,
    required this.expectedLayoutSpec,
    required super.child,
  });

  final Type sheetDecorationType;
  final SheetLayoutSpec expectedLayoutSpec;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDebugAssertSheetDecorationUsage(
      sheetDecorationType: sheetDecorationType,
      expectedLayoutSpec: expectedLayoutSpec,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderDebugAssertSheetDecorationUsage)
      ..sheetDecorationType = sheetDecorationType
      ..expectedLayoutSpec = expectedLayoutSpec;
  }
}

class _RenderDebugAssertSheetDecorationUsage extends RenderProxyBox {
  _RenderDebugAssertSheetDecorationUsage({
    required Type sheetDecorationType,
    required SheetLayoutSpec expectedLayoutSpec,
  })  : _sheetDecorationType = sheetDecorationType,
        _expectedLayoutSpec = expectedLayoutSpec;

  Type _sheetDecorationType;
  // ignore: avoid_setters_without_getters
  set sheetDecorationType(Type value) {
    if (value != _sheetDecorationType) {
      _sheetDecorationType = value;
      markNeedsLayout();
    }
  }

  SheetLayoutSpec _expectedLayoutSpec;
  // ignore: avoid_setters_without_getters
  set expectedLayoutSpec(SheetLayoutSpec value) {
    if (value != _expectedLayoutSpec) {
      _expectedLayoutSpec = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    if (kReleaseMode) {
      throw StateError(
        'Do not use _DebugAssertSheetShapeUsage widget in release mode.',
      );
    }

    if (constraints.biggest < _expectedLayoutSpec.maxSheetRect.size) {
      throw AssertionError(
        // ignore: lines_longer_than_80_chars
        'The available space for laying out the sheet is smaller than expected. '
        'It is likely that the widget built by the given $_sheetDecorationType '
        // ignore: lines_longer_than_80_chars
        'adds extra padding or margin around the "child" widget (e.g., Padding). '
        'Make sure that the widget returned by the $_sheetDecorationType.build '
        'method always has the same size as the "child" widget.',
      );
    }

    super.performLayout();
  }
}

@internal
class BareSheet extends StatefulWidget {
  const BareSheet({
    super.key,
    this.padding = EdgeInsets.zero,
    this.decoration = const DefaultSheetDecoration(),
    required this.child,
  });

  /// {@template viewport.BareSheet.padding}
  /// The padding around the [child].
  ///
  /// Typically, you want to use this property to push the [child] up
  /// against the software keyboard as it appears, to avoid it being covered.
  ///
  /// ```dart
  /// Sheet(
  ///   padding: EdgeInsets.only(
  ///     bottom: MediaQuery.viewInsetsOf(context).bottom,
  ///   ),
  ///   child: Container(height: 400),
  /// );
  /// ```
  ///
  /// If you want to avoid the screen notches at the bottom only when
  /// the keyboard is closed:
  ///
  /// ```dart
  /// Sheet(
  ///   padding: EdgeInsets.only(
  ///     bottom: math.max(
  ///       MediaQuery.viewInsetsOf(context).bottom,
  ///       MediaQuery.viewPaddingOf(context).bottom,
  ///     ),
  ///   ),
  ///   child: Container(height: 400),
  /// );
  /// ```
  ///
  /// ## Padding widget vs. padding property
  ///
  /// Although wrapping the [child] with a [Padding] widget appears to produce
  /// the same result as the former example, they differ in whether the padding
  /// is included in the [child]'s size calculation; the [Padding] size is
  /// added to the [child]'s size, but the [padding] property is not.
  /// This leads to unexpected behavior depending on whether the keyboard
  /// is open or closed, if you use [SheetOffset]s that depend on the [child]'s
  /// size for controlling the sheet's position, such as animation destinations
  /// and snap positions.
  ///
  /// For example, say we have a sheet with 3 snap offsets where the middle one
  /// is `SheetOffset(0.5)`, and we wrap the [child] with a [Padding]
  /// to avoid the keyboard.
  ///
  /// ```dart
  /// Sheet(
  ///   snapGrid: const SheetSnapGrid(
  ///     snaps: [SheetOffset(0.2), SheetOffset(0.5), SheetOffset(1)],
  ///   ),
  ///   child: Padding(
  ///     padding: EdgeInsets.only(
  ///       bottom: MediaQuery.viewInsetsOf(context).bottom,
  ///     ),
  ///     child: Container(height: 400, color: Colors.red),
  ///   ),
  /// );
  /// ```
  ///
  /// The actual value of `SheetOffset(0.5)` depends on the [child]'s size.
  /// If the keyboard is hidden, the [child]'s height is 400 logical pixels,
  /// so the sheet snaps to 400 * 0.5 = 200 logical pixels from the bottom
  /// of the viewport. If the keyboard is shown, we expect the sheet to snap
  /// to 200 logical pixels from the top of the keyboard for visual consistency.
  /// However, since the [Padding] is part of the [child] and
  /// `MediaQuery.viewInsetsOf(context).bottom` increases as the keyboard
  /// appears (say to 200), the [child]'s height also increases by 200.
  /// `SheetOffset(0.5)` then becomes 600 * 0.5 = 300 logical pixels.
  /// This means the sheet snaps to 100 logical pixels above the keyboard,
  /// which is 100 logical pixels below our expectation (200 logical pixels
  /// above the keyboard).
  ///
  /// In contrast, the blank space the [padding] property creates does not add
  /// to the [child]'s size, so `SheetOffset(0.5)` is always 200 regardless
  /// of the keyboard height (unless the available height for the [child] is
  /// less than 400, more precisely), meaning the sheet snaps to 200 logical
  /// pixels from the bottom of the viewport when the keyboard is hidden, and
  /// 200 logical pixels from the top of the keyboard when it is shown.
  ///
  /// For this reason, using the [padding] property is always preferable
  /// to using a [Padding] widget to avoid the keyboard, unless you know
  /// exactly what you are doing.
  ///
  /// ## SheetViewport.padding vs. padding property
  ///
  /// Specifying `MediaQuery.viewInsetsOf(context).bottom` to
  /// the [SheetViewport.padding] is another option to prevent the [child]
  /// from being overlapped by the keyboard. It pushes the sheet itself up
  /// above the keyboard, which differs from the [padding] property that
  /// only pushes up the [child].
  ///
  /// ```dart
  /// SheetViewport(
  ///   padding: EdgeInsets.only(
  ///     bottom: MediaQuery.viewInsetsOf(context).bottom,
  ///   ),
  ///   child: Sheet(...),
  /// );
  /// ```
  ///
  /// Since this approach does not cause the `SheetOffset` problem described
  /// in the previous section, and the [SheetViewport.padding] and the [padding]
  /// property create two distinct sheet appearances, both options are valid,
  /// and the choice depends on your use case.
  /// {@endtemplate}
  final EdgeInsets padding;

  final SheetDecoration decoration;

  final Widget child;

  @override
  State<BareSheet> createState() => _BareSheetState();
}

class _BareSheetState extends State<BareSheet> {
  late final ValueNotifier<SheetLayout?> _layoutNotifier;

  @override
  void initState() {
    super.initState();
    _layoutNotifier = ValueNotifier(null);
  }

  @override
  void dispose() {
    _layoutNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        assert(
          constraints is _SheetConstraints,
          'This error was likely caused either by the sheet being wrapped '
          'in a widget that adds extra margin around it (e.g. Padding), '
          'or by there is no SheetViewport in the ancestors of the sheet.',
        );

        final sheetConstraints = constraints as _SheetConstraints;
        final layoutSpec = SheetLayoutSpec(
          viewportSize: sheetConstraints.viewportSize,
          viewportPadding: sheetConstraints.viewportPadding,
          contentMargin: widget.padding,
        );

        Widget result = _SheetSkelton(
          layoutNotifier: _layoutNotifier,
          layoutSpec: layoutSpec,
          getPreferredExtent: widget.decoration.preferredExtent,
          child: SheetMediaQuery(
            layoutSpec: layoutSpec,
            layoutNotifier: _layoutNotifier,
            child: widget.child,
          ),
        );

        assert(() {
          result = _DebugAssertSheetDecorationUsage(
            sheetDecorationType: widget.decoration.runtimeType,
            expectedLayoutSpec: layoutSpec,
            child: result,
          );
          return true;
        }());

        return widget.decoration.build(context, result);
      },
    );
  }
}

typedef _GetPreferredExtent = double Function(double, ViewportLayout);

class _SheetSkelton extends SingleChildRenderObjectWidget {
  const _SheetSkelton({
    required this.layoutSpec,
    required this.layoutNotifier,
    required this.getPreferredExtent,
    required super.child,
  });

  final SheetLayoutSpec layoutSpec;
  final ValueNotifier<SheetLayout?> layoutNotifier;
  final _GetPreferredExtent getPreferredExtent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetSkelton(
      layoutNotifier: layoutNotifier,
      layoutSpec: layoutSpec,
      getPreferredExtent: getPreferredExtent,
      model: SheetViewportState.of(context)!._modelView,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetSkelton)
      ..layoutNotifier = layoutNotifier
      ..sheetMediaQueryData = layoutSpec
      ..getPreferredExtent = getPreferredExtent
      ..model = SheetViewportState.of(context)!._modelView;
  }
}

class _RenderSheetSkelton extends RenderShiftedBox {
  _RenderSheetSkelton({
    required this.layoutNotifier,
    required _LazySheetModelView model,
    required SheetLayoutSpec layoutSpec,
    required _GetPreferredExtent getPreferredExtent,
  })  : _model = model,
        _layoutSpec = layoutSpec,
        _getPreferredExtent = getPreferredExtent,
        super(null) {
    model.addListener(_invalidatePreferredExtent);
    _invalidatePreferredExtent();
  }

  ValueNotifier<SheetLayout?> layoutNotifier;

  _LazySheetModelView _model;
  // ignore: avoid_setters_without_getters
  set model(_LazySheetModelView value) {
    if (value != _model) {
      _model.removeListener(_invalidatePreferredExtent);
      _model = value..addListener(_invalidatePreferredExtent);
      _invalidatePreferredExtent();
      markNeedsLayout();
    }
  }

  SheetLayoutSpec _layoutSpec;
  // ignore: avoid_setters_without_getters
  set sheetMediaQueryData(SheetLayoutSpec value) {
    if (value != _layoutSpec) {
      _layoutSpec = value;
      markNeedsLayout();
    }
  }

  _GetPreferredExtent _getPreferredExtent;
  // ignore: avoid_setters_without_getters
  set getPreferredExtent(_GetPreferredExtent value) {
    if (value != _getPreferredExtent) {
      _getPreferredExtent = value;
      markNeedsLayout();
    }
  }

  double? _preferredExtent;

  void _invalidatePreferredExtent() {
    if (_model.hasMetrics) {
      final oldPreferredExtent = _preferredExtent;
      _preferredExtent = _getPreferredExtent(_model.offset, _model);
      if (oldPreferredExtent != _preferredExtent && !_isPerformingLayout) {
        markNeedsLayout();
      }
    }
  }

  @override
  void dispose() {
    _model.removeListener(_invalidatePreferredExtent);
    super.dispose();
  }

  /// Indicates whether it is in the middle of performLayout().
  ///
  /// Updating SheetModel.measurements in performLayout() will
  /// eventually trigger a call to _invalidatePreferredExtent(),
  /// which may cause markNeedsLayout() to be invoked. However,
  /// doing so in the middle of layout phase is not allowed.
  ///
  /// To avoid this, we need to track whether it is in the middle
  /// of layout phase, and check the flag before invoking markNeedsLayout().
  var _isPerformingLayout = false;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      return super.performLayout();
    }

    _isPerformingLayout = true;

    final maxChildRect = _layoutSpec.maxContentRect;
    final maxChildSize = maxChildRect.size;
    child.layout(
      BoxConstraints(
        minWidth: maxChildSize.width,
        maxWidth: maxChildSize.width,
        maxHeight: maxChildSize.height,
      ),
      parentUsesSize: true,
    );
    (child.parentData! as BoxParentData).offset =
        _layoutSpec.contentMargin.topLeft;

    assert(_model._inner != null);
    final viewportLayout = ImmutableViewportLayout(
      contentSize: Size.copy(child.size),
      viewportSize: _layoutSpec.viewportSize,
      viewportPadding: _layoutSpec.viewportPadding,
      contentBaseline:
          _layoutSpec.viewportSize.height - _layoutSpec.maxContentRect.bottom,
      contentMargin: _layoutSpec.contentMargin,
    );
    final newOffset = _model._inner!.dryApplyNewLayout(viewportLayout);
    _preferredExtent = _getPreferredExtent(newOffset, viewportLayout);
    final maxRect = _layoutSpec.maxSheetRect;
    final maxSize = maxRect.size;
    final paddedChildSize = _layoutSpec.contentMargin.inflateSize(child.size);
    size = BoxConstraints(
      minWidth: maxSize.width,
      maxWidth: maxSize.width,
      minHeight: paddedChildSize.height,
      maxHeight: maxSize.height,
    ).constrain(Size.fromHeight(_preferredExtent!));

    final newLayout = ImmutableSheetLayout.from(
      viewportLayout: viewportLayout,
      size: Size.copy(size),
    );
    _model._inner!.applyNewLayout(newLayout);
    assert(_model._inner!.hasMetrics);
    layoutNotifier.value = newLayout;

    _isPerformingLayout = false;
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      final outerRect = offset & size;
      debugPaintPadding(
        context.canvas,
        outerRect,
        switch (child) {
          null => null,
          final child => Offset.zero & child.size,
        },
      );
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('layoutSpec', _layoutSpec));
  }
}

class _LazySheetModelView extends SheetModelView with ChangeNotifier {
  SheetModel? _inner;
  final _rectNotifier = ChangeNotifier();

  void setModel(SheetModel? newModel) {
    if (newModel != _inner) {
      final oldOffset = _inner?.offset;
      final oldRect = _inner?.rect;
      _inner
        ?..removeListener(notifyListeners)
        ..removeRectListener(_rectNotifier.notifyListeners);
      _inner = newModel
        ?..addListener(notifyListeners)
        ..addRectListener(_rectNotifier.notifyListeners);

      if (newModel
          case SheetModel(
            hasMetrics: true,
            :final offset,
            :final rect,
          )) {
        if (offset != oldOffset) {
          notifyListeners();
        }
        if (rect != oldRect) {
          _rectNotifier.notifyListeners();
        }
      }
    }
  }

  @override
  void dispose() {
    _inner?.removeListener(notifyListeners);
    _inner = null;
    _rectNotifier.dispose();
    super.dispose();
  }

  @override
  void addRectListener(VoidCallback listener) {
    _rectNotifier.addListener(listener);
  }

  @override
  void removeRectListener(VoidCallback listener) {
    _rectNotifier.removeListener(listener);
  }

  @override
  bool get hasMetrics => _inner?.hasMetrics ?? false;

  @override
  bool get shouldIgnorePointer => _inner?.shouldIgnorePointer ?? false;

  @override
  double get devicePixelRatio => _inner!.devicePixelRatio;

  @override
  double get maxOffset => _inner!.maxOffset;

  @override
  double get minOffset => _inner!.minOffset;

  @override
  double get offset => _inner!.offset;

  @override
  double get contentBaseline => _inner!.contentBaseline;

  @override
  Size get contentSize => _inner!.contentSize;

  @override
  EdgeInsets get contentMargin => _inner!.contentMargin;

  @override
  Size get size => _inner!.size;

  @override
  EdgeInsets get viewportPadding => _inner!.viewportPadding;

  @override
  Size get viewportSize => _inner!.viewportSize;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? size,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportPadding,
    double? contentBaseline,
    EdgeInsets? contentMargin,
    double? devicePixelRatio,
  }) {
    return ImmutableSheetMetrics(
      offset: offset ?? _inner!.offset,
      minOffset: minOffset ?? _inner!.minOffset,
      maxOffset: maxOffset ?? _inner!.maxOffset,
      devicePixelRatio: devicePixelRatio ?? _inner!.devicePixelRatio,
      contentBaseline: contentBaseline ?? _inner!.contentBaseline,
      contentMargin: contentMargin ?? _inner!.contentMargin,
      contentSize: contentSize ?? _inner!.contentSize,
      size: size ?? _inner!.size,
      viewportPadding: viewportPadding ?? _inner!.viewportPadding,
      viewportSize: viewportSize ?? _inner!.viewportSize,
    );
  }
}

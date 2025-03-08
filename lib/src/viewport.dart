import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'model.dart';

/// Stores the geometry of the viewport and the layout constraints
/// used to lay out the sheet and its content.
///
/// Also overwrites the inherited [MediaQueryData.viewPadding] and
/// [MediaQueryData.viewInsets] with [SheetLayoutSpec.maxContentStaticOverlap]
/// and [SheetLayoutSpec.maxContentDynamicOverlap] specified in the
/// [layoutSpec], respectively. This enables the descendant widgets to read
/// that information using [layoutSpecOf] and use it to determine their own
/// layout.
///
/// Intended to be the child of a sheet, and the parent of its content.
class SheetMediaQuery extends StatelessWidget {
  @visibleForTesting
  const SheetMediaQuery({
    super.key,
    required this.layoutSpec,
    required this.child,
  });

  final SheetLayoutSpec layoutSpec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewPaddingForChild = layoutSpec.maxContentStaticOverlap;
    final viewInsetsForChild = layoutSpec.maxContentDynamicOverlap;
    final paddingForChild = EdgeInsets.fromLTRB(
      max(viewPaddingForChild.left - viewInsetsForChild.left, 0),
      max(viewPaddingForChild.top - viewInsetsForChild.top, 0),
      max(viewPaddingForChild.right - viewInsetsForChild.right, 0),
      max(viewPaddingForChild.bottom - viewInsetsForChild.bottom, 0),
    );

    return _InheritedSheetMediaQuery(
      layoutSpec: layoutSpec,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewPadding: viewPaddingForChild,
          viewInsets: viewInsetsForChild,
          padding: paddingForChild,
        ),
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
}

class _InheritedSheetMediaQuery extends InheritedWidget {
  const _InheritedSheetMediaQuery({
    required this.layoutSpec,
    required super.child,
  });

  final SheetLayoutSpec layoutSpec;

  @override
  bool updateShouldNotify(_InheritedSheetMediaQuery oldWidget) =>
      layoutSpec != oldWidget.layoutSpec;
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
    model.addListener(_invalidateTransformMatrix);
    _invalidateTransformMatrix();
  }

  // TODO: Change the type to `ValueListenable<double>`
  SheetModelView _model;
  // ignore: avoid_setters_without_getters
  set model(_LazySheetModelView value) {
    if (value != _model) {
      _model.removeListener(_invalidateTransformMatrix);
      _model = value..addListener(_invalidateTransformMatrix);
      _invalidateTransformMatrix();
    }
  }

  EdgeInsets _padding;
  // ignore: avoid_setters_without_getters
  set padding(EdgeInsets value) {
    if (_padding != value) {
      _padding = value;
      _invalidateTransformMatrix();
    }
  }

  EdgeInsets _viewInsets;
  // ignore: avoid_setters_without_getters
  set viewInsets(EdgeInsets value) {
    if (_viewInsets != value) {
      _viewInsets = value;
      _invalidateTransformMatrix();
    }
  }

  EdgeInsets _viewPadding;
  // ignore: avoid_setters_without_getters
  set viewPadding(EdgeInsets value) {
    if (_viewPadding != value) {
      _viewPadding = value;
      _invalidateTransformMatrix();
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
    _model.removeListener(_invalidateTransformMatrix);
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
          minWidth: viewportSize.width - viewportPadding.horizontal,
          maxWidth: viewportSize.width - viewportPadding.horizontal,
          maxHeight: viewportSize.height - viewportPadding.vertical,
        );

  final Size viewportSize;
  final EdgeInsets viewportInsets;
  final EdgeInsets viewportPadding;
  final EdgeInsets viewportViewPadding;
}

@internal
class BareSheet extends StatelessWidget {
  const BareSheet({
    super.key,
    this.resizeChildToAvoidBottomOverlap = true,
    required this.child,
  });

  final bool resizeChildToAvoidBottomOverlap;
  final Widget child;

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
          viewportDynamicOverlap: sheetConstraints.viewportInsets,
          viewportStaticOverlap: sheetConstraints.viewportViewPadding,
          resizeContentToAvoidBottomOverlap: resizeChildToAvoidBottomOverlap,
        );

        return _SheetSkelton(
          layoutSpec: layoutSpec,
          child: SheetMediaQuery(
            layoutSpec: layoutSpec,
            child: child,
          ),
        );
      },
    );
  }
}

class _SheetSkelton extends SingleChildRenderObjectWidget {
  const _SheetSkelton({
    required this.layoutSpec,
    required super.child,
  });

  final SheetLayoutSpec layoutSpec;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetSkelton(
      layoutSpec: layoutSpec,
      model: SheetViewportState.of(context)!._modelView,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetSkelton)
      ..sheetMediaQueryData = layoutSpec
      ..model = SheetViewportState.of(context)!._modelView;
  }
}

class _RenderSheetSkelton extends RenderShiftedBox {
  _RenderSheetSkelton({
    required _LazySheetModelView model,
    required SheetLayoutSpec layoutSpec,
  })  : _model = model,
        _layoutSpec = layoutSpec,
        super(null) {
    model.addListener(_invalidatePreferredExtent);
    _invalidatePreferredExtent();
  }

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

  double? _preferredExtent;

  void _invalidatePreferredExtent() {
    if (_model.hasMetrics) {
      final oldPreferredExtent = _preferredExtent;
      _preferredExtent = _computePreferredExtent(_model.offset);
      if (oldPreferredExtent != _preferredExtent && !_isPerformingLayout) {
        markNeedsLayout();
      }
    }
  }

  double _computePreferredExtent(double offset) {
    final sheetTop = _layoutSpec.viewportSize.height - offset;
    return max(_layoutSpec.maxSheetRect.bottom - sheetTop, 0.0);
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
  bool _isPerformingLayout = false;

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

    assert(_model._inner != null);
    final viewportLayout = ImmutableViewportLayout.from(
      layoutSpec: _layoutSpec,
      contentSize: Size.copy(child.size),
    );
    final newOffset = _model._inner!.dryApplyLayout(viewportLayout);
    _preferredExtent = _computePreferredExtent(newOffset);
    final maxRect = _layoutSpec.maxSheetRect;
    final maxSize = maxRect.size;
    final bottomPadding = maxChildRect.bottom - maxRect.bottom;
    size = BoxConstraints(
      minWidth: maxSize.width,
      maxWidth: maxSize.width,
      minHeight: child.size.height + bottomPadding,
      maxHeight: maxSize.height,
    ).constrain(Size.fromHeight(_preferredExtent!));
    _model._inner!.applyNewLayout(
      ImmutableSheetLayout.from(
        viewportLayout: viewportLayout,
        size: Size.copy(size),
      ),
    );
    assert(_model._inner!.hasMetrics);

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

  void setModel(SheetModel? newModel) {
    if (newModel != _inner) {
      final oldValue = _inner?.offset;
      _inner?.removeListener(notifyListeners);
      _inner = newModel?..addListener(notifyListeners);
      if (newModel case SheetModel(hasMetrics: true, :final offset)
          when offset != oldValue) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _inner?.removeListener(notifyListeners);
    _inner = null;
    super.dispose();
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
  Size get size => _inner!.size;

  @override
  EdgeInsets get viewportDynamicOverlap => _inner!.viewportDynamicOverlap;

  @override
  EdgeInsets get viewportPadding => _inner!.viewportPadding;

  @override
  Size get viewportSize => _inner!.viewportSize;

  @override
  EdgeInsets get viewportStaticOverlap => _inner!.viewportStaticOverlap;

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
      offset: offset ?? _inner!.offset,
      minOffset: minOffset ?? _inner!.minOffset,
      maxOffset: maxOffset ?? _inner!.maxOffset,
      devicePixelRatio: devicePixelRatio ?? _inner!.devicePixelRatio,
      contentBaseline: contentBaseline ?? _inner!.contentBaseline,
      contentSize: contentSize ?? _inner!.contentSize,
      size: size ?? _inner!.size,
      viewportDynamicOverlap:
          viewportDynamicOverlap ?? _inner!.viewportDynamicOverlap,
      viewportPadding: viewportPadding ?? _inner!.viewportPadding,
      viewportSize: viewportSize ?? _inner!.viewportSize,
      viewportStaticOverlap:
          viewportStaticOverlap ?? _inner!.viewportStaticOverlap,
    );
  }
}

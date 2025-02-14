import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'model.dart';

mixin _MeasurementPipeline {
  late Size _lastMeasuredViewportSize;
  late Size _lastMeasuredContentSize;
  late EdgeInsets _lastMeasuredViewportPadding;
  late EdgeInsets _lastMeasuredContentMargin;
  void _flushMeasurements();
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
class SheetViewportState extends State<SheetViewport>
    with _MeasurementPipeline {
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
  void _flushMeasurements() {
    assert(_modelView._inner != null);
    _modelView._inner!.measurements = Measurements(
      viewportSize: _lastMeasuredViewportSize,
      viewportPadding: _lastMeasuredViewportPadding,
      contentSize: _lastMeasuredContentSize,
      contentMargin: _lastMeasuredContentMargin,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.padding == EdgeInsets.zero) {
      return _InheritedSheetViewport(
        state: this,
        child: _SheetTranslate(
          padding: EdgeInsets.zero,
          child: widget.child,
        ),
      );
    }

    final inheritedViewInsets = MediaQuery.viewInsetsOf(context);
    final viewInsetsForChild = EdgeInsets.fromLTRB(
      max(inheritedViewInsets.left - widget.padding.left, 0),
      max(inheritedViewInsets.top - widget.padding.top, 0),
      max(inheritedViewInsets.right - widget.padding.right, 0),
      max(inheritedViewInsets.bottom - widget.padding.bottom, 0),
    );
    final inheritedPadding = MediaQuery.paddingOf(context);
    final paddingForChild = EdgeInsets.fromLTRB(
      max(inheritedPadding.left - widget.padding.left, 0),
      max(inheritedPadding.top - widget.padding.top, 0),
      max(inheritedPadding.right - widget.padding.right, 0),
      max(inheritedPadding.bottom - widget.padding.bottom, 0),
    );
    final inheritedViewPadding = MediaQuery.viewPaddingOf(context);
    final viewPaddingForChild = EdgeInsets.fromLTRB(
      max(inheritedViewPadding.left - widget.padding.left, 0),
      max(inheritedViewPadding.top - widget.padding.top, 0),
      max(inheritedViewPadding.right - widget.padding.right, 0),
      max(inheritedViewPadding.bottom - widget.padding.bottom, 0),
    );

    return _InheritedSheetViewport(
      state: this,
      child: _SheetTranslate(
        padding: widget.padding,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewInsets: viewInsetsForChild,
            padding: paddingForChild,
            viewPadding: viewPaddingForChild,
          ),
          child: widget.child,
        ),
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
      measurementPipeline: SheetViewportState.of(context)!,
      padding: padding,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetTranslate)
      ..model = SheetViewportState.of(context)!._modelView
      ..measurementPipeline = SheetViewportState.of(context)!
      ..padding = padding;
  }
}

class _RenderSheetTranslate extends RenderTransform {
  _RenderSheetTranslate({
    required SheetModelView model,
    required _MeasurementPipeline measurementPipeline,
    required EdgeInsets padding,
  })  : _model = model,
        _measurementPipeline = measurementPipeline,
        _padding = padding,
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

  _MeasurementPipeline _measurementPipeline;

  // ignore: avoid_setters_without_getters
  set measurementPipeline(_MeasurementPipeline value) {
    if (value != _measurementPipeline) {
      _measurementPipeline = value;
      markNeedsLayout();
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

    _measurementPipeline
      .._lastMeasuredViewportPadding = _padding
      .._lastMeasuredViewportSize = Size.copy(constraints.biggest);
    size = constraints.biggest;
    child!.layout(constraints.loosen().deflate(_padding));
  }

  void _invalidateTransformMatrix() {
    if (_model.hasMetrics) {
      final dy = _lastMeasuredSize.height - _model.viewOffset;
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

@internal
class BareSheet extends StatelessWidget {
  const BareSheet({
    super.key,
    required this.child,
    this.resizeChildToAvoidViewInsets = true,
  });

  final Widget child;
  final bool resizeChildToAvoidViewInsets;

  @override
  Widget build(BuildContext context) {
    if (resizeChildToAvoidViewInsets) {
      return _SheetSkelton(
        padding: MediaQuery.viewInsetsOf(context),
        child: MediaQuery.removeViewInsets(
          context: context,
          child: child,
        ),
      );
    } else {
      return _SheetSkelton(
        padding: EdgeInsets.zero,
        child: child,
      );
    }
  }
}

class _SheetSkelton extends SingleChildRenderObjectWidget {
  const _SheetSkelton({
    required super.child,
    required this.padding,
  });

  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetSkelton(
      padding: padding,
      measurementPipeline: SheetViewportState.of(context)!,
      model: SheetViewportState.of(context)!._modelView,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetSkelton)
      ..padding = padding
      ..measurementPipeline = SheetViewportState.of(context)!
      ..model = SheetViewportState.of(context)!._modelView;
  }
}

class _RenderSheetSkelton extends RenderShiftedBox {
  _RenderSheetSkelton({
    required _LazySheetModelView model,
    required EdgeInsets padding,
    required _MeasurementPipeline measurementPipeline,
  })  : _model = model,
        _padding = padding,
        _measurementPipeline = measurementPipeline,
        super(null) {
    model.addListener(_updatePreferredSize);
    _updatePreferredSize();
  }

  _LazySheetModelView _model;
  // ignore: avoid_setters_without_getters
  set model(_LazySheetModelView value) {
    if (value != _model) {
      _model.removeListener(_updatePreferredSize);
      _model = value..addListener(_updatePreferredSize);
      _updatePreferredSize();
      markNeedsLayout();
    }
  }

  _MeasurementPipeline _measurementPipeline;
  // ignore: avoid_setters_without_getters
  set measurementPipeline(_MeasurementPipeline value) {
    _measurementPipeline = value;
    markNeedsLayout();
  }

  EdgeInsets _padding;
  // ignore: avoid_setters_without_getters
  set padding(EdgeInsets value) {
    _padding = value;
    markNeedsLayout();
  }

  bool _isPerformingLayout = false;
  Size? _preferredSize;

  void _updatePreferredSize() {
    if (_model.hasMetrics) {
      final preferredSize = Size.fromHeight(
        max(_model.viewOffset - _model.measurements.viewportPadding.bottom, 0),
      );
      final oldPreferredSize = _preferredSize;
      _preferredSize = preferredSize;
      if (oldPreferredSize != preferredSize && !_isPerformingLayout) {
        markNeedsLayout();
      }
    }
  }

  @override
  void dispose() {
    _model.removeListener(_updatePreferredSize);
    super.dispose();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      return super.performLayout();
    }

    assert(_model._inner != null);
    assert(constraints.biggest.isFinite);
    assert(!constraints.isTight);

    _isPerformingLayout = true;

    final maxSize = constraints.biggest;
    final maxContentSize = _padding.deflateSize(maxSize);

    assert(
      maxSize ==
          _measurementPipeline._lastMeasuredViewportPadding
              .deflateSize(_measurementPipeline._lastMeasuredViewportSize),
      'The maximum size of the sheet is smaller than the expected size. '
      'This is likely because the sheet is wrapped by a widget that adds extra '
      'margin around it (e.g. Padding).',
    );

    (child.parentData! as BoxParentData).offset = _padding.topLeft;
    child.layout(
      BoxConstraints(
        minWidth: maxContentSize.width,
        maxWidth: maxContentSize.width,
        maxHeight: maxContentSize.height,
      ),
      parentUsesSize: true,
    );

    _measurementPipeline
      .._lastMeasuredContentSize = Size.copy(child.size)
      .._lastMeasuredContentMargin = _padding
      .._flushMeasurements();
    assert(_preferredSize != null);

    final minSize = _padding.inflateSize(child.size);
    size = BoxConstraints(
      minWidth: minSize.width,
      maxWidth: maxSize.width,
      minHeight: minSize.height,
      maxHeight: maxSize.height,
    ).constrain(_preferredSize!);

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
        child != null ? _padding.deflateRect(outerRect) : null,
      );
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('padding', _padding));
  }
}

class _LazySheetModelView extends SheetModelView with ChangeNotifier {
  SheetModel? _inner;

  void setModel(SheetModel? newModel) {
    if (newModel != _inner) {
      final oldValue = value;
      _inner?.removeListener(notifyListeners);
      _inner = newModel?..addListener(notifyListeners);
      final newValue = value;
      if (oldValue != newValue) {
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
  SheetGeometry? get value => _inner?.value;

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
  Measurements get measurements => _inner!.measurements;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Measurements? measurements,
    double? devicePixelRatio,
  }) {
    return _inner!.copyWith(
      offset: offset,
      minOffset: minOffset,
      maxOffset: maxOffset,
      measurements: measurements,
      devicePixelRatio: devicePixelRatio,
    );
  }
}

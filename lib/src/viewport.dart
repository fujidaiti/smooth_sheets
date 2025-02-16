import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'model.dart';

mixin _MeasurementPipeline {
  late double _lastMeasuredViewportExtent;
  late double _lastMeasuredContentExtent;
  late double _lastMeasuredBaseline;
  late double _lastMeasuredContentBaseline;
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
      viewportExtent: _lastMeasuredViewportExtent,
      contentExtent: _lastMeasuredContentExtent,
      contentBaseline: _lastMeasuredContentBaseline,
      baseline: _lastMeasuredBaseline,
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
      .._lastMeasuredBaseline = _padding.bottom
      .._lastMeasuredViewportExtent = constraints.biggest.height;
    size = constraints.biggest;
    child!.layout(constraints.loosen().deflate(_padding));
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

@internal
class BareSheet extends StatelessWidget {
  const BareSheet({
    super.key,
    required this.child,
    this.resizeChildToAvoidBottomInsets = true,
  });

  final Widget child;
  final bool resizeChildToAvoidBottomInsets;

  @override
  Widget build(BuildContext context) {
    if (resizeChildToAvoidBottomInsets) {
      return _SheetSkelton(
        bottomPadding: MediaQuery.viewInsetsOf(context).bottom,
        child: MediaQuery.removeViewInsets(
          removeBottom: true,
          context: context,
          child: child,
        ),
      );
    } else {
      return _SheetSkelton(
        bottomPadding: 0,
        child: child,
      );
    }
  }
}

class _SheetSkelton extends SingleChildRenderObjectWidget {
  const _SheetSkelton({
    required super.child,
    required this.bottomPadding,
  });

  final double bottomPadding;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetSkelton(
      bottomPadding: bottomPadding,
      measurementPipeline: SheetViewportState.of(context)!,
      model: SheetViewportState.of(context)!._modelView,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetSkelton)
      ..bottomPadding = bottomPadding
      ..measurementPipeline = SheetViewportState.of(context)!
      ..model = SheetViewportState.of(context)!._modelView;
  }
}

class _RenderSheetSkelton extends RenderShiftedBox {
  _RenderSheetSkelton({
    required _LazySheetModelView model,
    required double bottomPadding,
    required _MeasurementPipeline measurementPipeline,
  })  : _model = model,
        _bottomPadding = bottomPadding,
        _measurementPipeline = measurementPipeline,
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

  _MeasurementPipeline _measurementPipeline;
  // ignore: avoid_setters_without_getters
  set measurementPipeline(_MeasurementPipeline value) {
    _measurementPipeline = value;
    markNeedsLayout();
  }

  double _bottomPadding;
  // ignore: avoid_setters_without_getters
  set bottomPadding(double value) {
    _bottomPadding = value;
    markNeedsLayout();
  }

  double? _preferredExtent;

  void _invalidatePreferredExtent() {
    if (_model.hasMetrics) {
      final preferredExtent =
          max(_model.offset - _model.measurements.baseline, 0.0);
      final oldPreferredExtent = _preferredExtent;
      _preferredExtent = preferredExtent;
      if (oldPreferredExtent != preferredExtent && !_isPerformingLayout) {
        markNeedsLayout();
      }
    }
  }

  @override
  void dispose() {
    _model.removeListener(_invalidatePreferredExtent);
    super.dispose();
  }

  bool _isPerformingLayout = false;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      return super.performLayout();
    }

    assert(_model._inner != null);
    assert(constraints.biggest.isFinite);
    assert(!constraints.isTight);
    assert(() {
      bool debugCheckAncestor(RenderObject? ancestor) {
        switch (ancestor) {
          case null:
            throw AssertionError(
              'No SheetViewport found in the ancestors of the sheet.',
            );

          case final _RenderSheetTranslate viewport
              when constraints.biggest !=
                  viewport._padding.deflateSize(viewport._lastMeasuredSize):
            throw AssertionError(
              // ignore: lines_longer_than_80_chars
              'The maximum size of the sheet is smaller than the expected size. '
              'This is likely because the sheet is wrapped by a widget that '
              'adds extra margin around it (e.g. Padding).',
            );

          case final _RenderSheetTranslate _:
            return true;

          case _:
            return false;
        }
      }

      var ancestor = parent;
      while (!debugCheckAncestor(ancestor)) {
        ancestor = ancestor?.parent;
      }
      return true;
    }());

    _isPerformingLayout = true;

    child.layout(
      BoxConstraints(
        minWidth: constraints.maxWidth,
        maxWidth: constraints.maxWidth,
        maxHeight: max(constraints.maxHeight - _bottomPadding, 0.0),
      ),
      parentUsesSize: true,
    );

    _measurementPipeline
      .._lastMeasuredContentExtent = child.size.height
      .._lastMeasuredContentBaseline =
          _measurementPipeline._lastMeasuredBaseline + _bottomPadding
      .._flushMeasurements();
    assert(_preferredExtent != null);

    size = BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
      minHeight: child.size.height + _bottomPadding,
      maxHeight: constraints.maxHeight,
    ).constrain(Size.fromHeight(_preferredExtent!));

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
    properties.add(DiagnosticsProperty('bottomPadding', _bottomPadding));
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

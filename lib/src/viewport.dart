import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'model.dart';

class SheetViewport extends StatefulWidget {
  const SheetViewport({
    super.key,
    this.ignoreViewInsets = false,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  final bool ignoreViewInsets;
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
    Widget result = _InheritedSheetViewport(
      state: this,
      child: _RenderSheetViewportWidget(
        model: _modelView,
        viewInsets: MediaQuery.viewInsetsOf(context),
        padding: widget.padding,
        child: widget.child,
      ),
    );

    if (widget.ignoreViewInsets) {
      result = MediaQuery.removeViewInsets(
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        context: context,
        child: result,
      );
    }

    return result;
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

class _RenderSheetViewportWidget extends SingleChildRenderObjectWidget {
  const _RenderSheetViewportWidget({
    required this.model,
    required this.viewInsets,
    required this.padding,
    required super.child,
  });

  final _LazySheetModelView model;
  final EdgeInsets viewInsets;
  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetViewport(
      model: model,
      viewInsets: viewInsets,
      padding: padding,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetViewport)
      ..model = model
      ..viewInsets = viewInsets
      ..padding = padding;
  }
}

class _RenderSheetViewport extends RenderTransform {
  _RenderSheetViewport({
    required _LazySheetModelView model,
    required EdgeInsets viewInsets,
    required EdgeInsets padding,
  })  : _model = model,
        _viewInsets = viewInsets,
        _padding = padding,
        super(
          transform: Matrix4.zero()..setIdentity(),
          transformHitTests: true,
        ) {
    model.addListener(_invalidateTransformMatrix);
    _invalidateTransformMatrix();
  }

  _LazySheetModelView _model;
  // ignore: avoid_setters_without_getters
  set model(_LazySheetModelView value) {
    if (value != _model) {
      _model.removeListener(_invalidateTransformMatrix);
      _model = value..addListener(_invalidateTransformMatrix);
      _invalidateTransformMatrix();
    }
  }

  EdgeInsets _viewInsets;
  // ignore: avoid_setters_without_getters
  set viewInsets(EdgeInsets value) {
    if (value != _viewInsets) {
      _viewInsets = value;
      markNeedsLayout();
    }
  }

  EdgeInsets _padding;
  // ignore: avoid_setters_without_getters
  set padding(EdgeInsets value) {
    if (value != _padding) {
      _padding = value;
      markNeedsLayout();
    }
  }

  late Size _lastMeasuredSize;

  @override
  set size(Size value) {
    _lastMeasuredSize = Size.copy(value);
    super.size = value;
  }

  // Initialized in performLayout().
  late double _baseline;

  @override
  void performLayout() {
    assert(
      _model._inner != null,
      'The model object must be attached to the SheetViewport '
      'before the first layout phase.',
    );
    assert(
      constraints.biggest.isFinite,
      'The SheetViewport must be given a finite constraint.',
    );

    size = constraints.biggest;
    child!.layout(
      _SheetConstraints(
        minWidth: max(size.width - _padding.horizontal, 0),
        maxWidth: max(size.width - _padding.horizontal, 0),
        minHeight: 0,
        maxHeight: max(size.height - _padding.vertical, 0),
        viewInsets: EdgeInsets.fromLTRB(
          max(_viewInsets.left - _padding.left, 0),
          max(_viewInsets.top - _padding.top, 0),
          max(_viewInsets.right - _padding.right, 0),
          max(_viewInsets.bottom - _padding.bottom, 0),
        ),
      ),
      parentUsesSize: true,
    );

    _RenderSheet? renderSheet;
    void findRenderSheet(RenderObject child) {
      if (child is _RenderSheet) {
        renderSheet = child;
      } else {
        child.visitChildren(findRenderSheet);
      }
    }

    visitChildren(findRenderSheet);
    assert(
      renderSheet != null,
      'No RenderSheetWidget found in the subtree of the SheetViewport.',
    );

    _model._inner!.measurements = Measurements(
      viewportSize: _lastMeasuredSize,
      sheetExtent: renderSheet!.size.height,
      contentSize: renderSheet!.contentSize,
      baseline: (_baseline = max(_viewInsets.bottom, _padding.bottom)),
    );
  }

  void _invalidateTransformMatrix() {
    final offset = _model.value?.offset;
    if (offset != null) {
      final dy = _lastMeasuredSize.height - (_baseline + offset);
      // Update the translation value and mark this render object
      // as needing to be repainted.
      transform = Matrix4.translationValues(0, dy, 0);
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

class _SheetConstraints extends BoxConstraints {
  const _SheetConstraints({
    required super.minWidth,
    required super.maxWidth,
    required super.minHeight,
    required super.maxHeight,
    required this.viewInsets,
  });

  final EdgeInsets viewInsets;
}

@internal
class RenderSheetWidget extends SingleChildRenderObjectWidget {
  const RenderSheetWidget({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheet();
  }
}

class _RenderSheet extends RenderProxyBox {
  Size get contentSize => child?.size ?? Size.zero;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      super.performLayout();
      return;
    }

    assert(this.constraints.biggest.isFinite);
    assert(
      this.constraints is _SheetConstraints,
      'Intermediate render objects between the SheetViewport and '
      'the RenderSheetWidget should not modify the constraints '
      'given by the SheetViewport. This is likely caused by a widget '
      'between the SheetViewport and the RenderSheetWidget that '
      'adds or removes extra space around the RenderSheetWidget, '
      'such as Padding widget.',
    );
    final constraints = this.constraints as _SheetConstraints;
    child.layout(
      constraints.deflate(constraints.viewInsets),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      constraints.viewInsets.inflateSize(child.size),
    );
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

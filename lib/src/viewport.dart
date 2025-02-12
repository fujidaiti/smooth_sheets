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

    Widget result = _RenderSheetViewportWidget(
      model: _modelView,
      padding: widget.padding,
      viewInsets:
          widget.ignoreViewInsets ? EdgeInsets.zero : viewInsetsForChild,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewInsets:
              widget.ignoreViewInsets ? viewInsetsForChild : EdgeInsets.zero,
          padding: paddingForChild,
          viewPadding: viewPaddingForChild,
        ),
        child: widget.child,
      ),
    );

    if (widget.padding.collapsedSize != Size.zero) {
      result = Padding(
        padding: widget.padding,
        child: result,
      );
    }

    return _InheritedSheetViewport(
      state: this,
      child: result,
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

class _RenderSheetViewportWidget extends SingleChildRenderObjectWidget {
  const _RenderSheetViewportWidget({
    required this.model,
    required this.viewInsets,
    required this.padding,
    required super.child,
  });

  final _LazySheetModelView model;
  final EdgeInsets viewInsets;
  // TODO: Remove 'padding' from this class.
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

  Size? _lastMeasuredSize;

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

    child!.layout(
      _SheetViewportConstraints(
        size: (size = constraints.biggest),
        viewInsets: _viewInsets,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _invalidateTransformMatrix() {
    if (_model.hasMetrics && _lastMeasuredSize != null) {
      final dy = _lastMeasuredSize!.height - _model.viewOffset;
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

class _SheetViewportConstraints extends BoxConstraints {
  _SheetViewportConstraints({
    required Size size,
    required this.viewInsets,
    required this.padding,
  }) : super(
          maxWidth: size.width,
          maxHeight: size.height,
        );

  final EdgeInsets viewInsets;
  final EdgeInsets padding;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SheetViewportConstraints &&
        viewInsets == other.viewInsets &&
        padding == other.padding &&
        super == other;
  }

  @override
  int get hashCode {
    return Object.hash(
      viewInsets,
      padding,
      super.hashCode,
    );
  }
}

@internal
class RenderSheetWidget extends SingleChildRenderObjectWidget {
  const RenderSheetWidget({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheet(
      model: SheetViewportState.of(context)!._modelView,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheet).model =
        SheetViewportState.of(context)!._modelView;
  }
}

class _RenderSheet extends RenderProxyBox {
  _RenderSheet({
    required _LazySheetModelView model,
  }) : _model = model {
    model.addListener(_invalidatePreferredSize);
    _invalidatePreferredSize();
  }

  _LazySheetModelView _model;

  // ignore: avoid_setters_without_getters
  set model(_LazySheetModelView value) {
    if (value != _model) {
      _model.removeListener(_invalidatePreferredSize);
      _model = value..addListener(_invalidatePreferredSize);
      _invalidatePreferredSize();
      markNeedsLayout();
    }
  }

  // TODO: Refactor this flag.
  bool _isInLayout = false;

  Size? _preferredSize;

  void _invalidatePreferredSize() {
    if (_model.hasMetrics) {
      final preferredSize = Size.fromHeight(
        max(_model.viewOffset - _model.measurements.viewportPadding.bottom, 0),
      );
      final oldPreferredSize = _preferredSize;
      _preferredSize = preferredSize;
      if (oldPreferredSize != preferredSize && !_isInLayout) {
        markNeedsLayout();
      }
    }
  }

  @override
  void dispose() {
    _model.removeListener(_invalidatePreferredSize);
    super.dispose();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      super.performLayout();
      return;
    }

    assert(_model._inner != null);
    assert(this.constraints.biggest.isFinite);
    assert(
      this.constraints is _SheetViewportConstraints,
      'Intermediate render objects between the SheetViewport and '
      'the RenderSheetWidget should not modify the constraints '
      'given by the SheetViewport. This is likely caused by a widget '
      'between the SheetViewport and the RenderSheetWidget that '
      'adds or removes extra space around the RenderSheetWidget, '
      'such as Padding widget.',
    );

    final constraints = this.constraints as _SheetViewportConstraints;
    final viewportSize = constraints.biggest;
    final viewportInsets = constraints.viewInsets;
    final viewportPadding = constraints.padding;
    final insets = EdgeInsets.fromLTRB(
      max(viewportInsets.left - viewportPadding.left, 0),
      max(viewportInsets.top - viewportPadding.top, 0),
      max(viewportInsets.right - viewportPadding.right, 0),
      max(viewportInsets.bottom - viewportPadding.bottom, 0),
    );
    final maxSize = viewportPadding.deflateSize(viewportSize);
    final maxContentSize = insets.deflateSize(maxSize);

    child.layout(
      BoxConstraints(
        minWidth: maxContentSize.width,
        maxWidth: maxContentSize.width,
        maxHeight: maxContentSize.height,
      ),
      parentUsesSize: true,
    );

    _isInLayout = true;
    final contentSize = Size.copy(child.size);
    _model._inner!.measurements = Measurements(
      contentSize: contentSize,
      viewportSize: viewportSize,
      viewportInsets: constraints.viewInsets,
      viewportPadding: constraints.padding,
    );
    _isInLayout = false;

    assert(_preferredSize != null);
    final minSize = insets.inflateSize(contentSize);
    size = BoxConstraints(
      minWidth: minSize.width,
      maxWidth: maxSize.width,
      minHeight: minSize.height,
      maxHeight: maxSize.height,
    ).constrain(_preferredSize!);
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

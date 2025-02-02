import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'model.dart';

class SheetViewport extends StatefulWidget {
  const SheetViewport({
    super.key,
    this.avoidBottomInset = true,
    required this.child,
  });

  final bool avoidBottomInset;
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
        model: model,
        insets: MediaQuery.of(context).viewInsets,
        avoidBottomInset: widget.avoidBottomInset,
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
    required this.model,
    required this.insets,
    required this.avoidBottomInset,
    required super.child,
  });

  final SheetModelView model;
  final EdgeInsets insets;
  final bool avoidBottomInset;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetTranslate(
      model: model,
      insets: insets,
      avoidBottomInset: avoidBottomInset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetTranslate)
      ..setModel(model)
      ..setInsets(insets)
      ..setAvoidBottomInset(avoidBottomInset);
  }
}

class _RenderSheetTranslate extends RenderTransform {
  _RenderSheetTranslate({
    required SheetModelView model,
    required EdgeInsets insets,
    required bool avoidBottomInset,
  })  : _model = model,
        _insets = insets,
        _avoidBottomInset = avoidBottomInset,
        super(
          transform: Matrix4.zero()..setIdentity(),
          transformHitTests: true,
        ) {
    model.addListener(_invalidateTransformMatrix);
    _invalidateTransformMatrix();
  }

  SheetModelView _model;
  EdgeInsets _insets;
  bool _avoidBottomInset;
  Size? _lastMeasuredSize;

  void setModel(SheetModelView value) {
    if (value != _model) {
      _model.removeListener(_invalidateTransformMatrix);
      _model = value..addListener(_invalidateTransformMatrix);
      _invalidateTransformMatrix();
    }
  }

  void setInsets(EdgeInsets value) {
    if (value != _insets) {
      _insets = value;
      markNeedsLayout();
    }
  }

  void setAvoidBottomInset(bool value) {
    if (value != _avoidBottomInset) {
      _avoidBottomInset = value;
      markNeedsLayout();
    }
  }

  @override
  set size(Size value) {
    _lastMeasuredSize = value;
    super.size = value;
  }

  @override
  void performLayout() {
    assert(
      (_model as _LazySheetModelView)._model != null,
      'The model object must be attached to the SheetViewport '
      'before the first layout phase.',
    );
    assert(
      constraints.biggest.isFinite,
      'The SheetViewport must be given a finite constraint.',
    );

    size = constraints.biggest;
    var childConstraints = constraints.loosen();
    if (_avoidBottomInset) {
      childConstraints = childConstraints.deflate(_insets);
    }
    child!.layout(childConstraints);
    // Ensure that the transform matrix is up-to-date.
    _invalidateTransformMatrix();
  }

  void _invalidateTransformMatrix() {
    final offset = _model.value?.offset;
    final viewportSize = _lastMeasuredSize;
    if (offset != null && viewportSize != null) {
      final dy = viewportSize.height - _insets.bottom - offset;
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

class _LazySheetModelView extends SheetModelView with ChangeNotifier {
  SheetModel? _model;

  void setModel(SheetModel? newModel) {
    if (newModel != _model) {
      final oldValue = value;
      _model?.removeListener(notifyListeners);
      _model = newModel?..addListener(notifyListeners);
      final newValue = value;
      if (oldValue != newValue) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _model?.removeListener(notifyListeners);
    _model = null;
    super.dispose();
  }

  @override
  SheetGeometry? get value => _model?.value;

  @override
  bool get hasMetrics => _model?.hasMetrics ?? false;

  @override
  bool get shouldIgnorePointer => _model?.shouldIgnorePointer ?? false;

  @override
  double get devicePixelRatio => _model!.devicePixelRatio;

  @override
  double get maxOffset => _model!.maxOffset;

  @override
  double get minOffset => _model!.minOffset;

  @override
  double get offset => _model!.offset;

  @override
  SheetMeasurements get measurements => _model!.measurements;

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    SheetMeasurements? measurements,
    double? devicePixelRatio,
  }) {
    return _model!.copyWith(
      offset: offset,
      minOffset: minOffset,
      maxOffset: maxOffset,
      measurements: measurements,
      devicePixelRatio: devicePixelRatio,
    );
  }
}

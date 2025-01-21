import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_position.dart';

class SheetViewport extends StatefulWidget {
  const SheetViewport({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SheetViewport> createState() => SheetViewportState();
}

@internal
class SheetViewportState extends State<SheetViewport> {
  late final _LazySheetModelView _modelView;

  SheetModelView get model => _modelView;

  void setModel(SheetPosition? model) {
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
    required super.child,
  });

  final SheetModelView model;
  final EdgeInsets insets;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetTranslate(model: model, insets: insets);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetTranslate)
      ..setModel(model)
      ..setInsets(insets);
  }
}

class _RenderSheetTranslate extends RenderTransform {
  _RenderSheetTranslate({
    required SheetModelView model,
    required EdgeInsets insets,
  })  : _model = model,
        _insets = insets,
        super(
          transform: Matrix4.zero()..setIdentity(),
          transformHitTests: true,
        ) {
    model.addListener(_invalidateTransformMatrix);
    _invalidateTransformMatrix();
  }

  SheetModelView _model;
  EdgeInsets _insets;
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
      // ignore: lines_longer_than_80_chars
      // TODO: Remove this line when the `baseline` property is added to SheetPosition.
      markNeedsPaint();
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
    child!.layout(constraints.loosen());
    // Ensure that the transform matrix is up-to-date.
    _invalidateTransformMatrix();
  }

  void _invalidateTransformMatrix() {
    final offset = _model.value;
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

class _LazySheetModelView extends ChangeNotifier implements SheetModelView {
  SheetPosition? _model;

  void setModel(SheetPosition? newModel) {
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
  double? get value => _model?.maybePixels;

  @override
  bool get shouldIgnorePointer => _model?.shouldIgnorePointer ?? false;
}

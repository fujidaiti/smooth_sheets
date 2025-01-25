import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_position.dart';

@internal
class SheetFrame extends SingleChildRenderObjectWidget {
  const SheetFrame({
    super.key,
    required this.model,
    required super.child,
  });

  final SheetPosition model;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetFrame(
      model: model,
      viewportInsets: MediaQuery.viewInsetsOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetFrame)
      ..setModel(model)
      ..setViewportInsets(MediaQuery.viewInsetsOf(context));
  }
}

class _RenderSheetFrame extends RenderProxyBox {
  _RenderSheetFrame({
    required SheetPosition model,
    required EdgeInsets viewportInsets,
  })  : _model = model,
        _viewportInsets = viewportInsets {
    model.addListener(_onMetricsChange);
  }

  EdgeInsets _viewportInsets;
  SheetPosition _model;
  Size? _lastMeasuredSize;

  @override
  set size(Size value) {
    _lastMeasuredSize = value;
    super.size = value;
  }

  void setViewportInsets(EdgeInsets value) {
    if (value != _viewportInsets) {
      _viewportInsets = value;
      markNeedsLayout();
    }
  }

  void setModel(SheetPosition value) {
    if (value != _model) {
      _model = value;
      markNeedsLayout();
    }
  }

  @override
  void dispose() {
    _model.removeListener(_onMetricsChange);
    super.dispose();
  }

  void _onMetricsChange() {
    // ignore: lines_longer_than_80_chars
    // TODO: Mark this render object as needing layout when the preferred sheet size changes.
    /*
    final metrics = _metricsNotifier.value;
    if (metrics.contentSize != _lastMeasuredSize &&
        // Calling SheetPosition.applyNewDimensions() in the performLayout()
        // eventually triggers this callback. In that case, we must not
        // call markNeedsLayout() as it is already in the layout phase.
        SchedulerBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks) {
      markNeedsLayout();
    }
    */
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      super.performLayout();
      return;
    }

    assert(constraints.biggest.isFinite);
    final childConstraints = constraints.tighten(width: constraints.maxWidth);
    child.layout(childConstraints, parentUsesSize: true);
    final viewportSize = constraints.biggest;
    _model.measurements = SheetMeasurements(
      contentSize: Size.copy(child.size),
      viewportSize: viewportSize,
      viewportInsets: _viewportInsets,
    );
    // ignore: lines_longer_than_80_chars
    // TODO: The size of this widget should be determined by the geometry controller.
    size = child.size;
  }
}

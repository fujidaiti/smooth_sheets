import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_position.dart';

typedef OnSheetDimensionsChange = void Function(
  Size contentSize,
  Size viewportSize,
  EdgeInsets viewportInsets,
);

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
class SheetViewportState extends State<SheetViewport>
    implements ValueListenable<SheetMetrics> {
  late final List<VoidCallback> _listeners;
  SheetPosition? _position;

  void setPosition(SheetPosition? value) {
    if (value != _position) {
      _position?.removeListener(_notifyListeners);
      _position = value?..addListener(_notifyListeners);
    }
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Intended to be used only by [_RenderSheetTranslate]
  /// and [_RenderSheetFrame].
  @override
  SheetMetrics get value => _position!.snapshot;

  /// Intended to be used only by [_RenderSheetTranslate]
  /// and [_RenderSheetFrame].
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Intended to be used only by [_RenderSheetTranslate]
  /// and [_RenderSheetFrame].
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _onSheetDimensionsChange(
    Size contentSize,
    Size viewportSize,
    EdgeInsets viewportInsets,
  ) {
    _position?.applyNewDimensions(contentSize, viewportSize, viewportInsets);
  }

  bool _shouldIgnorePointer() {
    return _position?.activity.shouldIgnorePointer ?? false;
  }

  @override
  void initState() {
    super.initState();
    _listeners = [];
  }

  @override
  void dispose() {
    _listeners.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSheetViewport(
      state: this,
      child: SheetTranslate(
        metricsNotifier: this,
        shouldIgnorePointerGetter: _shouldIgnorePointer,
        insets: MediaQuery.of(context).viewInsets,
        child: SheetFrame(
          metricsNotifier: this,
          onSheetDimensionsChange: _onSheetDimensionsChange,
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

@visibleForTesting
@internal
class SheetTranslate extends SingleChildRenderObjectWidget {
  const SheetTranslate({
    super.key,
    required this.metricsNotifier,
    required this.shouldIgnorePointerGetter,
    required this.insets,
    required super.child,
  });

  final ValueListenable<SheetMetrics> metricsNotifier;
  final ValueGetter<bool> shouldIgnorePointerGetter;
  final EdgeInsets insets;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetTranslate(
      metricsNotifier: metricsNotifier,
      shouldIgnorePointerGetter: shouldIgnorePointerGetter,
      insets: insets,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetTranslate)
      ..setMetricsNotifier(metricsNotifier)
      ..setShouldIgnorePointerGetter(shouldIgnorePointerGetter)
      ..setInsets(insets);
  }
}

class _RenderSheetTranslate extends RenderTransform {
  _RenderSheetTranslate({
    required ValueListenable<SheetMetrics> metricsNotifier,
    required ValueGetter<bool> shouldIgnorePointerGetter,
    required EdgeInsets insets,
  })  : _metricsNotifier = metricsNotifier,
        _shouldIgnorePointerGetter = shouldIgnorePointerGetter,
        _insets = insets,
        super(
          transform: Matrix4.zero()..setIdentity(),
          transformHitTests: true,
        ) {
    _metricsNotifier.addListener(_invalidateTransformMatrix);
  }

  ValueListenable<SheetMetrics> _metricsNotifier;
  ValueGetter<bool> _shouldIgnorePointerGetter;
  EdgeInsets _insets;

  void setMetricsNotifier(ValueListenable<SheetMetrics> value) {
    if (value != _metricsNotifier) {
      _metricsNotifier.removeListener(_invalidateTransformMatrix);
      _metricsNotifier = value..addListener(_invalidateTransformMatrix);
      markNeedsPaint();
    }
  }

  void setShouldIgnorePointerGetter(ValueGetter<bool> value) {
    _shouldIgnorePointerGetter = value;
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
  void performLayout() {
    assert(constraints.biggest.isFinite);
    size = constraints.biggest;
    child!.layout(constraints);
  }

  void _invalidateTransformMatrix() {
    final currentPosition = _metricsNotifier.value.maybePixels;
    final viewportSize = _metricsNotifier.value.maybeViewportSize;
    if (currentPosition != null && viewportSize != null) {
      final dy = viewportSize.height - _insets.bottom - currentPosition;
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
    if (_shouldIgnorePointerGetter()) {
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
    _metricsNotifier.removeListener(_invalidateTransformMatrix);
    super.dispose();
  }
}

@internal
@visibleForTesting
class SheetFrame extends SingleChildRenderObjectWidget {
  const SheetFrame({
    super.key,
    required this.metricsNotifier,
    required this.onSheetDimensionsChange,
    required super.child,
  });

  final ValueListenable<SheetMetrics> metricsNotifier;
  final OnSheetDimensionsChange onSheetDimensionsChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetFrame(
      metricsNotifier: metricsNotifier,
      onSheetDimensionsChange: onSheetDimensionsChange,
      viewportInsets: MediaQuery.viewInsetsOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetFrame)
      ..setMetricsNotifier(metricsNotifier)
      ..setOnSheetDimensionsChange(onSheetDimensionsChange)
      ..setViewportInsets(MediaQuery.viewInsetsOf(context));
  }
}

class _RenderSheetFrame extends RenderProxyBox {
  _RenderSheetFrame({
    required OnSheetDimensionsChange onSheetDimensionsChange,
    required ValueListenable<SheetMetrics> metricsNotifier,
    required EdgeInsets viewportInsets,
  })  : _onSheetDimensionsChange = onSheetDimensionsChange,
        _metricsNotifier = metricsNotifier,
        _viewportInsets = viewportInsets {
    _metricsNotifier.addListener(_onMetricsChange);
  }

  EdgeInsets _viewportInsets;
  OnSheetDimensionsChange _onSheetDimensionsChange;
  ValueListenable<SheetMetrics> _metricsNotifier;
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

  void setOnSheetDimensionsChange(OnSheetDimensionsChange value) {
    if (value != _onSheetDimensionsChange) {
      _onSheetDimensionsChange = value;
      markNeedsLayout();
    }
  }

  void setMetricsNotifier(ValueListenable<SheetMetrics> value) {
    if (value != _metricsNotifier) {
      _metricsNotifier.removeListener(_onMetricsChange);
      _metricsNotifier = value..addListener(_onMetricsChange);
    }
  }

  @override
  void dispose() {
    _metricsNotifier.removeListener(_onMetricsChange);
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

    assert(
      constraints.biggest.isFinite,
      'SheetSkeleton must be in a box that has a bounded width and height.\n'
      'Given constraints: $constraints',
    );

    final childConstraints = constraints.tighten(width: constraints.maxWidth);
    child.layout(childConstraints, parentUsesSize: true);
    final viewportSize = constraints.biggest;
    _onSheetDimensionsChange(child.size, viewportSize, _viewportInsets);
    // ignore: lines_longer_than_80_chars
    // TODO: The size of this widget should be determined by the geometry controller.
    size = child.size;
  }
}

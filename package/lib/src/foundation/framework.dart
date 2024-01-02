import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

class SheetContainer extends StatelessWidget {
  const SheetContainer({
    super.key,
    this.controller,
    this.onExtentChanged,
    required this.factory,
    required this.child,
  });

  final SheetController? controller;
  final ValueChanged<SheetExtent?>? onExtentChanged;
  final SheetExtentFactory factory;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetExtentScope(
      factory: factory,
      controller: controller ?? SheetControllerScope.maybeOf(context),
      onExtentChanged: onExtentChanged,
      child: Builder(
        builder: (context) {
          return SheetViewport(
            extent: SheetExtentScope.of(context),
            child: SheetContentViewport(child: child),
          );
        },
      ),
    );
  }
}

class SheetViewport extends SingleChildRenderObjectWidget {
  const SheetViewport({
    super.key,
    required this.extent,
    required super.child,
  });

  final SheetExtent extent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetViewport(extent);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetViewport).extent = extent;
  }
}

class _RenderSheetViewport extends RenderTransform {
  _RenderSheetViewport(SheetExtent extent)
      : _extent = extent,
        super(transform: Matrix4.zero(), transformHitTests: true) {
    _extent.addListener(_invalidateTranslationValue);
  }

  // Cache the last measured size because we can't access
  // 'size' property from outside of the layout phase.
  Size? _lastMeasuredSize;

  SheetExtent _extent;
  // ignore: avoid_setters_without_getters
  set extent(SheetExtent value) {
    if (_extent != value) {
      _extent.removeListener(_invalidateTranslationValue);
      _extent = value..addListener(_invalidateTranslationValue);
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    // We can assume that the viewport will always be as big as possible.
    _lastMeasuredSize = constraints.biggest;
    // Notify the SheetExtent about the viewport size changes
    // before performing the layout so that the descendant widgets
    // can use the viewport size during the layout phase.
    _extent.applyNewViewportDimensions(_lastMeasuredSize!);
    super.performLayout();

    assert(
      size == constraints.biggest,
      'The sheet viewport should have the biggest possible size '
      'in the given constraints.',
    );

    assert(
      _extent.contentDimensions != null && _extent.pixels != null,
      'The sheet extent and its content dimensions '
      'must be finalized during the layout phase.',
    );

    _invalidateTranslationValue();
  }

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    _invalidateTranslationValue();
  }

  void _invalidateTranslationValue() {
    final currentExtent = _extent.pixels;
    final viewportSize = _lastMeasuredSize;
    if (currentExtent != null && viewportSize != null) {
      final dy = viewportSize.height - currentExtent;
      // Update the translation value and mark this render object
      // as needing to be repainted.
      transform = Matrix4.translationValues(0, dy, 0);
    }
  }

  @override
  void dispose() {
    _extent.removeListener(_invalidateTranslationValue);
    super.dispose();
  }
}

class SheetContentViewport extends StatefulWidget {
  const SheetContentViewport({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SheetContentViewport> createState() => _SheetContentViewportState();
}

class _SheetContentViewportState extends State<SheetContentViewport> {
  _SheetContentViewportState? _parent;

  bool _isPrimary = true;
  bool getIsPrimary() => _isPrimary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent = _SheetContentViewportScope.maybeOf(context);
    markAsPrimary();
  }

  @override
  void dispose() {
    unmarkAsPrimary();
    super.dispose();
  }

  void unmarkAsPrimary() {
    _isPrimary = false;
    _parent?.markAsPrimary();
  }

  void markAsPrimary() {
    _isPrimary = true;
    var parent = _parent;
    while (parent != null) {
      parent._isPrimary = false;
      parent = parent._parent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContentViewportScope(
      state: this,
      child: _SheetContentLayoutObserver(
        isPrimary: getIsPrimary,
        extent: SheetExtentScope.maybeOf(context),
        child: widget.child,
      ),
    );
  }
}

class _SheetContentViewportScope extends InheritedWidget {
  const _SheetContentViewportScope({
    required this.state,
    required super.child,
  });

  final _SheetContentViewportState state;

  @override
  bool updateShouldNotify(_SheetContentViewportScope oldWidget) => true;

  static _SheetContentViewportState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SheetContentViewportScope>()
        ?.state;
  }
}

class _SheetContentLayoutObserver extends SingleChildRenderObjectWidget {
  const _SheetContentLayoutObserver({
    required this.isPrimary,
    required this.extent,
    required super.child,
  });

  final ValueGetter<bool> isPrimary;
  final SheetExtent? extent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetContentLayoutObserver(
      isPrimary: isPrimary,
      extent: extent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetContentLayoutObserver)
      ..extent = extent
      ..isPrimary = isPrimary;
  }
}

class _RenderSheetContentLayoutObserver extends RenderPositionedBox {
  _RenderSheetContentLayoutObserver({
    required ValueGetter<bool> isPrimary,
    required SheetExtent? extent,
  })  : _isPrimary = isPrimary,
        _extent = extent,
        super(alignment: Alignment.topCenter);

  ValueGetter<bool> _isPrimary;
  // ignore: avoid_setters_without_getters
  set isPrimary(ValueGetter<bool> value) {
    if (_isPrimary != value) {
      _isPrimary = value;
      markNeedsLayout();
    }
  }

  SheetExtent? _extent;
  // ignore: avoid_setters_without_getters
  set extent(SheetExtent? value) {
    if (_extent != value) {
      _extent = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    if (child != null && _isPrimary()) {
      _extent?.applyNewContentDimensions(child!.size);
    }
  }
}

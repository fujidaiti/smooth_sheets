import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_position.dart';
import 'sheet_position_scope.dart';

@internal
class SheetViewport extends SingleChildRenderObjectWidget {
  const SheetViewport({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSheetViewport(
      SheetPositionScope.of(context),
      MediaQuery.viewInsetsOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as RenderSheetViewport)
      ..position = SheetPositionScope.of(context)
      ..insets = MediaQuery.viewInsetsOf(context);
  }
}

@internal
class RenderSheetViewport extends RenderTransform {
  RenderSheetViewport(SheetPosition position, EdgeInsets insets)
      : _position = position,
        _insets = insets,
        super(transform: Matrix4.zero(), transformHitTests: true) {
    _position.addListener(_invalidateTranslationValue);
  }

  // Cache the last measured size because we can't access
  // 'size' property from outside of the layout phase.
  Size? _lastMeasuredSize;

  Size? get lastMeasuredSize => _lastMeasuredSize;

  SheetPosition _position;

  // ignore: avoid_setters_without_getters
  set position(SheetPosition value) {
    if (_position != value) {
      _position.removeListener(_invalidateTranslationValue);
      _position = value..addListener(_invalidateTranslationValue);
      markNeedsLayout();
    }
  }

  EdgeInsets _insets;

  EdgeInsets get insets => _insets;

  set insets(EdgeInsets value) {
    if (value != _insets) {
      _insets = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    // We can assume that the viewport will always be as big as possible.
    _lastMeasuredSize = constraints.biggest;
    _position.markAsDimensionsWillChange();
    // Notify the SheetPosition about the viewport size changes
    // before performing the layout so that the descendant widgets
    // can use the viewport size during the layout phase.
    _position.applyNewViewportDimensions(
      Size(_lastMeasuredSize!.width, _lastMeasuredSize!.height),
      _insets,
    );

    super.performLayout();

    assert(
      size == constraints.biggest,
      'The sheet viewport should have the biggest possible size '
      'in the given constraints.',
    );

    assert(
      _position.hasDimensions,
      'The sheet position and the dimensions values '
      'must be finalized during the layout phase.',
    );

    _position.markAsDimensionsChanged();
    _invalidateTranslationValue();
  }

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    _invalidateTranslationValue();
  }

  void _invalidateTranslationValue() {
    final currentPosition = _position.maybePixels;
    final viewportSize = _lastMeasuredSize;
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
    if (_position.activity.shouldIgnorePointer) {
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
    _position.removeListener(_invalidateTranslationValue);
    super.dispose();
  }
}

@internal
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
  final List<_SheetContentViewportState> _children = [];

  bool _isEnabled() => _children.isEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = _SheetContentViewportScope.maybeOf(context);
    if (_parent != parent) {
      _parent?._children.remove(this);
      _parent = parent?.._children.add(this);
    }
  }

  @override
  void dispose() {
    _parent?._children.remove(this);
    _parent = null;
    _children.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContentViewportScope(
      state: this,
      child: _SheetContentLayoutObserver(
        isEnabled: _isEnabled,
        position: SheetPositionScope.maybeOf(context),
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
    required this.isEnabled,
    required this.position,
    required super.child,
  });

  final ValueGetter<bool> isEnabled;
  final SheetPosition? position;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetContentLayoutObserver(
      position: position,
      isEnabled: isEnabled,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetContentLayoutObserver)
      ..position = position
      ..isEnabled = isEnabled;
  }
}

class _RenderSheetContentLayoutObserver extends RenderPositionedBox {
  _RenderSheetContentLayoutObserver({
    required ValueGetter<bool> isEnabled,
    required SheetPosition? position,
  })  : _isEnabled = isEnabled,
        _position = position,
        super(alignment: Alignment.topCenter);

  SheetPosition? _position;

  // ignore: avoid_setters_without_getters
  set position(SheetPosition? value) {
    if (_position != value) {
      _position = value;
      markNeedsLayout();
    }
  }

  ValueGetter<bool> _isEnabled;

  // ignore: avoid_setters_without_getters
  set isEnabled(ValueGetter<bool> value) {
    if (_isEnabled != value) {
      _isEnabled = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    _position?.markAsDimensionsWillChange();
    super.performLayout();
    final childSize = child?.size;
    // The evaluation of _isEnabled() is intentionally delayed
    // until this line, because the descendant widgets may perform
    // their build during the subroutine of super.performLayout()
    // and if another SheetContentViewport exists in the subtree,
    // it will change the result of _isEnabled().
    if (_isEnabled() && childSize != null) {
      _position?.applyNewContentSize(childSize);
    }
    _position?.markAsDimensionsChanged();
  }
}

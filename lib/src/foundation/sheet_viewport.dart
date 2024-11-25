import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_position.dart';
import 'sheet_position_scope.dart';

class SheetViewport extends StatefulWidget {
  const SheetViewport({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SheetViewport> createState() => SheetViewportState();

  static SheetViewportState of(BuildContext context) {
    final viewport = context
        .dependOnInheritedWidgetOfExactType<_SheetViewportScope>()
        ?.state;

    assert(
      viewport != null,
      "A SheetViewport was not found. It's likely that the sheet widget "
      'does not have a SheetViewport as an ancestor.',
    );

    return viewport!;
  }
}

@internal
class SheetViewportState extends State<SheetViewport> {
  late final SheetPositionScopeKey positionOwnerKey;

  @override
  void initState() {
    super.initState();
    positionOwnerKey = SheetPositionScopeKey(
      debugLabel: kDebugMode ? 'SheetViewport' : null,
    );
  }

  @override
  void dispose() {
    positionOwnerKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetViewportScope(
      state: this,
      child: RenderSheetViewportWidget(
        positionOwnerKey: positionOwnerKey,
        insets: MediaQuery.of(context).viewInsets,
        child: widget.child,
      ),
    );
  }
}

class _SheetViewportScope extends InheritedWidget {
  const _SheetViewportScope({
    required this.state,
    required super.child,
  });

  final SheetViewportState state;

  @override
  bool updateShouldNotify(_SheetViewportScope oldWidget) => true;
}

@internal
class RenderSheetViewportWidget extends SingleChildRenderObjectWidget {
  const RenderSheetViewportWidget({
    super.key,
    required this.positionOwnerKey,
    required this.insets,
    required super.child,
  });

  final SheetPositionScopeKey positionOwnerKey;
  final EdgeInsets insets;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSheetViewport(
      positionOwnerKey: positionOwnerKey,
      insets: insets,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSheetViewport renderObject,
  ) {
    assert(
      positionOwnerKey == renderObject.positionOwnerKey,
      'The positionOwnerKey must not change during the widget life cycle.',
    );
    renderObject.insets = insets;
  }
}

@internal
class RenderSheetViewport extends RenderTransform {
  RenderSheetViewport({
    required this.positionOwnerKey,
    required EdgeInsets insets,
  })  : _insets = insets,
        super(
          transform: Matrix4.zero()..setIdentity(),
          transformHitTests: true,
        ) {
    positionOwnerKey.addOnCreatedListener(
      () => position = positionOwnerKey.maybeCurrentPosition,
    );
  }

  final SheetPositionScopeKey positionOwnerKey;

  SheetPosition? _position;

  // ignore: avoid_setters_without_getters
  set position(SheetPosition? value) {
    switch ((_position, value)) {
      case (null, final initialPosition?):
        _position = initialPosition
          ..addListener(markNeedsPaint)
          ..applyNewViewportInsets(insets);
        markNeedsPaint();

      case (final oldPosition?, null):
        oldPosition.removeListener(markNeedsPaint);
        _position = null;

      case (final oldPosition?, final newPosition?)
          when oldPosition != newPosition:
        oldPosition.removeListener(markNeedsPaint);
        _position = newPosition..addListener(markNeedsPaint);
        markNeedsPaint();
    }
  }

  EdgeInsets _insets;

  EdgeInsets get insets => _insets;

  set insets(EdgeInsets value) {
    if (value != _insets) {
      _insets = value;
      _position?.applyNewViewportInsets(value);
      // ignore: lines_longer_than_80_chars
      // TODO: Remove this line when the `baseline` property is added to SheetPosition.
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    // We can assume that the viewport will always be as big as possible.
    final biggestSize = constraints.biggest;
    // Notify the SheetPosition about the viewport size changes
    // before performing the layout so that the descendant widgets
    // can use the viewport size during the layout phase.
    _position?.applyNewViewportSize(Size.copy(biggestSize));

    super.performLayout();

    assert(
      size == biggestSize,
      'The sheet viewport should have the biggest possible size '
      'in the given constraints.',
    );
  }

  void _invalidateTransformMatrix() {
    final currentPosition = _position?.maybePixels;
    final viewportSize = _position?.maybeViewportSize;
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
    if (_position?.activity.shouldIgnorePointer == true) {
      final invTransform = Matrix4.tryInvert(
        PointerEvent.removePerspectiveTransform(_transform),
      );
      return invTransform != null &&
          size.contains(MatrixUtils.transformPoint(invTransform, position));
    }

    return super.hitTest(result, position: position);
  }

  /// Indicates whether this render object is currently in the painting phase.
  ///
  /// This flag prevents [markNeedsPaint] from being called during the
  /// subroutine of [SheetPosition.finalizePosition], which is invoked in the
  /// [paint] method. Calling [markNeedsPaint] during the painting phase is not
  /// allowed by the framework.
  bool _isPainting = false;

  @override
  void markNeedsPaint() {
    if (!_isPainting) {
      super.markNeedsPaint();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _isPainting = true;
    // Ensures that the transform matrix is up-to-date.
    // Ideally, we should call the next two lines
    // after the layout phase and before the painting phase.
    // However, there is no such hook in the framework,
    // so they are invoked here as a workaround.
    _position?.finalizePosition();
    _invalidateTransformMatrix();
    super.paint(context, offset);
    _isPainting = false;
  }

  @override
  void dispose() {
    _position?.removeListener(markNeedsPaint);
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
  }
}

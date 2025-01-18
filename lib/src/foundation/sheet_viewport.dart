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
        .dependOnInheritedWidgetOfExactType<_InheritedSheetViewport>()
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
    return _InheritedSheetViewport(
      state: this,
      child: SheetTranslate(
        positionOwnerKey: positionOwnerKey,
        insets: MediaQuery.of(context).viewInsets,
        child: SheetFrame(
          geometry: positionOwnerKey,
          child: widget.child,
        ),
      ),
    );
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
    required this.positionOwnerKey,
    required this.insets,
    required super.child,
  });

  final SheetPositionScopeKey positionOwnerKey;
  final EdgeInsets insets;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSheetTranslate(
      positionOwnerKey: positionOwnerKey,
      insets: insets,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSheetTranslate renderObject,
  ) {
    assert(
      positionOwnerKey == renderObject.positionOwnerKey,
      'The positionOwnerKey must not change during the widget life cycle.',
    );
    renderObject.insets = insets;
  }
}

@internal
class RenderSheetTranslate extends RenderTransform {
  RenderSheetTranslate({
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
        _position = initialPosition..addListener(_invalidateTransformMatrix);
        markNeedsPaint();

      case (final oldPosition?, null):
        oldPosition.removeListener(_invalidateTransformMatrix);
        _position = null;

      case (final oldPosition?, final newPosition?)
          when oldPosition != newPosition:
        oldPosition.removeListener(_invalidateTransformMatrix);
        _position = newPosition..addListener(_invalidateTransformMatrix);
        markNeedsPaint();
    }
  }

  EdgeInsets _insets;

  EdgeInsets get insets => _insets;

  set insets(EdgeInsets value) {
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

  @override
  void dispose() {
    _position?.removeListener(_invalidateTransformMatrix);
    super.dispose();
  }
}

@internal
@visibleForTesting
class SheetFrame extends SingleChildRenderObjectWidget {
  const SheetFrame({
    super.key,
    required this.geometry,
    required super.child,
  });

  final SheetPositionScopeKey geometry;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSheetFrame(
      geometry: geometry,
      viewportInsets: MediaQuery.viewInsetsOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSheetFrame)
      ..geometry = geometry
      ..viewportInsets = MediaQuery.viewInsetsOf(context);
  }
}

class _RenderSheetFrame extends RenderProxyBox {
  _RenderSheetFrame({
    required SheetPositionScopeKey geometry,
    required EdgeInsets viewportInsets,
  })  : _geometry = geometry,
        _viewportInsets = viewportInsets;

  SheetPositionScopeKey get geometry => _geometry;
  SheetPositionScopeKey _geometry;

  set geometry(SheetPositionScopeKey value) {
    if (value != _geometry) {
      _geometry = value;
      markNeedsLayout();
    }
  }

  EdgeInsets get viewportInsets => _viewportInsets;
  EdgeInsets _viewportInsets;

  set viewportInsets(EdgeInsets value) {
    parent;
    if (value != _viewportInsets) {
      _viewportInsets = value;
      markNeedsLayout();
    }
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
    _geometry.currentPosition
        .applyNewDimensions(child.size, viewportSize, viewportInsets);
    assert(_geometry.currentPosition.hasDimensions);
    // ignore: lines_longer_than_80_chars
    // TODO: The size of this widget should be determined by the geometry controller.
    size = child.size;

    if (parent case final RenderSheetTranslate it?) {
      // SheetPosition.applyNewDimensions() doesn't notify its listeners even
      // when the offset changes, so we need to manually notify the ancestor
      // RenderSheetTranslate, which is a listener of the SheetPosition,
      // to ensure that the transform matrix is up-to-date.
      it._invalidateTransformMatrix();
    }
  }
}

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_extent_scope.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_viewport.dart';

@internal
class NavigationSheetViewport extends SheetViewport {
  const NavigationSheetViewport({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNavigationSheetViewport(
      SheetExtentScope.of(context),
      MediaQuery.viewInsetsOf(context),
    );
  }

  static _RenderNavigationSheetViewport _of(BuildContext context) {
    final renderObject = context
        .findAncestorRenderObjectOfType<_RenderNavigationSheetViewport>();

    assert(() {
      if (renderObject == null) {
        throw FlutterError(
          'No $NavigationSheetViewport ancestor could be found starting '
          'from the context that was passed to $NavigationSheetViewport.of(). '
          'The context used was:\n'
          '$context',
        );
      }
      return true;
    }());

    return renderObject!;
  }
}

class _RenderNavigationSheetViewport extends RenderSheetViewport {
  _RenderNavigationSheetViewport(super.extent, super.insets);

  final _children = <_RenderNavigationSheetRouteViewport>[];

  void addChild(_RenderNavigationSheetRouteViewport child) {
    assert(!_children.contains(child));
    _children.add(child);
  }

  void removeChild(_RenderNavigationSheetRouteViewport child) {
    assert(_children.contains(child));
    _children.remove(child);
  }

  @override
  void markNeedsLayout() {
    super.markNeedsLayout();
    for (final child in _children) {
      // Mark the local viewports as dirty so that they can
      // receive the new dimension values from the global viewport.
      child.markNeedsLayout();
    }
  }

  @override
  void dispose() {
    _children.clear();
    super.dispose();
  }
}

@internal
class NavigationSheetRouteViewport extends SingleChildRenderObjectWidget {
  const NavigationSheetRouteViewport({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNavigationSheetRouteViewport(
      globalViewport: NavigationSheetViewport._of(context),
      localExtent: SheetExtentScope.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderNavigationSheetRouteViewport)
      ..globalViewport = NavigationSheetViewport._of(context)
      ..localExtent = SheetExtentScope.of(context);
  }
}

class _RenderNavigationSheetRouteViewport extends RenderProxyBox {
  _RenderNavigationSheetRouteViewport({
    required _RenderNavigationSheetViewport globalViewport,
    required SheetPosition localExtent,
  })  : _globalViewport = globalViewport,
        _localExtent = localExtent {
    _globalViewport.addChild(this);
  }

  _RenderNavigationSheetViewport _globalViewport;
  // ignore: avoid_setters_without_getters
  set globalViewport(_RenderNavigationSheetViewport value) {
    if (_globalViewport != value) {
      _globalViewport.removeChild(this);
      _globalViewport = value..addChild(this);
    }
  }

  SheetPosition _localExtent;
  // ignore: avoid_setters_without_getters
  set localExtent(SheetPosition value) {
    if (_localExtent != value) {
      _localExtent = value;
      markNeedsLayout();
    }
  }

  @override
  void dispose() {
    _globalViewport.removeChild(this);
    super.dispose();
  }

  @override
  void performLayout() {
    _localExtent.markAsDimensionsWillChange();
    // Notify the SheetExtent about the viewport size changes
    // before performing the layout so that the descendant widgets
    // can use the viewport size during the layout phase.
    _localExtent.applyNewViewportDimensions(
      Size.copy(_globalViewport.lastMeasuredSize!),
      _globalViewport.insets,
    );
    super.performLayout();
    _localExtent.markAsDimensionsChanged();
  }
}

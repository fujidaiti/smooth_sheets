import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_extent.dart';
import '../foundation/sheet_viewport.dart';

@internal
class NavigationSheetViewport extends SheetViewport {
  const NavigationSheetViewport({
    super.key,
    required super.extent,
    required super.insets,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNavigationSheetViewport(super.extent, super.insets);
  }

  static _RenderNavigationSheetViewport? _maybeOf(BuildContext context) {
    return context
        .findAncestorRenderObjectOfType<_RenderNavigationSheetViewport>();
  }
}

class _RenderNavigationSheetViewport extends RenderSheetViewport {
  _RenderNavigationSheetViewport(super.extent, super.insets);

  final _children = <_RenderLocalSheetViewport>[];

  void addChild(_RenderLocalSheetViewport child) {
    assert(!_children.contains(child));
    _children.add(child);
  }

  void removeChild(_RenderLocalSheetViewport child) {
    assert(_children.contains(child));
    _children.remove(child);
  }

  @override
  void markNeedsLayout() {
    super.markNeedsLayout();
    for (final child in _children) {
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
class NavigationSheetRouteViewport extends StatefulWidget {
  const NavigationSheetRouteViewport({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<NavigationSheetRouteViewport> createState() =>
      _NavigationSheetRouteViewportState();
}

class _NavigationSheetRouteViewportState
    extends State<NavigationSheetRouteViewport> {
  _RenderNavigationSheetViewport? _globalViewport;
  SheetExtent? _localExtent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    assert(() {
      if (NavigationSheetViewport._maybeOf(context) == null) {
        throw FlutterError(
          '$NavigationSheetRouteViewport must be a descendant of '
          '$NavigationSheetViewport.',
        );
      }
      return true;
    }());

    assert(() {
      if (SheetExtentScope.maybeOf(context) == null) {
        throw FlutterError(
          '$NavigationSheetRouteViewport must be a descendant of '
          '$NavigationSheetViewport.',
        );
      }
      return true;
    }());

    _globalViewport = NavigationSheetViewport._maybeOf(context);
    _localExtent = SheetExtentScope.maybeOf(context);
  }

  @override
  void dispose() {
    _globalViewport = null;
    _localExtent = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NavigationSheetRouteViewport(
      globalViewport: _globalViewport!,
      localExtent: _localExtent!,
      child: widget.child,
    );
  }
}

class _NavigationSheetRouteViewport extends SingleChildRenderObjectWidget {
  const _NavigationSheetRouteViewport({
    required this.globalViewport,
    required this.localExtent,
    required super.child,
  });

  final _RenderNavigationSheetViewport globalViewport;
  final SheetExtent localExtent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLocalSheetViewport(
      globalViewport: globalViewport,
      localExtent: localExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderLocalSheetViewport)
      ..globalViewport = globalViewport
      ..localExtent = localExtent;
  }
}

class _RenderLocalSheetViewport extends RenderProxyBox {
  _RenderLocalSheetViewport({
    required _RenderNavigationSheetViewport globalViewport,
    required SheetExtent localExtent,
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

  SheetExtent _localExtent;
  // ignore: avoid_setters_without_getters
  set localExtent(SheetExtent value) {
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:smooth_sheets/src/draggable/sheet_draggable.dart';
import 'package:smooth_sheets/src/foundation/framework.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

class SheetContentScaffold extends StatelessWidget {
  const SheetContentScaffold({
    super.key,
    this.primary = false,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.appbarDraggable = true,
    this.backgroundColor,
    this.requiredMinExtentForStickyBottomBar = const Extent.pixels(0),
    this.appBar,
    required this.body,
    this.bottomBar,
  });

  final Extent requiredMinExtentForStickyBottomBar;
  final bool primary;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool appbarDraggable;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        this.backgroundColor ?? Theme.of(context).colorScheme.surface;

    final appBar = this.appBar != null && appbarDraggable
        ? _AppBarDraggable(appBar: this.appBar!)
        : this.appBar;

    var bottomBar = this.bottomBar;
    if (this.bottomBar != null) {
      bottomBar = _PersistentBottomBar(
        extent: SheetExtentScope.of(context),
        requiredMinExtent: requiredMinExtentForStickyBottomBar,
        child: this.bottomBar,
      );
    }

    var body = this.body;
    final useTopSafeArea = appBar != null && !extendBodyBehindAppBar;
    final useBottomSafeArea = bottomBar != null && !extendBody;
    if (useTopSafeArea || useBottomSafeArea) {
      body = SafeArea(
        left: false,
        right: false,
        top: useTopSafeArea,
        bottom: useBottomSafeArea,
        child: body,
      );
    }

    Widget result = Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      primary: primary,
      appBar: appBar,
      bottomNavigationBar: bottomBar,
      resizeToAvoidBottomInset: false,
      body: SheetContentViewport(
        child: body,
      ),
    );

    if (!primary) {
      result = MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: result,
      );
    }

    return result;
  }
}

class _AppBarDraggable extends StatelessWidget implements PreferredSizeWidget {
  const _AppBarDraggable({
    required this.appBar,
  });

  final PreferredSizeWidget appBar;

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return SheetDraggable(child: appBar);
  }
}

class _PersistentBottomBar extends SingleChildRenderObjectWidget {
  const _PersistentBottomBar({
    required super.child,
    required this.extent,
    required this.requiredMinExtent,
  });

  final SheetExtent extent;
  final Extent requiredMinExtent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPersistentBottomBar(
      extent: extent,
      requiredMinExtent: requiredMinExtent,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPersistentBottomBar renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.extent = extent;
  }
}

class _RenderPersistentBottomBar extends RenderTransform {
  _RenderPersistentBottomBar({
    required SheetExtent extent,
    required Extent requiredMinExtent,
  })  : _extent = extent,
        _requiredMinExtent = requiredMinExtent,
        super(transform: Matrix4.zero(), transformHitTests: true) {
    _extent.addListener(_invalidateOffset);
  }

  SheetExtent _extent;
  // ignore: avoid_setters_without_getters
  set extent(SheetExtent value) {
    if (_extent != value) {
      _extent.removeListener(_invalidateOffset);
      _extent = value..addListener(_invalidateOffset);
      markNeedsPaint();
    }
  }

  Extent _requiredMinExtent;
  // ignore: avoid_setters_without_getters
  set requiredMinExtent(Extent value) {
    if (_requiredMinExtent != value) {
      _requiredMinExtent = value;
      markNeedsPaint();
    }
  }

  // Cache the last measured size because we can't access
  // 'size' property from outside of the layout phase.
  late Size _lastMeasuredSize;

  @override
  void performLayout() {
    super.performLayout();
    _lastMeasuredSize = size;
  }

  void _invalidateOffset() {
    if (_extent.hasPixels) {
      final metrics = _extent.metrics;
      final minPixels = max(
        _requiredMinExtent.resolve(metrics.contentDimensions),
        _lastMeasuredSize.height,
      );
      final translation =
          max(metrics.pixels, minPixels) - metrics.viewportDimensions.height;
      transform = Matrix4.translationValues(0, min(0.0, translation), 0);
    }
  }
}

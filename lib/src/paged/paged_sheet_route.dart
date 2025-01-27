import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

import '../foundation/foundation.dart';
import '../foundation/model_owner.dart';
import '../scrollable/scrollable_sheet.dart';
import 'paged_sheet_geometry.dart';

// TODO: DRY this widget across the library.
class _RouteContentLayoutObserver extends SingleChildRenderObjectWidget {
  const _RouteContentLayoutObserver({
    required this.parentRoute,
    required super.child,
  });

  final BasePagedSheetRoute parentRoute;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRouteContentLayoutObserver(
      parentRoute: parentRoute,
      controller: SheetModelOwner.of<PagedSheetGeometry>(context)!,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRouteContentLayoutObserver renderObject,
  ) {
    assert(parentRoute == renderObject.parentRoute);
    renderObject.controller = SheetModelOwner.of<PagedSheetGeometry>(context)!;
  }
}

class _RenderRouteContentLayoutObserver extends RenderProxyBox {
  _RenderRouteContentLayoutObserver({
    required this.parentRoute,
    required PagedSheetGeometry controller,
  }) : _controller = controller;

  final BasePagedSheetRoute parentRoute;

  PagedSheetGeometry _controller;

  // ignore: avoid_setters_without_getters
  set controller(PagedSheetGeometry value) {
    if (_controller != value) {
      _controller = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    if (child?.size case final childSize?) {
      _controller.applyNewRouteContentSize(parentRoute, childSize);
    }
  }
}

@internal
@optionalTypeArgs
abstract class BasePagedSheetRoute<T> extends PageRoute<T>
    with ObservableRouteMixin<T> {
  BasePagedSheetRoute({super.settings});

  SheetOffset get initialOffset;

  SheetOffset get minOffset;

  SheetOffset get maxOffset;

  SheetPhysics get physics;

  RouteTransitionsBuilder? get transitionsBuilder;

  SheetDragConfiguration? get dragConfiguration;

  // TODO: Apply new configuration when the current route changes.
  SheetScrollConfiguration? get scrollConfiguration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is BasePagedSheetRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is BasePagedSheetRoute;
  }

  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  );

  @override
  @nonVirtual
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ResizableNavigatorRouteContentBoundary(
      child: _RouteContentLayoutObserver(
        parentRoute: this,
        child: DraggableScrollableSheetContent(
          scrollConfiguration: scrollConfiguration,
          dragConfiguration: dragConfiguration,
          child: buildContent(
            context,
            animation,
            secondaryAnimation,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionsBuilder case final builder?) {
      return builder(context, animation, secondaryAnimation, child);
    }
    final theme = Theme.of(context).pageTransitionsTheme;
    return theme.buildTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class PagedSheetRoute<T> extends BasePagedSheetRoute<T> {
  PagedSheetRoute({
    super.settings,
    this.maintainState = true,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset.relative(1),
    this.minOffset = const SheetOffset.relative(1),
    this.maxOffset = const SheetOffset.relative(1),
    this.physics = kDefaultSheetPhysics,
    this.transitionsBuilder,
    required this.builder,
  });

  @override
  final SheetOffset initialOffset;

  @override
  final SheetOffset minOffset;

  @override
  final SheetOffset maxOffset;

  @override
  final SheetPhysics physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  @override
  final SheetDragConfiguration? dragConfiguration;

  @override
  final SheetScrollConfiguration? scrollConfiguration;

  final WidgetBuilder builder;

  @override
  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }
}

class PagedSheetPage<T> extends Page<T> {
  const PagedSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset.relative(1),
    this.minOffset = const SheetOffset.relative(1),
    this.maxOffset = const SheetOffset.relative(1),
    this.physics = kDefaultSheetPhysics,
    this.transitionsBuilder,
    required this.child,
  });

  final SheetOffset initialOffset;

  final SheetOffset minOffset;

  final SheetOffset maxOffset;

  final SheetPhysics physics;

  final bool maintainState;

  final Duration transitionDuration;

  final RouteTransitionsBuilder? transitionsBuilder;

  final SheetDragConfiguration? dragConfiguration;

  final SheetScrollConfiguration? scrollConfiguration;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedNavigationSheetRoute(page: this);
  }
}

class _PageBasedNavigationSheetRoute<T> extends BasePagedSheetRoute<T> {
  _PageBasedNavigationSheetRoute({
    required PagedSheetPage<T> page,
  }) : super(settings: page);

  PagedSheetPage<T> get page => settings as PagedSheetPage<T>;

  @override
  bool get maintainState => page.maintainState;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  RouteTransitionsBuilder? get transitionsBuilder => page.transitionsBuilder;

  @override
  SheetDragConfiguration? get dragConfiguration => page.dragConfiguration;

  @override
  SheetScrollConfiguration? get scrollConfiguration => page.scrollConfiguration;

  @override
  SheetOffset get initialOffset => page.initialOffset;

  @override
  SheetOffset get maxOffset => page.maxOffset;

  @override
  SheetOffset get minOffset => page.minOffset;

  @override
  SheetPhysics get physics => page.physics;

  @override
  Widget buildContent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page.child;
  }
}

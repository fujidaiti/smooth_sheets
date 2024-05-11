import 'package:flutter/material.dart';

import '../draggable/draggable_sheet_extent.dart';
import '../draggable/sheet_draggable.dart';
import '../foundation/physics.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/theme.dart';
import '../scrollable/scrollable_sheet.dart';
import '../scrollable/scrollable_sheet_extent.dart';
import '../scrollable/scrollable_sheet_physics.dart';
import 'navigation_sheet.dart';

class _ScrollableNavigationSheetRouteContent extends StatelessWidget {
  const _ScrollableNavigationSheetRouteContent({
    this.debugLabel,
    required this.initialExtent,
    required this.minExtent,
    required this.maxExtent,
    required this.physics,
    required this.child,
  });

  final String? debugLabel;
  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics? physics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    // TODO: Do this in ScrollableSheetConfig
    final physics = switch (this.physics ?? theme?.physics) {
      null => const ScrollableSheetPhysics(parent: kDefaultSheetPhysics),
      final ScrollableSheetPhysics scrollablePhysics => scrollablePhysics,
      final otherPhysics => ScrollableSheetPhysics(parent: otherPhysics),
    };

    return NavigationSheetRouteContent(
      factory: const ScrollableSheetExtentFactory(),
      config: ScrollableSheetExtentConfig(
        debugLabel: debugLabel,
        initialExtent: initialExtent,
        minExtent: minExtent,
        maxExtent: maxExtent,
        physics: physics,
      ),
      child: PrimarySheetContentScrollController(child: child),
    );
  }
}

class _DraggableNavigationSheetRouteContent extends StatelessWidget {
  const _DraggableNavigationSheetRouteContent({
    this.debugLabel,
    required this.initialExtent,
    required this.minExtent,
    required this.maxExtent,
    required this.physics,
    required this.child,
  });

  final String? debugLabel;
  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics? physics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final physics = this.physics ?? theme?.physics ?? kDefaultSheetPhysics;

    return NavigationSheetRouteContent(
      factory: const DraggableSheetExtentFactory(),
      config: DraggableSheetExtentConfig(
        debugLabel: debugLabel,
        initialExtent: initialExtent,
        minExtent: minExtent,
        maxExtent: maxExtent,
        physics: physics,
      ),
      child: SheetDraggable(child: child),
    );
  }
}

class ScrollableNavigationSheetRoute<T> extends NavigationSheetRoute<T> {
  ScrollableNavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.builder,
  });

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics? physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  final WidgetBuilder builder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ScrollableNavigationSheetRouteContent(
      debugLabel: '$ScrollableNavigationSheetRoute(${settings.name})',
      initialExtent: initialExtent,
      minExtent: minExtent,
      maxExtent: maxExtent,
      physics: physics,
      child: builder(context),
    );
  }
}

class DraggableNavigationSheetRoute<T> extends NavigationSheetRoute<T> {
  DraggableNavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.builder,
  });

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics? physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  final WidgetBuilder builder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _DraggableNavigationSheetRouteContent(
      debugLabel: '$DraggableNavigationSheetRoute(${settings.name})',
      initialExtent: initialExtent,
      minExtent: minExtent,
      maxExtent: maxExtent,
      physics: physics,
      child: builder(context),
    );
  }
}

class ScrollableNavigationSheetPage<T> extends Page<T> {
  const ScrollableNavigationSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Duration transitionDuration;

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;

  final SheetPhysics? physics;

  final RouteTransitionsBuilder? transitionsBuilder;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedScrollableNavigationSheetRoute(page: this);
  }
}

class _PageBasedScrollableNavigationSheetRoute<T>
    extends NavigationSheetRoute<T> {
  _PageBasedScrollableNavigationSheetRoute({
    required ScrollableNavigationSheetPage<T> page,
  }) : super(settings: page);

  ScrollableNavigationSheetPage<T> get page =>
      settings as ScrollableNavigationSheetPage<T>;

  @override
  bool get maintainState => page.maintainState;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  RouteTransitionsBuilder? get transitionsBuilder => page.transitionsBuilder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ScrollableNavigationSheetRouteContent(
      debugLabel: '$ScrollableNavigationSheetPage(${page.name})',
      initialExtent: page.initialExtent,
      minExtent: page.minExtent,
      maxExtent: page.maxExtent,
      physics: page.physics,
      child: page.child,
    );
  }
}

class DraggableNavigationSheetPage<T> extends Page<T> {
  const DraggableNavigationSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Duration transitionDuration;

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;

  final SheetPhysics? physics;

  final RouteTransitionsBuilder? transitionsBuilder;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedDraggableNavigationSheetRoute(page: this);
  }
}

class _PageBasedDraggableNavigationSheetRoute<T>
    extends NavigationSheetRoute<T> {
  _PageBasedDraggableNavigationSheetRoute({
    required DraggableNavigationSheetPage<T> page,
  }) : super(settings: page);

  DraggableNavigationSheetPage<T> get page =>
      settings as DraggableNavigationSheetPage<T>;

  @override
  bool get maintainState => page.maintainState;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  RouteTransitionsBuilder? get transitionsBuilder => page.transitionsBuilder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _DraggableNavigationSheetRouteContent(
      debugLabel: '$DraggableNavigationSheetPage(${page.name})',
      initialExtent: page.initialExtent,
      minExtent: page.minExtent,
      maxExtent: page.maxExtent,
      physics: page.physics,
      child: page.child,
    );
  }
}

import 'package:flutter/material.dart';
import '../draggable/draggable_sheet.dart';
import '../draggable/sheet_draggable.dart';
import '../foundation/physics.dart';
import '../foundation/sheet_extent.dart';
import '../scrollable/scrollable_sheet.dart';
import '../scrollable/scrollable_sheet_extent.dart';
import 'navigation_route.dart';
import 'navigation_sheet.dart';

class ScrollableNavigationSheetRoute<T> extends NavigationSheetRoute<T>
    with NavigationSheetRouteMixin<T> {
  ScrollableNavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics = const StretchingSheetPhysics(parent: SnappingSheetPhysics()),
    this.transitionsBuilder,
    required this.builder,
  }) : pageExtentConfig = ScrollableSheetExtentConfig(
          initialExtent: initialExtent,
          minExtent: minExtent,
          maxExtent: maxExtent,
          physics: physics,
        );

  @override
  final ScrollableSheetExtentConfig pageExtentConfig;

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  final RouteTransitionsBuilder? transitionsBuilder;

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) {
    return PrimarySheetContentScrollController(
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final builder = transitionsBuilder ?? super.buildTransitions;
    return builder(context, animation, secondaryAnimation, child);
  }
}

class DraggableNavigationSheetRoute<T> extends NavigationSheetRoute<T>
    with NavigationSheetRouteMixin<T> {
  DraggableNavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics = const StretchingSheetPhysics(parent: SnappingSheetPhysics()),
    this.transitionsBuilder,
    required this.builder,
  }) : pageExtentConfig = DraggableSheetExtentConfig(
          initialExtent: initialExtent,
          minExtent: minExtent,
          maxExtent: maxExtent,
          physics: physics,
        );

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  final RouteTransitionsBuilder? transitionsBuilder;

  final WidgetBuilder builder;

  @override
  final DraggableSheetExtentConfig pageExtentConfig;

  @override
  Widget buildContent(BuildContext context) {
    return SheetDraggable(
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final builder = transitionsBuilder ?? super.buildTransitions;
    return builder(context, animation, secondaryAnimation, child);
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
    this.physics = const StretchingSheetPhysics(parent: SnappingSheetPhysics()),
    this.transitionsBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Duration transitionDuration;

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;

  final SheetPhysics physics;

  final RouteTransitionsBuilder? transitionsBuilder;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedScrollableNavigationSheetRoute(page: this);
  }
}

class _PageBasedScrollableNavigationSheetRoute<T>
    extends NavigationSheetRoute<T> with NavigationSheetRouteMixin<T> {
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
  ScrollableSheetExtentConfig get pageExtentConfig => _pageExtentConfig!;
  ScrollableSheetExtentConfig? _pageExtentConfig;

  @override
  void changedInternalState() {
    super.changedInternalState();
    if (page.initialExtent != _pageExtentConfig?.initialExtent ||
        page.minExtent != _pageExtentConfig?.minExtent ||
        page.maxExtent != _pageExtentConfig?.maxExtent ||
        page.physics != _pageExtentConfig?.physics) {
      _pageExtentConfig = ScrollableSheetExtentConfig(
        initialExtent: page.initialExtent,
        minExtent: page.minExtent,
        maxExtent: page.maxExtent,
        physics: page.physics,
      );
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final builder = page.transitionsBuilder ?? super.buildTransitions;
    return builder(context, animation, secondaryAnimation, child);
  }

  @override
  Widget buildContent(BuildContext context) {
    return PrimarySheetContentScrollController(
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
    this.physics = const StretchingSheetPhysics(parent: SnappingSheetPhysics()),
    this.transitionsBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Duration transitionDuration;

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;

  final SheetPhysics physics;

  final RouteTransitionsBuilder? transitionsBuilder;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedDraggableNavigationSheetRoute(page: this);
  }
}

class _PageBasedDraggableNavigationSheetRoute<T> extends NavigationSheetRoute<T>
    with NavigationSheetRouteMixin<T> {
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
  DraggableSheetExtentConfig get pageExtentConfig => _pageExtentConfig!;
  DraggableSheetExtentConfig? _pageExtentConfig;

  @override
  void changedInternalState() {
    super.changedInternalState();
    if (page.initialExtent != _pageExtentConfig?.initialExtent ||
        page.minExtent != _pageExtentConfig?.minExtent ||
        page.maxExtent != _pageExtentConfig?.maxExtent ||
        page.physics != _pageExtentConfig?.physics) {
      _pageExtentConfig = DraggableSheetExtentConfig(
        initialExtent: page.initialExtent,
        minExtent: page.minExtent,
        maxExtent: page.maxExtent,
        physics: page.physics,
      );
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final builder = page.transitionsBuilder ?? super.buildTransitions;
    return builder(context, animation, secondaryAnimation, child);
  }

  @override
  Widget buildContent(BuildContext context) {
    return SheetDraggable(child: page.child);
  }
}

import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet.dart';

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
  }) : pageExtentFactory = ScrollableSheetExtentFactory(
          initialExtent: initialExtent,
          minExtent: minExtent,
          maxExtent: maxExtent,
          physics: physics,
        );

  @override
  final ScrollableSheetExtentFactory pageExtentFactory;

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
  }) : pageExtentFactory = DraggableSheetExtentFactory(
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
  final DraggableSheetExtentFactory pageExtentFactory;

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
  ScrollableSheetExtentFactory get pageExtentFactory => _pageExtentFactory!;
  ScrollableSheetExtentFactory? _pageExtentFactory;

  @override
  void changedInternalState() {
    super.changedInternalState();
    if (page.initialExtent != _pageExtentFactory?.initialExtent ||
        page.minExtent != _pageExtentFactory?.minExtent ||
        page.maxExtent != _pageExtentFactory?.maxExtent ||
        page.physics != _pageExtentFactory?.physics) {
      _pageExtentFactory = ScrollableSheetExtentFactory(
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
  DraggableSheetExtentFactory get pageExtentFactory => _pageExtentFactory!;
  DraggableSheetExtentFactory? _pageExtentFactory;

  @override
  void changedInternalState() {
    super.changedInternalState();
    if (page.initialExtent != _pageExtentFactory?.initialExtent ||
        page.minExtent != _pageExtentFactory?.minExtent ||
        page.maxExtent != _pageExtentFactory?.maxExtent ||
        page.physics != _pageExtentFactory?.physics) {
      _pageExtentFactory = DraggableSheetExtentFactory(
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

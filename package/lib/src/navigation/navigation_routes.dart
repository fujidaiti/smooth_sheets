import 'package:flutter/material.dart';
import 'package:smooth_sheets/src/draggable/draggable_sheet.dart';
import 'package:smooth_sheets/src/draggable/sheet_draggable.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';
import 'package:smooth_sheets/src/foundation/sized_content_sheet.dart';
import 'package:smooth_sheets/src/navigation/navigation_route.dart';
import 'package:smooth_sheets/src/navigation/navigation_sheet.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet_extent.dart';

abstract class SingleChildNavigationSheetRoute<T>
    extends NavigationSheetRoute<T> with NavigationSheetRouteMixin<T> {
  SingleChildNavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics = const StretchingSheetPhysics(parent: SnappingSheetPhysics()),
    this.transitionsBuilder,
    required this.builder,
  });

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
  SizedContentSheetExtentFactory get pageExtentFactory;

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

abstract class SingleChildNavigationSheetPage<T> extends Page<T> {
  const SingleChildNavigationSheetPage({
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
}

abstract class PageBasedSingleChildNavigationSheetRoute<T,
        P extends SingleChildNavigationSheetPage<T>>
    extends NavigationSheetRoute<T> with NavigationSheetRouteMixin<T> {
  PageBasedSingleChildNavigationSheetRoute({
    required P page,
  }) : super(settings: page);

  P get page => settings as P;

  @override
  bool get maintainState => page.maintainState;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  SizedContentSheetExtentFactory get pageExtentFactory => _pageExtentFactory!;
  SizedContentSheetExtentFactory? _pageExtentFactory;

  @override
  void changedInternalState() {
    super.changedInternalState();
    if (shouldUpdatePageExtentFactory()) {
      _pageExtentFactory = createPageExtentFactory();
    }
  }

  SizedContentSheetExtentFactory createPageExtentFactory();

  bool shouldUpdatePageExtentFactory() {
    return page.initialExtent != _pageExtentFactory?.initialExtent ||
        page.minExtent != _pageExtentFactory?.minExtent ||
        page.maxExtent != _pageExtentFactory?.maxExtent ||
        page.physics != _pageExtentFactory?.physics;
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
}

class ScrollableNavigationSheetRoute<T>
    extends SingleChildNavigationSheetRoute<T> {
  ScrollableNavigationSheetRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.transitionDuration,
    super.initialExtent,
    super.minExtent,
    super.maxExtent,
    super.physics,
    super.transitionsBuilder,
  }) : pageExtentFactory = ScrollableSheetExtentFactory(
          initialExtent: initialExtent,
          minExtent: minExtent,
          maxExtent: maxExtent,
          physics: physics,
        );

  @override
  final ScrollableSheetExtentFactory pageExtentFactory;

  @override
  Widget buildContent(BuildContext context) {
    return PrimarySheetContentScrollController(
      child: builder(context),
    );
  }
}

class DraggableNavigationSheetRoute<T>
    extends SingleChildNavigationSheetRoute<T> {
  DraggableNavigationSheetRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.transitionDuration,
    super.initialExtent,
    super.minExtent,
    super.maxExtent,
    super.physics,
    super.transitionsBuilder,
  }) : pageExtentFactory = DraggableSheetExtentFactory(
          initialExtent: initialExtent,
          minExtent: minExtent,
          maxExtent: maxExtent,
          physics: physics,
        );

  @override
  final DraggableSheetExtentFactory pageExtentFactory;

  @override
  Widget buildContent(BuildContext context) {
    return SheetDraggable(
      child: builder(context),
    );
  }
}

class ScrollableNavigationSheetPage<T>
    extends SingleChildNavigationSheetPage<T> {
  const ScrollableNavigationSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.maintainState,
    super.transitionDuration,
    super.initialExtent,
    super.minExtent,
    super.maxExtent,
    super.physics,
    super.transitionsBuilder,
    required super.child,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedScrollableNavigationSheetRoute(page: this);
  }
}

class _PageBasedScrollableNavigationSheetRoute<T>
    extends PageBasedSingleChildNavigationSheetRoute<T,
        ScrollableNavigationSheetPage<T>> {
  _PageBasedScrollableNavigationSheetRoute({required super.page});

  @override
  SizedContentSheetExtentFactory createPageExtentFactory() {
    return ScrollableSheetExtentFactory(
      initialExtent: page.initialExtent,
      minExtent: page.minExtent,
      maxExtent: page.maxExtent,
      physics: page.physics,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return PrimarySheetContentScrollController(
      child: page.child,
    );
  }
}

class DraggableNavigationSheetPage<T>
    extends SingleChildNavigationSheetPage<T> {
  const DraggableNavigationSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.maintainState,
    super.transitionDuration,
    super.initialExtent,
    super.minExtent,
    super.maxExtent,
    super.physics,
    super.transitionsBuilder,
    required super.child,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedDraggableNavigationSheetRoute(page: this);
  }
}

class _PageBasedDraggableNavigationSheetRoute<T>
    extends PageBasedSingleChildNavigationSheetRoute<T,
        DraggableNavigationSheetPage<T>> {
  _PageBasedDraggableNavigationSheetRoute({required super.page});

  @override
  SizedContentSheetExtentFactory createPageExtentFactory() {
    return DraggableSheetExtentFactory(
      initialExtent: page.initialExtent,
      minExtent: page.minExtent,
      maxExtent: page.maxExtent,
      physics: page.physics,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return SheetDraggable(
      child: page.child,
    );
  }
}

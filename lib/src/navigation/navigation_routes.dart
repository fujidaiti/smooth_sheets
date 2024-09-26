import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../draggable/draggable_sheet_extent.dart';
import '../draggable/draggable_sheet_extent_scope.dart';
import '../draggable/sheet_draggable.dart';
import '../foundation/sheet_extent_scope.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_theme.dart';
import '../scrollable/scrollable_sheet.dart';
import '../scrollable/scrollable_sheet_extent.dart';
import '../scrollable/scrollable_sheet_extent_scope.dart';
import 'navigation_route.dart';

class _ScrollableNavigationSheetRouteContent extends StatelessWidget {
  const _ScrollableNavigationSheetRouteContent({
    this.debugLabel,
    required this.initialExtent,
    required this.minPosition,
    required this.maxExtent,
    required this.physics,
    required this.child,
  });

  final String? debugLabel;
  final SheetAnchor initialExtent;
  final SheetAnchor minPosition;
  final SheetAnchor maxExtent;
  final SheetPhysics? physics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final gestureTamper = SheetGestureProxy.maybeOf(context);

    return NavigationSheetRouteContent(
      scopeBuilder: (context, key, child) {
        return ScrollableSheetExtentScope(
          key: key,
          context: context,
          isPrimary: false,
          initialExtent: initialExtent,
          minPosition: minPosition,
          maxExtent: maxExtent,
          physics: physics ?? theme?.physics ?? kDefaultSheetPhysics,
          gestureTamperer: gestureTamper,
          child: child,
        );
      },
      child: ScrollableSheetContent(child: child),
    );
  }
}

class _DraggableNavigationSheetRouteContent extends StatelessWidget {
  const _DraggableNavigationSheetRouteContent({
    this.debugLabel,
    required this.initialExtent,
    required this.minPosition,
    required this.maxExtent,
    required this.physics,
    required this.child,
  });

  final String? debugLabel;
  final SheetAnchor initialExtent;
  final SheetAnchor minPosition;
  final SheetAnchor maxExtent;
  final SheetPhysics? physics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final physics = this.physics ?? theme?.physics ?? kDefaultSheetPhysics;
    final gestureTamper = SheetGestureProxy.maybeOf(context);

    return NavigationSheetRouteContent(
      scopeBuilder: (context, key, child) {
        return DraggableSheetExtentScope(
          key: key,
          context: context,
          isPrimary: false,
          initialExtent: initialExtent,
          minPosition: minPosition,
          maxExtent: maxExtent,
          physics: physics,
          gestureTamperer: gestureTamper,
          debugLabel: debugLabel,
          child: child,
        );
      },
      child: SheetDraggable(child: child),
    );
  }
}

class ScrollableNavigationSheetRoute<T>
    extends NavigationSheetRoute<T, ScrollableSheetExtent> {
  ScrollableNavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxExtent = const SheetAnchor.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.builder,
  });

  final SheetAnchor initialExtent;
  final SheetAnchor minPosition;
  final SheetAnchor maxExtent;
  final SheetPhysics? physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  final WidgetBuilder builder;

  @override
  SheetExtentScopeKey<ScrollableSheetExtent> createScopeKey() {
    return SheetExtentScopeKey<ScrollableSheetExtent>(
      debugLabel: kDebugMode ? '$debugLabel:${describeIdentity(this)}' : null,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ScrollableNavigationSheetRouteContent(
      debugLabel: '$ScrollableNavigationSheetRoute(${settings.name})',
      initialExtent: initialExtent,
      minPosition: minPosition,
      maxExtent: maxExtent,
      physics: physics,
      child: builder(context),
    );
  }
}

class DraggableNavigationSheetRoute<T>
    extends NavigationSheetRoute<T, DraggableSheetExtent> {
  DraggableNavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialExtent = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxExtent = const SheetAnchor.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.builder,
  });

  final SheetAnchor initialExtent;
  final SheetAnchor minPosition;
  final SheetAnchor maxExtent;
  final SheetPhysics? physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  final WidgetBuilder builder;

  @override
  SheetExtentScopeKey<DraggableSheetExtent> createScopeKey() {
    return SheetExtentScopeKey<DraggableSheetExtent>(
      debugLabel: kDebugMode ? '$debugLabel:${describeIdentity(this)}' : null,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _DraggableNavigationSheetRouteContent(
      debugLabel: '$DraggableNavigationSheetRoute(${settings.name})',
      initialExtent: initialExtent,
      minPosition: minPosition,
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
    this.initialExtent = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxExtent = const SheetAnchor.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Duration transitionDuration;

  final SheetAnchor initialExtent;
  final SheetAnchor minPosition;
  final SheetAnchor maxExtent;

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
    extends NavigationSheetRoute<T, ScrollableSheetExtent> {
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
  SheetExtentScopeKey<ScrollableSheetExtent> createScopeKey() {
    return SheetExtentScopeKey<ScrollableSheetExtent>(
      debugLabel: kDebugMode ? '$debugLabel:${describeIdentity(this)}' : null,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ScrollableNavigationSheetRouteContent(
      debugLabel: '$ScrollableNavigationSheetPage(${page.name})',
      initialExtent: page.initialExtent,
      minPosition: page.minPosition,
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
    this.initialExtent = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxExtent = const SheetAnchor.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Duration transitionDuration;

  final SheetAnchor initialExtent;
  final SheetAnchor minPosition;
  final SheetAnchor maxExtent;

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
    extends NavigationSheetRoute<T, DraggableSheetExtent> {
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
  SheetExtentScopeKey<DraggableSheetExtent> createScopeKey() {
    return SheetExtentScopeKey<DraggableSheetExtent>(
      debugLabel: kDebugMode ? '$debugLabel:${describeIdentity(this)}' : null,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _DraggableNavigationSheetRouteContent(
      debugLabel: '$DraggableNavigationSheetPage(${page.name})',
      initialExtent: page.initialExtent,
      minPosition: page.minPosition,
      maxExtent: page.maxExtent,
      physics: page.physics,
      child: page.child,
    );
  }
}

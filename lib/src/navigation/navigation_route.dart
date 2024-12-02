import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/sheet_viewport.dart';
import '../scrollable/scrollable_sheet.dart';
import '../scrollable/scrollable_sheet_physics.dart';
import '../scrollable/scrollable_sheet_position.dart';
import '../scrollable/scrollable_sheet_position_scope.dart';
import 'navigation_sheet.dart';
import 'navigation_sheet_position.dart';

@optionalTypeArgs
abstract class BasicNavigationSheetRoute<T, E extends SheetPosition>
    extends PageRoute<T> {
  BasicNavigationSheetRoute({super.settings});

  SheetPositionScopeKey<E> get scopeKey => _scopeKey;
  late final SheetPositionScopeKey<E> _scopeKey;

  SheetPositionScopeKey<E> createScopeKey();

  @override
  void install() {
    super.install();
    assert(_debugAssertDependencies());
    _scopeKey = createScopeKey();
  }

  @override
  void dispose() {
    _scopeKey.dispose();
    super.dispose();
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    assert(_debugAssertDependencies());
  }

  bool _debugAssertDependencies() {
    assert(
      () {
        final globalPosition =
            SheetPositionScope.maybeOf<NavigationSheetPosition>(
                navigator!.context);
        if (globalPosition == null) {
          throw FlutterError(
            'A $SheetPositionScope that hosts a $NavigationSheetPosition '
            'is not found in the given context. This is likely because '
            'this $BasicNavigationSheetRoute is not a route of the navigator '
            'enclosed by a $NavigationSheet.',
          );
        }
        return true;
      }(),
    );
    return true;
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  RouteTransitionsBuilder? get transitionsBuilder;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is BasicNavigationSheetRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is BasicNavigationSheetRoute;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final builder = transitionsBuilder ?? _buildDefaultTransitions;
    return builder(context, animation, secondaryAnimation, child);
  }

  Widget _buildDefaultTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final theme = Theme.of(context).pageTransitionsTheme;
    final platformAdaptiveTransitions = theme.buildTransitions<T>(
        this, context, animation, secondaryAnimation, child);

    final fadeInTween = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 1,
      ),
    ]);

    final fadeOutTween = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
    ]);

    return FadeTransition(
      opacity: animation.drive(fadeInTween),
      child: FadeTransition(
        opacity: secondaryAnimation.drive(fadeOutTween),
        child: platformAdaptiveTransitions,
      ),
    );
  }
}

typedef SheetPositionScopeBuilder = SheetPositionScope Function(
  SheetContext context,
  SheetPositionScopeKey key,
  Widget child,
);

class NavigationSheetRouteContent extends StatelessWidget {
  const NavigationSheetRouteContent({
    super.key,
    required this.scopeBuilder,
    required this.child,
  });

  final SheetPositionScopeBuilder scopeBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(_debugAssertDependencies(context));
    final parentRoute = ModalRoute.of(context)! as BasicNavigationSheetRoute;
    final globalPosition =
        SheetPositionScope.of<NavigationSheetPosition>(context);
    final routeViewport = SheetContentViewport(child: child);
    final localScope = scopeBuilder(
      globalPosition.context,
      parentRoute.scopeKey,
      routeViewport,
    );
    assert(_debugAssertScope(localScope, parentRoute.scopeKey, routeViewport));
    return localScope;
  }

  bool _debugAssertScope(
    SheetPositionScope scope,
    Key expectedKey,
    Widget expectedChild,
  ) {
    assert(() {
      if (scope.key != expectedKey) {
        throw FlutterError(
          'The key of the SheetPositionScope returned by `scopeBuilder` does '
          'not match the key passed to the builder. This is likely a mistake.',
        );
      }
      if (scope.child != expectedChild) {
        throw FlutterError(
          'The child of the SheetPositionScope returned by `scopeBuilder` does '
          'not match the child passed to the builder. '
          'This is likely a mistake.',
        );
      }
      if (scope.controller != null) {
        throw FlutterError(
          'The SheetPositionScope returned by the `scopeBuilder` should not '
          'have a controller. Since the controller is managed by the global '
          ' scope, this is likely a mistake.',
        );
      }
      return true;
    }());
    return true;
  }

  bool _debugAssertDependencies(BuildContext context) {
    assert(
      () {
        final globalPosition =
            SheetPositionScope.maybeOf<NavigationSheetPosition>(context);
        if (globalPosition == null) {
          throw FlutterError(
            'A SheetPositionScope that hosts a $NavigationSheetPosition '
            'is not found in the given context. This is likely because '
            'this NavigationSheetRouteContent is not in the subtree of '
            'the navigator enclosed by a NavigationSheet.',
          );
        }

        final parentRoute = ModalRoute.of(context);
        if (parentRoute is BasicNavigationSheetRoute) {
          return true;
        }
        throw FlutterError(
          'The NavigationSheetRouteContent must be the content of '
          'a NavigationSheetRoute, but the result of ModalRoute.of(context) '
          'is ${parentRoute?.runtimeType}.',
        );
      }(),
    );
    return true;
  }
}

class _DraggableScrollableNavigationSheetRouteContent extends StatelessWidget {
  const _DraggableScrollableNavigationSheetRouteContent({
    this.debugLabel,
    required this.initialPosition,
    required this.minPosition,
    required this.maxPosition,
    required this.physics,
    required this.scrollConfiguration,
    required this.dragConfiguration,
    required this.child,
  });

  final String? debugLabel;
  final SheetAnchor initialPosition;
  final SheetAnchor minPosition;
  final SheetAnchor maxPosition;
  final SheetPhysics? physics;
  final SheetScrollConfiguration? scrollConfiguration;
  final SheetDragConfiguration? dragConfiguration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final gestureTamper = SheetGestureProxy.maybeOf(context);

    var physics = this.physics ?? theme?.physics ?? kDefaultSheetPhysics;
    if (scrollConfiguration case final config?) {
      physics = ScrollableSheetPhysics(
        parent: physics,
        maxScrollSpeedToInterrupt:
            config.thresholdVelocityToInterruptBallisticScroll,
      );
    }

    return NavigationSheetRouteContent(
      scopeBuilder: (context, key, child) {
        return ScrollableSheetPositionScope(
          key: key,
          context: context,
          isPrimary: false,
          initialPosition: initialPosition,
          minPosition: minPosition,
          maxPosition: maxPosition,
          physics: physics,
          gestureTamperer: gestureTamper,
          child: child,
        );
      },
      child: DraggableScrollableSheetContent(
        scrollConfiguration: scrollConfiguration,
        dragConfiguration: dragConfiguration,
        child: child,
      ),
    );
  }
}

class NavigationSheetRoute<T>
    extends BasicNavigationSheetRoute<T, DraggableScrollableSheetPosition> {
  NavigationSheetRoute({
    super.settings,
    this.maintainState = true,
    this.scrollConfiguration,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialPosition = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxPosition = const SheetAnchor.proportional(1),
    this.physics,
    this.transitionsBuilder,
    required this.builder,
  });

  final SheetAnchor initialPosition;
  final SheetAnchor minPosition;
  final SheetAnchor maxPosition;
  final SheetPhysics? physics;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  @override
  final RouteTransitionsBuilder? transitionsBuilder;

  final WidgetBuilder builder;

  final SheetDragConfiguration? dragConfiguration;
  final SheetScrollConfiguration? scrollConfiguration;

  @override
  SheetPositionScopeKey<DraggableScrollableSheetPosition> createScopeKey() {
    return SheetPositionScopeKey<DraggableScrollableSheetPosition>(
      debugLabel: kDebugMode ? '$debugLabel:${describeIdentity(this)}' : null,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _DraggableScrollableNavigationSheetRouteContent(
      debugLabel: '$NavigationSheetRoute(${settings.name})',
      dragConfiguration: dragConfiguration,
      scrollConfiguration: scrollConfiguration,
      initialPosition: initialPosition,
      minPosition: minPosition,
      maxPosition: maxPosition,
      physics: physics,
      child: builder(context),
    );
  }
}

class NavigationSheetPage<T> extends Page<T> {
  const NavigationSheetPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialPosition = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxPosition = const SheetAnchor.proportional(1),
    this.dragConfiguration = const SheetDragConfiguration(),
    this.scrollConfiguration,
    this.physics,
    this.transitionsBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  final Duration transitionDuration;

  final SheetAnchor initialPosition;
  final SheetAnchor minPosition;
  final SheetAnchor maxPosition;

  final SheetPhysics? physics;

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

class _PageBasedNavigationSheetRoute<T>
    extends BasicNavigationSheetRoute<T, DraggableScrollableSheetPosition> {
  _PageBasedNavigationSheetRoute({
    required NavigationSheetPage<T> page,
  }) : super(settings: page);

  NavigationSheetPage<T> get page => settings as NavigationSheetPage<T>;

  @override
  bool get maintainState => page.maintainState;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  RouteTransitionsBuilder? get transitionsBuilder => page.transitionsBuilder;

  @override
  SheetPositionScopeKey<DraggableScrollableSheetPosition> createScopeKey() {
    return SheetPositionScopeKey<DraggableScrollableSheetPosition>(
      debugLabel: kDebugMode ? '$debugLabel:${describeIdentity(this)}' : null,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _DraggableScrollableNavigationSheetRouteContent(
      debugLabel: '$NavigationSheetPage(${page.name})',
      scrollConfiguration: page.scrollConfiguration,
      dragConfiguration: page.dragConfiguration,
      initialPosition: page.initialPosition,
      minPosition: page.minPosition,
      maxPosition: page.maxPosition,
      physics: page.physics,
      child: page.child,
    );
  }
}

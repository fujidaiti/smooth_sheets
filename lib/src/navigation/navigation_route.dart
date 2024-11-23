import 'package:flutter/material.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import '../foundation/sheet_viewport.dart';
import 'navigation_sheet.dart';
import 'navigation_sheet_position.dart';

@optionalTypeArgs
abstract class NavigationSheetRoute<T, E extends SheetPosition>
    extends PageRoute<T> {
  NavigationSheetRoute({super.settings});

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
            'this $NavigationSheetRoute is not a route of the navigator '
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
    return previousRoute is NavigationSheetRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is NavigationSheetRoute;
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
    final parentRoute = ModalRoute.of(context)! as NavigationSheetRoute;
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
        if (parentRoute is NavigationSheetRoute) {
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

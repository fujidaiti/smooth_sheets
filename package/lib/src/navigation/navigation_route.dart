import 'package:flutter/material.dart';

import '../foundation/sheet_extent.dart';
import '../foundation/sheet_viewport.dart';
import 'navigation_sheet.dart';
import 'navigation_sheet_extent.dart';
import 'navigation_sheet_viewport.dart';

abstract class NavigationSheetRoute<T> extends PageRoute<T> {
  NavigationSheetRoute({super.settings});

  late NavigationSheetExtent _globalExtent;

  @override
  void install() {
    super.install();
    assert(_debugAssertDependencies());

    _globalExtent = SheetExtentScope.of(navigator!.context);
    _globalExtent.createLocalExtentScopeKey(this, debugLabel);
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    // Keep the reference to the global extent up-to-date since we need
    // to call disposeLocalExtentScopeKey() in dispose().
    _globalExtent = SheetExtentScope.of(navigator!.context);
  }

  @override
  void dispose() {
    _globalExtent.disposeLocalExtentScopeKey(this);
    super.dispose();
  }

  bool _debugAssertDependencies() {
    assert(
      () {
        final globalExtent = SheetExtentScope.maybeOf(navigator!.context);
        if (globalExtent is NavigationSheetExtent) {
          return true;
        }
        throw FlutterError(
          'A $SheetExtentScope that hosts a $NavigationSheetExtent '
          'is not found in the given context. This is likely because '
          'this $NavigationSheetRoute is not a route of the navigator '
          'enclosed by a $NavigationSheet.',
        );
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

typedef LocalExtentScopeBuilder = SheetExtentScope Function(
  SheetExtentScopeKey key,
  Widget child,
);

class NavigationSheetRouteContent extends StatelessWidget {
  const NavigationSheetRouteContent({
    super.key,
    required this.scopeBuilder,
    required this.child,
  });

  final LocalExtentScopeBuilder scopeBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(_debugAssertDependencies(context));
    final parentRoute = ModalRoute.of(context)!;
    final globalExtent = SheetExtentScope.of<NavigationSheetExtent>(context);
    final localScopeKey = globalExtent.getLocalExtentScopeKey(parentRoute);
    final routeViewport = NavigationSheetRouteViewport(
      child: SheetContentViewport(child: child),
    );
    final localScope = scopeBuilder(localScopeKey, routeViewport);

    assert(() {
      if (localScope.key != localScopeKey) {
        throw FlutterError(
          'The key of the $SheetExtentScope returned by the scopeBuilder '
          'does not match the key of the $SheetExtentScopeKey obtained from '
          'the global extent. This is likely a mistake.',
        );
      }
      if (localScope.child != routeViewport) {
        throw FlutterError(
          'The child of the $SheetExtentScope returned by the scopeBuilder '
          'does not match the child of the $NavigationSheetRouteViewport. '
          'This is likely a mistake.',
        );
      }
      if (localScope.controller != null) {
        throw FlutterError(
          'The controller of the $SheetExtentScope returned by the scopeBuilder '
          'is not null. The controller should be null because it is managed by '
          'the global extent.',
        );
      }
      return true;
    }());

    return localScope;
  }

  bool _debugAssertDependencies(BuildContext context) {
    assert(
      () {
        final parentRoute = ModalRoute.of(context);
        if (parentRoute is NavigationSheetRoute) {
          return true;
        }
        throw FlutterError(
          'The $NavigationSheetRouteContent must be the content of '
          'a $NavigationSheetRoute, but the result of ModalRoute.of(context) '
          'is ${parentRoute?.runtimeType}.',
        );
      }(),
    );
    assert(
      () {
        final globalExtent = SheetExtentScope.maybeOf(context);
        if (globalExtent is NavigationSheetExtent) {
          return true;
        }
        throw FlutterError(
          'A $SheetExtentScope that hosts a $NavigationSheetExtent '
          'is not found in the given context. This is likely because '
          'this $NavigationSheetRouteContent is not the content of a '
          '$NavigationSheetRoute.',
        );
      }(),
    );
    return true;
  }
}

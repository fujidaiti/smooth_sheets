import 'package:flutter/material.dart';

import '../foundation/framework.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_status.dart';
import 'navigation_sheet.dart';

abstract class NavigationSheetRoute<T> extends PageRoute<T>
    implements NavigationSheetEntry {
  NavigationSheetRoute({super.settings});

  final GlobalKey<SheetExtentScopeState> _scopeKey = GlobalKey();

  // Since the extent is lazily created, we need to keep track of the listeners
  // so that we can add them to the extent when it is created.
  final List<VoidCallback> _listeners = [];

  // ignore: use_late_for_private_fields_and_variables
  (Size, EdgeInsets)? _viewportDimensions;

  @override
  SheetMetrics get metrics =>
      _scopeKey.currentState?.extent.metrics ?? SheetMetrics.empty;

  @override
  SheetStatus get status =>
      _scopeKey.currentState?.extent.status ?? SheetStatus.stable;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    _scopeKey.currentState?.extent.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    _scopeKey.currentState?.extent.removeListener(listener);
  }

  @override
  void applyNewViewportDimensions(
    Size viewportSize,
    EdgeInsets viewportInsets,
  ) {
    _viewportDimensions = (viewportSize, viewportInsets);
    _scopeKey.currentState?.extent
        .applyNewViewportDimensions(viewportSize, viewportInsets);
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

class NavigationSheetRouteContent extends StatelessWidget {
  const NavigationSheetRouteContent({
    super.key,
    required this.config,
    required this.delegate,
    required this.child,
  });

  final SheetExtentConfig config;
  final SheetExtentDelegate delegate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(
      ModalRoute.of(context) is NavigationSheetRoute,
      '$NavigationSheetRouteContent can only be used '
      'within a $NavigationSheetRoute',
    );

    final route = ModalRoute.of(context)! as NavigationSheetRoute;
    return SheetExtentScope(
      key: route._scopeKey,
      isPrimary: false,
      config: config,
      delegate: delegate,
      controller: SheetControllerScope.of(context),
      initializer: (extent) {
        route._listeners.forEach(extent.addListener);
        if (route._viewportDimensions case (final size, final insets)) {
          extent.applyNewViewportDimensions(size, insets);
        }
        return extent;
      },
      child: SheetContentViewport(child: child),
    );
  }
}

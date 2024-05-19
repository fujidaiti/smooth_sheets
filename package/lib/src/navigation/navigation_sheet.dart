import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../foundation/keyboard_dismissible.dart';
import '../foundation/sheet_container.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_theme.dart';
import '../internal/transition_observer.dart';
import 'navigation_sheet_extent.dart';

typedef NavigationSheetTransitionObserver = TransitionObserver;

class NavigationSheet extends StatefulWidget with TransitionAwareWidgetMixin {
  const NavigationSheet({
    super.key,
    required this.transitionObserver,
    this.keyboardDismissBehavior,
    this.controller,
    required this.child,
  });

  @override
  final NavigationSheetTransitionObserver transitionObserver;

  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;
  final SheetController? controller;
  final Widget child;

  @override
  State<NavigationSheet> createState() => _NavigationSheetState();
}

class _NavigationSheetState extends State<NavigationSheet>
    with TransitionAwareStateMixin
    implements SheetExtentFactory<SheetExtentConfig, NavigationSheetExtent> {
  final _scopeKey = SheetExtentScopeKey<NavigationSheetExtent>(
    debugLabel: kDebugMode ? 'NavigationSheet' : null,
  );

  @override
  void didChangeTransitionState(Transition? transition) {
    _scopeKey.maybeCurrentExtent?.handleRouteTransition(transition);
  }

  @factory
  @override
  NavigationSheetExtent createSheetExtent({
    required SheetContext context,
    required SheetExtentConfig config,
  }) {
    return NavigationSheetExtent(
      context: context,
      config: config,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        widget.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;

    Widget result = ImplicitSheetControllerScope(
      controller: widget.controller,
      builder: (context, controller) {
        return SheetContainer(
          factory: this,
          scopeKey: _scopeKey,
          controller: controller,
          config: const SheetExtentConfig(
            minExtent: Extent.pixels(0),
            maxExtent: Extent.proportional(1),
            // TODO: Use more appropriate physics.
            physics: ClampingSheetPhysics(),
            debugLabel: kDebugMode ? 'NavigationSheet' : null,
          ),
          child: widget.child,
        );
      },
    );

    if (keyboardDismissBehavior != null) {
      result = SheetKeyboardDismissible(
        dismissBehavior: keyboardDismissBehavior,
        child: result,
      );
    }

    return result;
  }
}

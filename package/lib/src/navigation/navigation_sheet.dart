import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../foundation/keyboard_dismissible.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/sheet_viewport.dart';
import '../internal/transition_observer.dart';
import 'navigation_sheet_extent.dart';
import 'navigation_sheet_viewport.dart';

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
    final gestureTamper = TamperSheetGesture.maybeOf(context);

    Widget result = ImplicitSheetControllerScope(
      controller: widget.controller,
      builder: (context, controller) {
        return SheetExtentScope(
          key: _scopeKey,
          controller: controller,
          factory: this,
          isPrimary: true,
          config: SheetExtentConfig(
            minExtent: const Extent.pixels(0),
            maxExtent: const Extent.proportional(1),
            // TODO: Use more appropriate physics.
            physics: const ClampingSheetPhysics(),
            gestureTamperer: gestureTamper,
            debugLabel: kDebugMode ? 'NavigationSheet' : null,
          ),
          child: Builder(
            builder: (context) {
              return NavigationSheetViewport(
                insets: MediaQuery.viewInsetsOf(context),
                extent: SheetExtentScope.of(context),
                child: SheetContentViewport(child: widget.child),
              );
            },
          ),
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

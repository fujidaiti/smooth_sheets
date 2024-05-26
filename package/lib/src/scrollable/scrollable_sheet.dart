import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/keyboard_dismissible.dart';
import '../foundation/sheet_container.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_theme.dart';
import 'scrollable_sheet_extent.dart';
import 'sheet_scrollable.dart';

class ScrollableSheet extends StatelessWidget {
  const ScrollableSheet({
    super.key,
    this.keyboardDismissBehavior,
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    this.controller,
    required this.child,
  });

  /// The strategy to dismiss the on-screen keyboard when the sheet is dragged.
  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;

  /// {@macro ScrollableSheetExtent.initialExtent}
  final Extent initialExtent;

  /// {@macro SheetExtentConfig.minExtent}
  final Extent minExtent;

  /// {@macro SheetExtentConfig.maxExtent}
  final Extent maxExtent;

  /// {@macro SheetExtentConfig.physics}
  final SheetPhysics? physics;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  /// The content of the sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        this.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;
    final gestureTamper = TamperSheetGesture.maybeOf(context);

    Widget result = ImplicitSheetControllerScope(
      controller: controller,
      builder: (context, controller) {
        return SheetContainer(
          controller: controller,
          factory: const ScrollableSheetExtentFactory(),
          config: ScrollableSheetExtentConfig.withFallbacks(
            initialExtent: initialExtent,
            minExtent: minExtent,
            maxExtent: maxExtent,
            physics: physics ?? theme?.physics,
            gestureTamperer: gestureTamper,
            debugLabel: 'ScrollableSheet',
          ),
          child: ScrollableSheetContent(child: child),
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

@internal
class ScrollableSheetContent extends StatelessWidget {
  const ScrollableSheetContent({
    super.key,
    this.debugLabel,
    this.keepScrollOffset = true,
    this.initialScrollOffset = 0,
    required this.child,
  });

  final String? debugLabel;
  final bool keepScrollOffset;
  final double initialScrollOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetScrollable(
      debugLabel: debugLabel,
      keepScrollOffset: keepScrollOffset,
      initialScrollOffset: initialScrollOffset,
      builder: (context, controller) {
        return PrimaryScrollController(
          controller: controller,
          child: child,
        );
      },
    );
  }
}

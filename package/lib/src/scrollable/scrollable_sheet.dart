import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/sheet_viewport.dart';
import 'scrollable_sheet_extent_scope.dart';
import 'sheet_scrollable.dart';

class ScrollableSheet extends StatefulWidget {
  const ScrollableSheet({
    super.key,
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    this.controller,
    required this.child,
  });

  /// {@macro ScrollableSheetExtent.initialExtent}
  final Extent initialExtent;

  /// {@macro SheetExtent.minExtent}
  final Extent minExtent;

  /// {@macro SheetExtent.maxExtent}
  final Extent maxExtent;

  /// {@macro SheetExtent.physics}
  final SheetPhysics? physics;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  /// The content of the sheet.
  final Widget child;

  @override
  State<ScrollableSheet> createState() => _ScrollableSheetState();
}

class _ScrollableSheetState extends State<ScrollableSheet>
    with TickerProviderStateMixin, SheetContextStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final physics = widget.physics ?? theme?.physics ?? kDefaultSheetPhysics;
    final gestureTamper = TamperSheetGesture.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);

    return ScrollableSheetExtentScope(
      context: this,
      controller: controller,
      initialExtent: widget.initialExtent,
      minExtent: widget.minExtent,
      maxExtent: widget.maxExtent,
      physics: physics,
      gestureTamperer: gestureTamper,
      debugLabel: kDebugMode ? 'ScrollableSheet' : null,
      child: SheetViewport(
        child: SheetContentViewport(
          child: ScrollableSheetContent(child: widget.child),
        ),
      ),
    );
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

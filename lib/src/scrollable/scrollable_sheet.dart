import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_context.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_position.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/sheet_viewport.dart';
import 'scrollable_sheet_position_scope.dart';
import 'sheet_scrollable.dart';

class ScrollableSheet extends StatefulWidget {
  const ScrollableSheet({
    super.key,
    this.initialPosition = const SheetAnchor.proportional(1),
    this.minPosition = const SheetAnchor.proportional(1),
    this.maxPosition = const SheetAnchor.proportional(1),
    this.physics,
    this.controller,
    required this.child,
  });

  /// {@macro ScrollableSheetPosition.initialPosition}
  final SheetAnchor initialPosition;

  /// {@macro SheetPosition.minPosition}
  final SheetAnchor minPosition;

  /// {@macro SheetPosition.maxPosition}
  final SheetAnchor maxPosition;

  /// {@macro SheetPosition.physics}
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
    final gestureTamper = SheetGestureProxy.maybeOf(context);
    final controller =
        widget.controller ?? SheetControllerScope.maybeOf(context);
    final viewport = SheetViewport.of(context);

    return ScrollableSheetPositionScope(
      context: this,
      key: viewport.positionOwnerKey,
      controller: controller,
      initialPosition: widget.initialPosition,
      minPosition: widget.minPosition,
      maxPosition: widget.maxPosition,
      physics: physics,
      gestureTamperer: gestureTamper,
      debugLabel: kDebugMode ? 'ScrollableSheet' : null,
      child: SheetContentViewport(
        child: ScrollableSheetContent(child: widget.child),
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

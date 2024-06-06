import 'package:flutter/widgets.dart';

import '../foundation/keyboard_dismissible.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/sheet_gesture_tamperer.dart';
import '../foundation/sheet_physics.dart';
import '../foundation/sheet_theme.dart';
import '../foundation/sheet_viewport.dart';
import '../scrollable/scrollable_sheet.dart';
import 'draggable_sheet_extent.dart';
import 'sheet_draggable.dart';

/// A sheet that can be dragged.
///
/// Note that this widget does not work with scrollable widgets.
/// Instead, use [ScrollableSheet] for this usecase.
class DraggableSheet extends StatelessWidget {
  /// Creates a sheet that can be dragged.
  ///
  /// The maximum height will be equal to the [child]'s height.
  ///
  /// The [physics] determines how the sheet will behave when over-dragged
  /// or under-dragged, or when the user stops dragging.
  ///
  /// The [hitTestBehavior] defaults to [HitTestBehavior.translucent].
  ///
  /// See also:
  /// - [A tutorial](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/draggable_sheet.dart),
  ///  minimal code to use a draggable sheet.
  const DraggableSheet({
    super.key,
    this.hitTestBehavior = HitTestBehavior.translucent,
    this.keyboardDismissBehavior,
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    required this.child,
    this.controller,
  });

  /// The strategy to dismiss the on-screen keyboard when the sheet is dragged.
  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;

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

  /// How to behave during hit testing.
  ///
  /// This value will be passed to the constructor of internal [SheetDraggable].
  final HitTestBehavior hitTestBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final physics = this.physics ?? theme?.physics ?? kDefaultSheetPhysics;
    final keyboardDismissBehavior =
        this.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;
    final gestureTamper = TamperSheetGesture.maybeOf(context);

    Widget result = SheetExtentScope(
      controller: controller,
      factory: const DraggableSheetExtentFactory(),
      config: DraggableSheetExtentConfig(
        initialExtent: initialExtent,
        minExtent: minExtent,
        maxExtent: maxExtent,
        physics: physics,
        gestureTamperer: gestureTamper,
        debugLabel: 'DraggableSheet',
      ),
      child: SheetViewport(
        child: SheetContentViewport(
          child: SheetDraggable(
            behavior: hitTestBehavior,
            child: child,
          ),
        ),
      ),
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

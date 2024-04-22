import 'package:flutter/widgets.dart';

import '../foundation/activities.dart';
import '../foundation/framework.dart';
import '../foundation/keyboard_dismissible.dart';
import '../foundation/physics.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/theme.dart';
import '../scrollable/scrollable_sheet.dart';
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

  /// {@macro SizedContentSheetExtent.initialExtent}
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

  /// How to behave during hit testing.
  ///
  /// This value will be passed to the constructor of internal [SheetDraggable].
  final HitTestBehavior hitTestBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        this.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;

    Widget result = ImplicitSheetControllerScope(
      controller: controller,
      builder: (context, controller) {
        return SheetContainer(
          controller: controller,
          config: DraggableSheetExtentConfig(
            initialExtent: initialExtent,
            minExtent: minExtent,
            maxExtent: maxExtent,
            physics: physics,
          ),
          child: SheetDraggable(
            behavior: hitTestBehavior,
            child: child,
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

/// A configuration of a [DraggableSheetExtent].
class DraggableSheetExtentConfig extends SheetExtentConfig {
  const DraggableSheetExtentConfig({
    required this.initialExtent,
    required this.minExtent,
    required this.maxExtent,
    required this.physics,
  });

  /// {@macro DraggableSheetExtent.initialExtent}
  final Extent initialExtent;

  /// {@macro SheetExtent.minExtent}
  final Extent minExtent;

  /// {@macro SheetExtent.maxExtent}
  final Extent maxExtent;

  /// {@macro SheetExtent.physics}
  final SheetPhysics? physics;

  @override
  bool shouldRebuild(BuildContext context, SheetExtent oldExtent) {
    return oldExtent is! DraggableSheetExtent ||
        oldExtent.minExtent != minExtent ||
        oldExtent.maxExtent != maxExtent ||
        oldExtent.initialExtent != initialExtent ||
        oldExtent.physics != _resolvePhysics(context);
  }

  @override
  SheetExtent build(BuildContext context, SheetContext sheetContext) {
    return DraggableSheetExtent(
      context: sheetContext,
      initialExtent: initialExtent,
      minExtent: minExtent,
      maxExtent: maxExtent,
      physics: _resolvePhysics(context),
    );
  }

  SheetPhysics _resolvePhysics(BuildContext context) {
    const fallback = StretchingSheetPhysics(parent: SnappingSheetPhysics());
    final theme = SheetTheme.maybeOf(context);
    final base = theme?.basePhysics;
    if (physics case final physics?) {
      return base != null ? physics.applyTo(base) : physics;
    } else if (theme?.physics case final inherited?) {
      // Do not apply the base physics to the inherited physics.
      return inherited;
    } else {
      return base != null ? fallback.applyTo(base) : fallback;
    }
  }
}

/// [SheetExtent] for a [DraggableSheet].
class DraggableSheetExtent extends SheetExtent {
  DraggableSheetExtent({
    required super.context,
    required super.physics,
    required super.minExtent,
    required super.maxExtent,
    required this.initialExtent,
  }) {
    goIdle();
  }

  /// {@template DraggableSheetExtent.initialExtent}
  /// The initial extent of the sheet when it is first shown.
  /// {@endtemplate}
  final Extent initialExtent;

  @override
  void goIdle() {
    beginActivity(_IdleDraggableSheetActivity(
      initialExtent: initialExtent,
    ));
  }
}

class _IdleDraggableSheetActivity extends IdleSheetActivity {
  _IdleDraggableSheetActivity({
    required this.initialExtent,
  });

  final Extent initialExtent;

  @override
  void didChangeContentDimensions(Size? oldDimensions) {
    super.didChangeContentDimensions(oldDimensions);
    if (pixels == null) {
      setPixels(initialExtent.resolve(delegate.contentDimensions!));
    }
  }
}

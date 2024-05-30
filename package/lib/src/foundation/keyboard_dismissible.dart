import 'package:flutter/widgets.dart';
import '../draggable/draggable_sheet.dart';
import 'sheet_notification.dart';

/// A widget that dismisses the on-screen keyboard when the user
/// drags the sheet below this widget.
///
/// It is rarely used directly since the sheets internally have this widget
/// and expose a slot for a [SheetKeyboardDismissBehavior], which is directly
/// passed to this widget.
///
/// See also:
/// - [DraggableSheet.keyboardDismissBehavior], which is the slot for
///   a custom [SheetKeyboardDismissBehavior].
class SheetKeyboardDismissible extends StatelessWidget {
  /// Creates a widget that dismisses the on-screen keyboard when the user
  /// drags the sheet below this widget.
  const SheetKeyboardDismissible({
    super.key,
    required this.dismissBehavior,
    required this.child,
  });

  /// Determines when the on-screen keyboard should be dismissed.
  final SheetKeyboardDismissBehavior dismissBehavior;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result = NotificationListener<SheetDragUpdateNotification>(
      onNotification: (notification) {
        final delta = switch (notification.dragDetails.axisDirection) {
          VerticalDirection.up => notification.dragDetails.deltaY,
          VerticalDirection.down => -1 * notification.dragDetails.deltaY,
        };

        if (primaryFocus?.hasFocus == true &&
            dismissBehavior.shouldDismissKeyboard(delta)) {
          primaryFocus!.unfocus();
        }
        return false;
      },
      child: child,
    );

    if (dismissBehavior.isContentScrollAware) {
      result = NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          final dragDelta = notification.dragDetails?.delta.dy;
          if (notification.depth == 0 &&
              dragDelta != null &&
              primaryFocus?.hasFocus == true &&
              dismissBehavior.shouldDismissKeyboard(-1 * dragDelta)) {
            primaryFocus!.unfocus();
          }
          return false;
        },
        child: result,
      );
    }

    return result;
  }
}

/// Determines when the on-screen keyboard should be dismissed.
abstract class SheetKeyboardDismissBehavior {
  /// Creates an object that determines when the on-screen keyboard
  /// should be dismissed.
  const SheetKeyboardDismissBehavior({
    this.isContentScrollAware = false,
  });

  /// {@macro drag_sheet_keyboard_dismiss_behavior.ctor}
  const factory SheetKeyboardDismissBehavior.onDrag(
      {bool isContentScrollAware}) = DragSheetKeyboardDismissBehavior;

  /// {@macro drag_down_sheet_keyboard_dismiss_behavior.ctor}
  const factory SheetKeyboardDismissBehavior.onDragDown(
      {bool isContentScrollAware}) = DragDownSheetKeyboardDismissBehavior;

  /// {@macro drag_up_sheet_keyboard_dismiss_behavior.ctor}
  const factory SheetKeyboardDismissBehavior.onDragUp(
      {bool isContentScrollAware}) = DragUpSheetKeyboardDismissBehavior;

  /// Whether the sheet should be aware of the content scrolling.
  ///
  /// If this is `true`, [shouldDismissKeyboard] will also be called whenever
  /// the user scrolls a scrollable content within the sheet.
  final bool isContentScrollAware;

  /// Whether the on-screen keyboard should be dismissed.
  ///
  /// This method is called whenever the sheet is dragged by the user.
  /// Returns `true` if the on-screen keyboard should be dismissed.
  bool shouldDismissKeyboard(double userDragDelta);
}

/// A [SheetKeyboardDismissBehavior] that always dismisses the on-screen
/// keyboard when the sheet is dragged.
class DragSheetKeyboardDismissBehavior extends SheetKeyboardDismissBehavior {
  /// {@template drag_sheet_keyboard_dismiss_behavior.ctor}
  /// Creates a [SheetKeyboardDismissBehavior] that always dismisses the
  /// on-screen keyboard when the sheet is dragged.
  ///
  /// If [isContentScrollAware] is `true`, the keyboard will also be dismissed
  /// when the user scrolls a scrollable content within the sheet.
  /// {@endtemplate}
  const DragSheetKeyboardDismissBehavior({super.isContentScrollAware});

  @override
  bool shouldDismissKeyboard(double userDragDelta) {
    return userDragDelta.abs() > 0;
  }
}

/// A [SheetKeyboardDismissBehavior] that dismisses the on-screen keyboard
/// only when the sheet is dragged down.
class DragDownSheetKeyboardDismissBehavior
    extends SheetKeyboardDismissBehavior {
  /// {@template drag_down_sheet_keyboard_dismiss_behavior.ctor}
  /// Creates a [SheetKeyboardDismissBehavior] that dismisses the on-screen
  /// keyboard only when the sheet is dragged down.
  ///
  /// If [isContentScrollAware] is `true`, the keyboard will also be dismissed
  /// when the user scrolls up a scrollable content within the sheet.
  /// {@endtemplate}
  const DragDownSheetKeyboardDismissBehavior({super.isContentScrollAware});

  @override
  bool shouldDismissKeyboard(double userDragDelta) {
    return userDragDelta < 0;
  }
}

/// A [SheetKeyboardDismissBehavior] that dismisses the on-screen keyboard
/// only when the sheet is dragged up.
class DragUpSheetKeyboardDismissBehavior extends SheetKeyboardDismissBehavior {
  /// {@template drag_up_sheet_keyboard_dismiss_behavior.ctor}
  /// Creates a [SheetKeyboardDismissBehavior] that dismisses the on-screen
  /// keyboard only when the sheet is dragged up.
  ///
  /// If [isContentScrollAware] is `true`, the keyboard will also be dismissed
  /// when the user scrolls down a scrollable content within the sheet.
  /// {@endtemplate}
  const DragUpSheetKeyboardDismissBehavior({super.isContentScrollAware});

  @override
  bool shouldDismissKeyboard(double userDragDelta) {
    return userDragDelta > 0;
  }
}

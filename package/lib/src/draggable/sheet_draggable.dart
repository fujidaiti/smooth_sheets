import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/draggable/draggable_sheet.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet.dart';

/// A widget that makes its child as a drag-handle for a sheet.
///
/// Typically, this widget is used when placing non-scrollable widget(s)
/// in a [ScrollableSheet], since it only works with scrollable widgets,
/// so you can't drag the sheet by touching a non-scrollable area.
///
/// Note that [SheetDraggable] is not needed when using [DraggableSheet]
/// since it implicitly wraps the child widget with [SheetDraggable].
///
/// See also:
/// - [A tutorial](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_draggable.dart),
///   in which a [SheetDraggable] is used to create a drag-handle for
///   a [ScrollableSheet].
class SheetDraggable extends StatefulWidget {
  /// Creates a drag-handle for a sheet.
  ///
  /// The [behavior] defaults to [HitTestBehavior.translucent].
  const SheetDraggable({
    super.key,
    this.behavior = HitTestBehavior.translucent,
    required this.child,
  });

  /// How to behave during hit testing.
  final HitTestBehavior behavior;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<SheetDraggable> createState() => _SheetDraggableState();
}

class _SheetDraggableState extends State<SheetDraggable> {
  SheetExtent? _extent;
  UserDragSheetActivity? _activity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extent = SheetExtentScope.maybeOf(context);
  }

  @override
  void dispose() {
    _extent = null;
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_activity == null);
    if (_extent != null) {
      _activity = UserDragSheetActivity();
      _extent!.beginActivity(_activity!);
      _activity!.onDragStart(details);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _activity?.onDragUpdate(details);
  }

  void _handleDragEnd(DragEndDetails details) {
    _activity?.onDragEnd(details);
    _activity = null;
  }

  void _handleDragCancel() {
    _activity?.onDragCancel();
    _activity = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onVerticalDragCancel: _handleDragCancel,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: widget.child,
    );
  }
}

// TODO: Move this class to sheet_activity.dart
// TODO: Add constructor with `DragGestureRecognizer` parameter
class UserDragSheetActivity extends SheetActivity
    with UserControlledSheetActivityMixin {
  void onDragStart(DragStartDetails details) {
    if (!mounted) return;
    dispatchDragStartNotification(details);
  }

  void onDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    final delta = -1 * details.primaryDelta!;
    final physicsAppliedDelta =
        delegate.physics.applyPhysicsToOffset(delta, delegate.metrics);
    if (physicsAppliedDelta != 0) {
      setPixels(pixels! + physicsAppliedDelta);
      dispatchDragUpdateNotification(delta: physicsAppliedDelta);
    }
  }

  void onDragEnd(DragEndDetails details) {
    if (!mounted) return;
    dispatchDragEndNotification(details);
    delegate.goBallistic(-1 * details.velocity.pixelsPerSecond.dy);
  }

  void onDragCancel() {
    if (!mounted) return;
    dispatchDragCancelNotification();
    delegate.goBallistic(0);
  }
}

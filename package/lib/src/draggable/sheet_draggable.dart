import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

class SheetDraggable extends StatefulWidget {
  const SheetDraggable({
    super.key,
    this.behavior = HitTestBehavior.translucent,
    required this.child,
  });

  final HitTestBehavior behavior;
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

class UserDragSheetActivity extends SheetActivity {
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
    // TODO: Support fling gestures
    delegate.goBallistic(0);
  }

  void onDragCancel() {
    if (!mounted) return;
    delegate.goBallistic(0);
  }

  @override
  void didChangeContentDimensions(Size? oldDimensions) {
    // This body is intentionally left blank to disable the default behavior.
  }

  @override
  void didChangeViewportDimensions(ViewportDimensions? oldDimensions) {
    final oldInsets = oldDimensions?.insets;
    final insets = delegate.metrics.viewportDimensions.insets;
    if (pixels != null &&
        oldInsets != null &&
        insets.bottom != oldInsets.bottom) {
      // Append the delta of the bottom inset (typically the keyboard height)
      // to keep the visual position of the sheet unchanged.
      setPixels(pixels! + (oldInsets.bottom - insets.bottom));
    }
  }
}

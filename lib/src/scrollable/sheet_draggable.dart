import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../foundation/sheet_position.dart';
import '../foundation/sheet_position_scope.dart';
import 'scrollable_sheet.dart';

/// A widget that makes its child as a drag-handle for a sheet.
///
/// Typically, this widget is used when placing non-scrollable widget(s)
/// in a [Sheet], since it only works with scrollable widgets,
/// so you can't drag the sheet by touching a non-scrollable area.
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
  SheetPosition? _position;
  Drag? _currentDrag;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position = SheetPositionScope.maybeOf(context);
  }

  @override
  void dispose() {
    _position = null;
    _disposeDrag();
    super.dispose();
  }

  void _disposeDrag() {
    _currentDrag = null;
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_currentDrag == null);
    _currentDrag = _position?.drag(details, _disposeDrag);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _currentDrag?.update(details);
  }

  void _handleDragEnd(DragEndDetails details) {
    _currentDrag?.end(details);
    _disposeDrag();
  }

  void _handleDragCancel() {
    _currentDrag?.cancel();
    _disposeDrag();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(
            debugOwner: kDebugMode ? runtimeType : null,
            supportedDevices: const {PointerDeviceKind.touch},
          ),
          (instance) => instance
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd
            ..onCancel = _handleDragCancel,
        ),
      },
      child: widget.child,
    );
  }
}
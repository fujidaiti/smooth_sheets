import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../foundation/activities.dart';
import '../foundation/sheet_extent.dart';
import '../scrollable/scrollable_sheet.dart';
import 'draggable_sheet.dart';

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
  VerticalDragGestureRecognizer? _dragRecognizer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extent = SheetExtentScope.maybeOf(context);
  }

  @override
  void dispose() {
    _extent = null;
    _dragRecognizer = null;
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    final extent = _extent;
    final recognizer = _dragRecognizer;
    if (extent != null && recognizer != null) {
      extent.activity.dispatchDragStartNotification(details);
      extent.beginActivity(
        UserDragSheetActivity(
          gestureRecognizer: recognizer,
        ),
      );
    }
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
          (instance) {
            _dragRecognizer = instance..onStart = _handleDragStart;
          },
        ),
      },
      child: widget.child,
    );
  }
}

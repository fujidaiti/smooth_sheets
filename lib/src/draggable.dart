import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
// TODO: Remove this import after the minimum sdk version is bumped to 3.35.0
//
// @internal annotation has been included in flutter/foundation.dart since 3.35.0.
// See: https://github.com/flutter/flutter/commit/5706259791de29a27cb68e9b95d6319ba863e366
// ignore: unnecessary_import
import 'package:meta/meta.dart';

import 'model.dart';
import 'model_owner.dart';
import 'sheet.dart';

/// A widget that makes its child as a drag-handle for a sheet.
///
/// Typically, this widget is used when placing non-scrollable widget(s)
/// in a [Sheet], since it only works with scrollable widgets,
/// so you can't drag the sheet by touching a non-scrollable area.
@internal
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
  SheetModel? _model;
  Drag? _currentDrag;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _model = SheetModelOwner.of(context);
  }

  @override
  void dispose() {
    _model = null;
    _disposeDrag();
    super.dispose();
  }

  void _disposeDrag() {
    _currentDrag = null;
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_currentDrag == null);
    _currentDrag = _model?.drag(details, _disposeDrag);
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
      // At least one hit-testable widget is required
      // to receive drag events.
      child: ColoredBox(
        color: const Color(0x00000000),
        child: widget.child,
      ),
    );
  }
}

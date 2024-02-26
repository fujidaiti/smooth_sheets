import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sized_content_sheet.dart';

/// A sheet that can be dragged.
///
/// Note that this widget does not work with scrollable widgets.
/// Instead, use [ScrollableSheet] for this usecase.
class DraggableSheet extends SizedContentSheet {
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
    super.keyboardDismissBehavior,
    super.initialExtent,
    super.minExtent,
    super.maxExtent,
    super.physics,
    super.controller,
    required super.child,
  });

  /// How to behave during hit testing.
  ///
  /// This value will be passed to the constructor of internal [SheetDraggable].
  final HitTestBehavior hitTestBehavior;

  @override
  SizedContentSheetState<SizedContentSheet> createState() {
    return _DraggableSheetState();
  }
}

class _DraggableSheetState extends SizedContentSheetState<DraggableSheet> {
  @override
  SheetExtentFactory createExtentFactory() {
    return DraggableSheetExtentFactory(
      initialExtent: widget.initialExtent,
      minExtent: widget.minExtent,
      maxExtent: widget.maxExtent,
      physics: widget.physics,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return SheetDraggable(
      behavior: widget.hitTestBehavior,
      child: super.buildContent(context),
    );
  }
}

/// Factory of [DraggableSheetExtent].
class DraggableSheetExtentFactory extends SizedContentSheetExtentFactory {
  const DraggableSheetExtentFactory({
    required super.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required super.physics,
  });

  @override
  SheetExtent create({required SheetContext context}) {
    return DraggableSheetExtent(
      initialExtent: initialExtent,
      minExtent: minExtent,
      maxExtent: maxExtent,
      physics: physics,
      context: context,
    );
  }
}

/// [SheetExtent] for a [DraggableSheet].
class DraggableSheetExtent extends SizedContentSheetExtent {
  DraggableSheetExtent({
    required super.context,
    required super.physics,
    required super.minExtent,
    required super.maxExtent,
    required super.initialExtent,
  }) {
    goIdle();
  }

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

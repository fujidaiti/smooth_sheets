import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/single_child_sheet.dart';

class DraggableSheet extends SingleChildSheet {
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

  final HitTestBehavior hitTestBehavior;

  @override
  SingleChildSheetState<SingleChildSheet> createState() {
    return _DraggableSheetState();
  }
}

class _DraggableSheetState extends SingleChildSheetState<DraggableSheet> {
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

class DraggableSheetExtentFactory extends SingleChildSheetExtentFactory {
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

class DraggableSheetExtent extends SingleChildSheetExtent {
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

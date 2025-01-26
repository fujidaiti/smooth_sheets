import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../foundation/model_scope.dart';
import 'scrollable_sheet_position.dart';
import 'sheet_content_scroll_position.dart';

class SheetScrollable extends StatefulWidget {
  const SheetScrollable({
    super.key,
    this.debugLabel,
    this.keepScrollOffset = true,
    this.initialScrollOffset = 0,
    required this.builder,
  });

  final String? debugLabel;
  final bool keepScrollOffset;
  final double initialScrollOffset;
  final ScrollableWidgetBuilder builder;

  @override
  State<SheetScrollable> createState() => _SheetScrollableState();
}

class _SheetScrollableState extends State<SheetScrollable> {
  late ScrollController _scrollController;
  DraggableScrollableSheetPosition? _position;

  @override
  void initState() {
    super.initState();
    _scrollController = createController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position = SheetPositionScope.maybeOf(context);
  }

  @override
  void didUpdateWidget(SheetScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.debugLabel != oldWidget.debugLabel ||
        widget.keepScrollOffset != oldWidget.keepScrollOffset ||
        widget.initialScrollOffset != oldWidget.initialScrollOffset) {
      _scrollController.dispose();
      _scrollController = createController();
    }
  }

  @factory
  SheetContentScrollController createController() {
    return SheetContentScrollController(
      getOwner: () => _position,
      debugLabel: widget.debugLabel,
      initialScrollOffset: widget.initialScrollOffset,
      keepScrollOffset: widget.keepScrollOffset,
    );
  }

  @override
  void dispose() {
    _position = null;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _scrollController);
}

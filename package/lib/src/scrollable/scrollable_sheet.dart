import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sized_content_sheet.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet_extent.dart';

class ScrollableSheet extends SizedContentSheet {
  const ScrollableSheet({
    super.key,
    super.keyboardDismissBehavior,
    super.initialExtent,
    super.minExtent,
    super.maxExtent,
    super.physics,
    super.controller,
    required super.child,
  });

  @override
  SizedContentSheetState<SizedContentSheet> createState() {
    return _ScrollableSheetState();
  }
}

class _ScrollableSheetState extends SizedContentSheetState<ScrollableSheet> {
  @override
  SheetExtentFactory createExtentFactory() {
    return ScrollableSheetExtentFactory(
      initialExtent: widget.initialExtent,
      minExtent: widget.minExtent,
      maxExtent: widget.maxExtent,
      physics: widget.physics,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return PrimarySheetContentScrollController(
      child: super.buildContent(context),
    );
  }
}

@internal
class PrimarySheetContentScrollController extends StatelessWidget {
  const PrimarySheetContentScrollController({
    super.key,
    this.debugLabel,
    this.keepScrollOffset = true,
    this.initialScrollOffset = 0,
    required this.child,
  });

  final String? debugLabel;
  final bool keepScrollOffset;
  final double initialScrollOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetScrollable(
      debugLabel: debugLabel,
      keepScrollOffset: keepScrollOffset,
      initialScrollOffset: initialScrollOffset,
      builder: (context, controller) {
        return PrimaryScrollController(
          controller: controller,
          child: child,
        );
      },
    );
  }
}

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extent = SheetExtentScope.maybeOf(context);
    _scrollController = switch (extent) {
      final ScrollableSheetExtent extent => SheetContentScrollController(
          extent: extent,
          debugLabel: widget.debugLabel,
          initialScrollOffset: widget.initialScrollOffset,
          keepScrollOffset: widget.keepScrollOffset,
        ),
      // If this widget is not a descendant of a SheetExtentScope,
      // then create a normal ScrollController for stubbing.
      _ => ScrollController(
          debugLabel: widget.debugLabel,
          initialScrollOffset: widget.initialScrollOffset,
          keepScrollOffset: widget.keepScrollOffset,
        ),
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _scrollController);
}

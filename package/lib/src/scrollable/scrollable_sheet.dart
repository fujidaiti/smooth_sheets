import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/single_child_sheet.dart';
import 'package:smooth_sheets/src/internal/into.dart';
import 'package:smooth_sheets/src/scrollable/content_scroll_position.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet_extent.dart';

class ScrollableSheet extends SingleChildSheet {
  const ScrollableSheet({
    super.key,
    super.initialExtent,
    super.minExtent,
    super.maxExtent,
    super.physics,
    super.controller,
    required super.child,
  });

  @override
  SingleChildSheetState<SingleChildSheet> createState() {
    return _ScrollableSheetState();
  }
}

class _ScrollableSheetState extends SingleChildSheetState<ScrollableSheet> {
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
    return SheetContentScrollControllerScope(
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

class SheetContentScrollControllerScope extends StatefulWidget {
  const SheetContentScrollControllerScope({
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
  State<SheetContentScrollControllerScope> createState() =>
      _SheetContentScrollControllerScopeState();
}

class _SheetContentScrollControllerScopeState
    extends State<SheetContentScrollControllerScope> {
  late final SheetContentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = SheetContentScrollController(
      debugLabel: widget.debugLabel,
      initialScrollOffset: widget.initialScrollOffset,
      keepScrollOffset: widget.keepScrollOffset,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController.extent = SheetExtentScope.maybeOf(context)?.intoOrNull();
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

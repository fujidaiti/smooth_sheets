import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet_extent.dart';

class ScrollableSheet extends StatelessWidget {
  const ScrollableSheet({
    super.key,
    this.keyboardDismissBehavior,
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics = const StretchingSheetPhysics(
      parent: SnappingSheetPhysics(),
    ),
    this.controller,
    required this.child,
  });

  /// The strategy to dismiss the on-screen keyboard when the sheet is dragged.
  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;

  /// {@macro ScrollableSheetExtent.initialExtent}
  final Extent initialExtent;

  /// {@macro SheetExtent.minExtent}
  final Extent minExtent;

  /// {@macro SheetExtent.maxExtent}
  final Extent maxExtent;

  /// {@macro SheetExtent.physics}
  final SheetPhysics physics;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  /// The content of the sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        this.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;

    Widget result = SheetContainer(
      controller: controller,
      factory: ScrollableSheetExtentFactory(
        initialExtent: initialExtent,
        minExtent: minExtent,
        maxExtent: maxExtent,
        physics: physics,
      ),
      child: PrimarySheetContentScrollController(child: child),
    );

    if (keyboardDismissBehavior != null) {
      result = SheetKeyboardDismissible(
        dismissBehavior: keyboardDismissBehavior,
        child: result,
      );
    }

    return result;
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

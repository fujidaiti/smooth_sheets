import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../foundation/framework.dart';
import '../foundation/keyboard_dismissible.dart';
import '../foundation/physics.dart';
import '../foundation/sheet_controller.dart';
import '../foundation/sheet_extent.dart';
import '../foundation/theme.dart';
import 'scrollable_sheet_extent.dart';
import 'scrollable_sheet_physics.dart';

class ScrollableSheet extends StatelessWidget {
  const ScrollableSheet({
    super.key,
    this.keyboardDismissBehavior,
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics,
    this.controller,
    required this.child,
  });

  /// The strategy to dismiss the on-screen keyboard when the sheet is dragged.
  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;

  /// {@macro ScrollableSheetExtent.initialExtent}
  final Extent initialExtent;

  /// {@macro SheetExtentConfig.minExtent}
  final Extent minExtent;

  /// {@macro SheetExtentConfig.maxExtent}
  final Extent maxExtent;

  /// {@macro SheetExtentConfig.physics}
  final SheetPhysics? physics;

  /// An object that can be used to control and observe the sheet height.
  final SheetController? controller;

  /// The content of the sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SheetTheme.maybeOf(context);
    final keyboardDismissBehavior =
        this.keyboardDismissBehavior ?? theme?.keyboardDismissBehavior;
    // TODO: Do this in ScrollableSheetConfig
    final physics = switch (this.physics ?? theme?.physics) {
      null => const ScrollableSheetPhysics(parent: kDefaultSheetPhysics),
      final ScrollableSheetPhysics scrollablePhysics => scrollablePhysics,
      final otherPhysics => ScrollableSheetPhysics(parent: otherPhysics),
    };

    Widget result = ImplicitSheetControllerScope(
      controller: controller,
      builder: (context, controller) {
        return SheetContainer(
          controller: controller,
          factory: const ScrollableSheetExtentFactory(),
          config: ScrollableSheetExtentConfig(
            initialExtent: initialExtent,
            minExtent: minExtent,
            maxExtent: maxExtent,
            physics: physics,
            debugLabel: 'ScrollableSheet',
          ),
          child: PrimarySheetContentScrollController(child: child),
        );
      },
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

// TODO: Move this to a separate file.
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
      // If this widget is not a descendant of a SheetExtentScope,
      // then create a normal ScrollController for stubbing.
      null => ScrollController(
          debugLabel: widget.debugLabel,
          initialScrollOffset: widget.initialScrollOffset,
          keepScrollOffset: widget.keepScrollOffset,
        ),
      final extent => SheetContentScrollController(
          extent: extent,
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

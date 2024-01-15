import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/foundation/framework.dart';
import 'package:smooth_sheets/src/foundation/keyboard_dismissible.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';

abstract class SingleChildSheetExtent extends SheetExtent {
  SingleChildSheetExtent({
    required super.context,
    required super.physics,
    required super.minExtent,
    required super.maxExtent,
    required this.initialExtent,
  });

  final Extent initialExtent;
}

abstract class SingleChildSheetExtentFactory extends SheetExtentFactory {
  const SingleChildSheetExtentFactory({
    required this.initialExtent,
    required this.minExtent,
    required this.maxExtent,
    required this.physics,
  });

  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics physics;
}

/// A base class for sheets that have a single content.
abstract class SingleChildSheet extends StatefulWidget {
  const SingleChildSheet({
    super.key,
    this.keyboardDismissBehavior,
    this.resizeToAvoidBottomInset = true,
    this.initialExtent = const Extent.proportional(1),
    this.minExtent = const Extent.proportional(1),
    this.maxExtent = const Extent.proportional(1),
    this.physics = const StretchingSheetPhysics(
      parent: SnappingSheetPhysics(),
    ),
    this.controller,
    required this.child,
  });

  final SheetKeyboardDismissBehavior? keyboardDismissBehavior;
  final bool resizeToAvoidBottomInset;
  final Extent initialExtent;
  final Extent minExtent;
  final Extent maxExtent;
  final SheetPhysics physics;
  final SheetController? controller;
  final Widget child;

  @override
  SingleChildSheetState createState();
}

abstract class SingleChildSheetState<T extends SingleChildSheet>
    extends State<T> {
  late SheetExtentFactory _factory;
  SheetExtentFactory get factory => _factory;

  SheetExtentFactory createExtentFactory();

  @override
  void initState() {
    super.initState();
    _factory = createExtentFactory();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialExtent != oldWidget.initialExtent ||
        widget.minExtent != oldWidget.minExtent ||
        widget.maxExtent != oldWidget.maxExtent ||
        widget.physics != oldWidget.physics) {
      _factory = createExtentFactory();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = SheetContainer(
      factory: factory,
      controller: widget.controller,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      child: buildContent(context),
    );
    
    if (widget.keyboardDismissBehavior != null) {
      result = SheetKeyboardDismissible(
        dismissBehavior: widget.keyboardDismissBehavior!,
        child: result,
      );
    }
    
    return result;
  }

  /// Builds the content of the sheet.
  ///
  /// Consider overriding this method if you want to
  /// insert widgets above the [SingleChildSheet.child].
  @protected
  Widget buildContent(BuildContext context) {
    return widget.child;
  }
}

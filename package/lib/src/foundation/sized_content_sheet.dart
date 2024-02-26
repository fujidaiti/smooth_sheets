import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/foundation/framework.dart';
import 'package:smooth_sheets/src/foundation/keyboard_dismissible.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';
import 'package:smooth_sheets/src/foundation/sheet_physics.dart';

/// [SheetExtent] for a [SizedContentSheet].
abstract class SizedContentSheetExtent extends SheetExtent {
  /// Creates a [SheetExtent] for [SizedContentSheet]s.
  SizedContentSheetExtent({
    required super.context,
    required super.physics,
    required super.minExtent,
    required super.maxExtent,
    required this.initialExtent,
  });

  /// {@template SizedContentSheetExtent.initialExtent}
  /// The initial extent of the sheet when it is first shown.
  /// {@endtemplate}
  final Extent initialExtent;
}

/// Factory of [SizedContentSheetExtent].
abstract class SizedContentSheetExtentFactory extends SheetExtentFactory {
  /// Creates a factory of [SizedContentSheetExtent].
  const SizedContentSheetExtentFactory({
    required this.initialExtent,
    required this.minExtent,
    required this.maxExtent,
    required this.physics,
  });

  /// {@macro SizedContentSheetExtent.initialExtent}
  final Extent initialExtent;

  /// {@macro SheetExtent.minExtent}
  final Extent minExtent;

  /// {@macro SheetExtent.maxExtent}
  final Extent maxExtent;

  /// {@macro SheetExtent.physics}
  final SheetPhysics physics;
}

/// A base class for sheets that have an explicit initial extent.
abstract class SizedContentSheet extends StatefulWidget {
  /// Creates a sheet with an explicit initial extent.
  const SizedContentSheet({
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

  /// {@macro SizedContentSheetExtent.initialExtent}
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
  SizedContentSheetState createState();
}

/// State for a [SizedContentSheet].
abstract class SizedContentSheetState<T extends SizedContentSheet>
    extends State<T> {
  /// The factory of [SheetExtent] which drives this sheet.
  ///
  /// This is first created in [initState] and updated in [didUpdateWidget]
  /// when the [SizedContentSheet] properties change.
  SheetExtentFactory get factory => _factory;
  late SheetExtentFactory _factory;

  /// Creates the factory of [SheetExtent] for this sheet.
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
  /// insert widgets above the [SizedContentSheet.child].
  @protected
  Widget buildContent(BuildContext context) {
    return widget.child;
  }
}

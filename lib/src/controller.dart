/// @docImport 'paged_sheet.dart';
/// @docImport 'sheet.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'model.dart';

/// Controls and observes a [Sheet].
///
/// A [SheetController] can be passed to [Sheet.controller] (or
/// [PagedSheet.controller]) to programmatically animate the sheet and to read
/// the current [metrics].
///
/// The [value] property exposes the sheet's current offset in pixels, and
/// changes to it are broadcast to all registered listeners.
///
/// See also:
/// - [DefaultSheetController], which creates and exposes a [SheetController]
///   to its descendants.
class SheetController extends ChangeNotifier
    implements ValueListenable<double?> {
  SheetModel? _client;

  /// A notifier which notifies listeners immediately when the [_client] fires.
  ///
  /// This is necessary to keep separate the listeners that should be
  /// notified immediately when the [_client] fires, and the ones that should
  /// not be notified during the middle of a frame.
  final _immediateListeners = ChangeNotifier();

  @override
  double? get value => _client?.offset;

  /// The current metrics of the sheet.
  SheetMetrics? get metrics => switch (_client) {
    final it? when it.hasMetrics => it.copyWith(),
    _ => null,
  };

  /// Whether a [SheetModel] is attached to this controller.
  bool get hasClient => _client != null;

  @override
  void addListener(VoidCallback listener, {bool fireImmediately = false}) {
    if (fireImmediately) {
      _immediateListeners.addListener(listener);
    } else {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _immediateListeners.removeListener(listener);
    super.removeListener(listener);
  }

  void attach(SheetModel position) {
    if (_client case final oldPosition?) {
      detach(oldPosition);
    }

    _client = position..addListener(notifyListeners);
  }

  void detach(SheetModel? position) {
    if (position == _client) {
      position?.removeListener(notifyListeners);
      _client = null;
    }
  }

  @override
  void dispose() {
    detach(_client);
    _immediateListeners.dispose();
    super.dispose();
  }

  /// Animates the sheet to the given [to] offset.
  ///
  /// The animation runs for the given [duration] along the [curve].
  /// Returns a [Future] that completes when the animation finishes.
  Future<void> animateTo(
    SheetOffset to, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    assert(_client != null);
    return _client!.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void notifyListeners() {
    _immediateListeners.notifyListeners();

    // Avoid notifying listeners during the middle of a frame.
    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.postFrameCallbacks:
        super.notifyListeners();

      case SchedulerPhase.persistentCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          super.notifyListeners();
        });
    }
  }
}

/// A widget that creates a [SheetController] and makes it available to
/// all descendants via [DefaultSheetController.of].
///
/// The controller is automatically disposed when this widget is removed from
/// the tree.
///
/// ```dart
/// DefaultSheetController(
///   child: Sheet(
///     child: MySheetContent(),
///   ),
/// )
/// ```
///
/// See also:
/// - [DefaultSheetController.of], which retrieves the nearest controller.
class DefaultSheetController extends StatefulWidget {
  const DefaultSheetController({super.key, required this.child});

  /// The widget below this widget in the tree.
  ///
  /// A [SheetController] is made available to all descendants.
  final Widget child;

  @override
  State<DefaultSheetController> createState() => _DefaultSheetControllerState();

  /// Returns the nearest [SheetController] in the widget tree, or `null` if
  /// no [DefaultSheetController] ancestor exists.
  static SheetController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SheetControllerScope>()
        ?.controller;
  }

  /// Returns the nearest [SheetController] in the widget tree.
  ///
  /// Throws a [FlutterError] if no [DefaultSheetController] ancestor exists.
  static SheetController of(BuildContext context) {
    final controller = maybeOf(context);

    assert(
      (() {
        if (controller == null) {
          throw FlutterError(
            'No SheetControllerScope ancestor could be found starting '
            'from the context that was passed to DefaultSheetController.of(). '
            'The context used was:\n'
            '$context',
          );
        }
        return true;
      })(),
    );

    return controller!;
  }
}

class _DefaultSheetControllerState extends State<DefaultSheetController> {
  late final SheetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SheetController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetControllerScope(controller: _controller, child: widget.child);
  }
}

@internal
class SheetControllerScope extends InheritedWidget {
  const SheetControllerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final SheetController controller;

  @override
  bool updateShouldNotify(SheetControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

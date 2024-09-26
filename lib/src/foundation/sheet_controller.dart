import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'foundation.dart';
import 'sheet_position.dart';

class SheetController extends ChangeNotifier
    implements ValueListenable<double?> {
  SheetPosition? _client;

  /// A notifier which notifies listeners immediately when the [_client] fires.
  ///
  /// This is necessary to keep separate the listeners that should be
  /// notified immediately when the [_client] fires, and the ones that should
  /// not be notified during the middle of a frame.
  final _immediateListeners = ChangeNotifier();

  /// The current sheet position.
  ///
  /// Returns [SheetPosition.value] of the attached [SheetPosition],
  /// or `null` if no [SheetPosition] is attached.
  @override
  double? get value => _client?.value;

  SheetStatus? get status => _client?.status;

  /// The current metrics of the sheet.
  ///
  /// Returns [SheetPosition.snapshot] of the attached [SheetPosition],
  /// or [SheetMetrics.empty] if no [SheetPosition] is attached.
  SheetMetrics get metrics => _client?.snapshot ?? SheetMetrics.empty;

  /// Whether a [SheetPosition] is attached to this controller.
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

  void attach(SheetPosition extent) {
    if (_client case final oldExtent?) {
      detach(oldExtent);
    }

    _client = extent..addListener(notifyListeners);
  }

  void detach(SheetPosition? extent) {
    if (extent == _client) {
      extent?.removeListener(notifyListeners);
      _client = null;
    }
  }

  @override
  void dispose() {
    detach(_client);
    _immediateListeners.dispose();
    super.dispose();
  }

  Future<void> animateTo(
    SheetAnchor to, {
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

@internal
class SheetControllerScope extends InheritedWidget {
  const SheetControllerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final SheetController controller;

  static SheetController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SheetControllerScope>()
        ?.controller;
  }

  static SheetController of(BuildContext context) {
    final controller = maybeOf(context);

    assert((() {
      if (controller == null) {
        throw FlutterError(
          'No $SheetControllerScope ancestor could be found starting '
          'from the context that was passed to $SheetControllerScope.of(). '
          'The context used was:\n'
          '$context',
        );
      }
      return true;
    })());

    return controller!;
  }

  @override
  bool updateShouldNotify(SheetControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class DefaultSheetController extends StatefulWidget {
  const DefaultSheetController({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DefaultSheetController> createState() => _DefaultSheetControllerState();

  static SheetController of(BuildContext context) {
    return SheetControllerScope.of(context);
  }

  static SheetController? maybeOf(BuildContext context) {
    return SheetControllerScope.maybeOf(context);
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
    return SheetControllerScope(
      controller: _controller,
      child: widget.child,
    );
  }
}

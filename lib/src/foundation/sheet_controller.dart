import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_model.dart';

class SheetController extends ChangeNotifier
    implements ValueListenable<SheetGeometry?> {
  SheetModel? _client;

  /// A notifier which notifies listeners immediately when the [_client] fires.
  ///
  /// This is necessary to keep separate the listeners that should be
  /// notified immediately when the [_client] fires, and the ones that should
  /// not be notified during the middle of a frame.
  final _immediateListeners = ChangeNotifier();

  /// The current sheet position.
  ///
  /// Returns [SheetModel.value] of the attached [SheetModel],
  /// or `null` if no [SheetModel] is attached.
  @override
  SheetGeometry? get value => _client?.value;

  /// The current metrics of the sheet.
  ///
  /// Returns the result of [SheetModel.snapshot]
  /// on the attached [SheetModel].
  SheetMetrics? get metrics => switch (_client) {
        final it? when it.hasMetrics => it.snapshot,
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

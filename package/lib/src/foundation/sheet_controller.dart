import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

class SheetController extends ChangeNotifier
    implements ValueListenable<double?> {
  SheetExtent? _client;

  @override
  double? get value => _client?.pixels;

  SheetMetrics? get metrics {
    return _client?.hasPixels == true ? _client!.metrics : null;
  }

  void attach(SheetExtent extent) {
    if (_client case final oldExtent?) {
      detach(oldExtent);
    }

    _client = extent..addListener(notifyListeners);
  }

  void detach(SheetExtent? extent) {
    if (extent == _client) {
      extent?.removeListener(notifyListeners);
      _client = null;
    }
  }

  @override
  void dispose() {
    detach(_client);
    super.dispose();
  }

  Future<void> animateTo(
    Extent to, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    assert(_client != null);
    return _client!.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void notifyListeners() {
    // Avoid notifying listeners during the middle of a frame.
    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.postFrameCallbacks:
        super.notifyListeners();

      case SchedulerPhase.persistentCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
        break;
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
    return maybeOf(context)!;
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

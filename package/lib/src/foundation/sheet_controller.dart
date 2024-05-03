import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'sheet_extent.dart';
import 'sheet_status.dart';

class SheetController extends ChangeNotifier
    implements ValueListenable<SheetMetrics> {
  SheetExtent? _client;

  /// A notifier which notifies listeners immediately when the [_client] fires.
  ///
  /// This is necessary to keep separate the listeners that should be
  /// notified immediately when the [_client] fires, and the ones that should
  /// not be notified during the middle of a frame.
  final _immediateListeners = ChangeNotifier();

  @override
  SheetMetrics get value => _client?.metrics ?? SheetMetrics.empty;

  SheetStatus? get status => _client?.status;

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

  SheetExtent createSheetExtent({
    required SheetContext context,
    required SheetExtentConfig config,
    required SheetExtentDelegate delegate,
  }) {
    return SheetExtent(
      context: context,
      config: config,
      delegate: delegate,
    );
  }

  @override
  void dispose() {
    detach(_client);
    _immediateListeners.dispose();
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
    return maybeOf(context)!;
  }

  @override
  bool updateShouldNotify(SheetControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// A widget that ensures that a [SheetController] is available in the subtree.
///
/// The [builder] callback will be called with the [controller] if it is
/// explicitly provided and is not null, or a [SheetController] that is hosted
/// in the nearest ancestor [SheetControllerScope]. If neither is found, a newly
/// created [SheetController] hosted in a [DefaultSheetController] will be
/// used as a fallback.
@internal
class ImplicitSheetControllerScope extends StatelessWidget {
  const ImplicitSheetControllerScope({
    super.key,
    this.controller,
    required this.builder,
  });

  final SheetController? controller;
  final Widget Function(BuildContext, SheetController) builder;

  @override
  Widget build(BuildContext context) {
    return switch (controller ?? DefaultSheetController.maybeOf(context)) {
      final controller? => builder(context, controller),
      null => DefaultSheetController(
          child: Builder(
            builder: (context) {
              final controller = DefaultSheetController.of(context);
              return builder(context, controller);
            },
          ),
        ),
    };
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

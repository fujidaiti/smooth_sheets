import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'model.dart';
import 'motion.dart';

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

  /// Animates the sheet to the given offset.
  ///
  /// The returned future completes when the animation ends, whether it
  /// reached [to] or was interrupted by another activity such as a drag.
  ///
  /// [motion] describes how the sheet travels there. It defaults to
  /// [kDefaultSheetAnimationMotion]; pass a [SpringSheetMotion] to move the
  /// sheet with a spring simulation instead of a curve:
  ///
  /// ```dart
  /// controller.animateTo(
  ///   const SheetOffset(0.5),
  ///   motion: SpringSheetMotion.snappy(),
  /// );
  /// ```
  ///
  /// [velocity] is the speed the sheet is already moving at, in pixels per
  /// second, with positive values meaning the offset is increasing. Only a
  /// [SpringSheetMotion] can carry it over into the animation.
  Future<void> animateTo(
    SheetOffset to, {
    @Deprecated(
      'Use motion instead. Note that CurvedSheetMotion defaults to '
      'Curves.fastEaseInToSlowEaseOut; pass kDefaultSheetAnimationMotion '
      'to keep the easing animateTo has always used. '
      'This feature was deprecated after v1.1.0.',
    )
    Duration? duration,
    @Deprecated(
      'Use motion instead. Note that CurvedSheetMotion defaults to '
      'Curves.fastEaseInToSlowEaseOut; pass kDefaultSheetAnimationMotion '
      'to keep the easing animateTo has always used. '
      'This feature was deprecated after v1.1.0.',
    )
    Curve? curve,
    SheetMotion? motion,
    double velocity = 0,
  }) {
    assert(_client != null);
    return _client!.animateTo(
      to,
      duration: duration,
      curve: curve,
      motion: motion,
      velocity: velocity,
    );
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

class DefaultSheetController extends StatefulWidget {
  const DefaultSheetController({super.key, required this.child});

  final Widget child;

  @override
  State<DefaultSheetController> createState() => _DefaultSheetControllerState();

  static SheetController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SheetControllerScope>()
        ?.controller;
  }

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

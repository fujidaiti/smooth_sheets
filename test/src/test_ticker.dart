import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';

import 'stubbing.dart';

class TestTicker implements Ticker {
  TestTicker(this._onTick, {this.debugLabel});

  final TickerCallback _onTick;

  @override
  final String? debugLabel;

  Duration _elapsed = Duration.zero;
  MockTickerFuture? _currentFuture;

  @override
  bool get isActive => _currentFuture != null;

  @override
  bool get isTicking => isActive && !muted;

  // ignore: lines_longer_than_80_chars
  // TODO: Remove the following ignore-rule once the minimum SDK is bumped to 3.29
  @override
  // ignore: omit_obvious_property_types
  bool muted = false;

  /// Manually advances the ticker by the specified duration.
  void tick(Duration duration) {
    if (isActive && !muted) {
      _elapsed += duration;
      _onTick(_elapsed);
    }
  }

  /// Calls [tick] repeatedly with given [duration] until the ticker is
  /// no longer active.
  void tickAndSettle({Duration duration = const Duration(milliseconds: 100)}) {
    while (isActive) {
      tick(duration);
    }
  }

  @override
  TickerFuture start() {
    if (isActive) {
      throw StateError('MockTicker cannot be started while already active.');
    }
    _elapsed = Duration.zero;
    return _currentFuture = MockTickerFuture();
  }

  @override
  void stop({bool canceled = false}) {
    if (!isActive) return;
    _currentFuture = null;
  }

  @override
  void dispose() {
    stop(canceled: true);
  }

  @override
  String toString({bool debugIncludeStack = false}) {
    return 'MockTicker(${debugLabel ?? ''})';
  }

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}

class _SingleVsync implements TickerProvider {
  _SingleVsync();

  TestTicker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(_ticker == null);
    return _ticker = TestTicker(onTick);
  }

  void dispose() {
    _ticker?.dispose();
  }
}

class TestAnimationController extends AnimationController {
  factory TestAnimationController({
    String? debugLabel,
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    double lowerBound = 0,
    double upperBound = 1,
  }) {
    final vsync = _SingleVsync();
    return TestAnimationController._(
      debugLabel: debugLabel,
      value: value,
      duration: duration,
      reverseDuration: reverseDuration,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: vsync,
    );
  }

  TestAnimationController._({
    required super.debugLabel,
    required super.value,
    required super.duration,
    required super.reverseDuration,
    required super.lowerBound,
    required super.upperBound,
    required _SingleVsync vsync,
  })  : _vsync = vsync,
        super(vsync: vsync);

  final _SingleVsync _vsync;

  void tick(Duration duration) => _vsync._ticker?.tick(duration);

  void tickAndSettle({Duration duration = const Duration(milliseconds: 100)}) =>
      _vsync._ticker?.tickAndSettle(duration: duration);

  @override
  void dispose() {
    _vsync.dispose();
    super.dispose();
  }
}

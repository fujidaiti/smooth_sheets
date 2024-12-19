import 'package:flutter_test/flutter_test.dart';

import 'test_ticker.dart';

void main() {
  test('Should call onTick callback when tick is manually advanced', () {
    final ticks = <Duration>[];
    final mockTicker = TestTicker(ticks.add);

    mockTicker.start();
    mockTicker.tick(const Duration(milliseconds: 500));
    mockTicker.tick(const Duration(milliseconds: 500));

    expect(ticks, const [
      Duration(milliseconds: 500),
      Duration(milliseconds: 1000),
    ]);
  });

  test('Should reset elapsed time when start is called', () {
    final ticks = <Duration>[];
    final mockTicker = TestTicker(ticks.add);

    mockTicker.start();
    mockTicker.tick(const Duration(milliseconds: 500));
    mockTicker.stop();
    mockTicker.start(); // Reset
    mockTicker.tick(const Duration(milliseconds: 300));

    expect(ticks, const [
      Duration(milliseconds: 500),
      Duration(milliseconds: 300),
    ]);
  });

  test('Should not call onTick when ticker is stopped', () {
    final ticks = <Duration>[];
    final mockTicker = TestTicker(ticks.add);

    mockTicker.start();
    mockTicker.tick(const Duration(milliseconds: 500));
    mockTicker.stop();
    mockTicker.tick(const Duration(milliseconds: 500));

    expect(ticks, const [Duration(milliseconds: 500)]);
  });

  test('Should not call onTick when ticker is muted', () {
    final ticks = <Duration>[];
    final mockTicker = TestTicker(ticks.add);

    mockTicker.start();
    mockTicker.muted = true;
    mockTicker.tick(const Duration(milliseconds: 500));

    expect(ticks, isEmpty);
  });

  test('Should throw error if start is called while already active', () {
    final mockTicker = TestTicker((elapsed) {});

    mockTicker.start();
    expect(mockTicker.start, throwsA(isA<StateError>()));
  });

  test('Should correctly reflect isActive state', () {
    final mockTicker = TestTicker((elapsed) {});

    expect(mockTicker.isActive, isFalse);

    mockTicker.start();
    expect(mockTicker.isActive, isTrue);

    mockTicker.stop();
    expect(mockTicker.isActive, isFalse);
  });

  test('Should correctly reflect isTicking state', () {
    final mockTicker = TestTicker((elapsed) {});

    mockTicker.start();
    expect(mockTicker.isTicking, isTrue);

    mockTicker.muted = true;
    expect(mockTicker.isTicking, isFalse);

    mockTicker.muted = false;
    expect(mockTicker.isTicking, isTrue);
  });

  test('dispose Should stop ticker and make it inactive', () {
    final mockTicker = TestTicker((elapsed) {});

    mockTicker.start();
    mockTicker.dispose();

    expect(mockTicker.isActive, isFalse);
    expect(mockTicker.isTicking, isFalse);
  });

  test('tick Should not advance if ticker is disposed', () {
    final ticks = <Duration>[];
    final mockTicker = TestTicker(ticks.add);

    mockTicker.start();
    mockTicker.dispose();
    mockTicker.tick(const Duration(milliseconds: 500));

    expect(ticks, isEmpty);
  });

  test(
      'should call onTick repeatedly with custom duration '
      'until ticker is inactive', () {
    late TestTicker ticker;
    final tickDurations = <Duration>[];
    void onTick(Duration elapsed) {
      tickDurations.add(elapsed);
      if (elapsed >= const Duration(milliseconds: 500)) {
        ticker.stop();
      }
    }

    ticker = TestTicker(onTick);

    ticker.start();
    ticker.tickAndSettle(duration: const Duration(milliseconds: 120));

    expect(
      tickDurations,
      const [
        Duration(milliseconds: 120),
        Duration(milliseconds: 240),
        Duration(milliseconds: 360),
        Duration(milliseconds: 480),
        Duration(milliseconds: 600),
      ],
    );
  });

  test('toString Should include debugLabel if provided', () {
    final mockTicker = TestTicker((elapsed) {}, debugLabel: 'debugLabel');
    expect(mockTicker.toString(), contains('debugLabel'));
  });
}

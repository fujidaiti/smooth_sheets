import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/activity.dart';

import 'src/flutter_test_x.dart';
import 'src/matchers.dart';
import 'src/stubbing.dart';

class _TestAnimatedSheetActivity extends AnimatedSheetActivity {
  _TestAnimatedSheetActivity({
    required AnimationController controller,
    required super.destination,
    required super.motion,
    super.initialVelocity,
  }) : _controller = controller;

  final AnimationController _controller;

  @override
  AnimationController createAnimationController() {
    return _controller;
  }
}

void main() {
  group('AnimatedSheetActivity', () {
    late MockAnimationController controller;

    setUp(() {
      controller = MockAnimationController();
      when(
        controller.animateTo(
          any,
          duration: anyNamed('duration'),
          curve: anyNamed('curve'),
        ),
      ).thenAnswer((_) => MockTickerFuture());
    });

    test('should animate to the destination', () {
      final (ownerMetrics, owner) = createMockSheetModel(
        offset: 300,
        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(300),
        ),
        contentSize: const Size(400, 700),
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetOffset.absolute(700),
        motion: CurvedSheetMotion(
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        ),
      )..init(owner);

      verify(
        controller.animateTo(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        ),
      );

      when(controller.value).thenReturn(0.0);
      activity.onAnimationTick();
      expect(ownerMetrics.offset, 300);

      when(controller.value).thenReturn(0.5);
      activity.onAnimationTick();
      expect(ownerMetrics.offset, 500);

      when(controller.value).thenReturn(1.0);
      activity.onAnimationTick();
      expect(ownerMetrics.offset, 700);
    });

    // Regression test: the curve was applied twice, once by
    // AnimationController.animateTo() and once again in onAnimationTick(),
    // so the sheet followed `curve o curve` instead of `curve`. It went
    // unnoticed because the other tests here use the idempotent
    // Curves.linear.
    test('should not apply the curve on top of the controller value', () {
      final (ownerMetrics, owner) = createMockSheetModel(
        offset: 300,
        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(300),
        ),
        contentSize: const Size(400, 700),
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetOffset.absolute(700),
        motion: CurvedSheetMotion(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
      )..init(owner);

      // What the controller reports a quarter of the way through the
      // animation: the curve has already been applied to it.
      final quarterWay = Curves.easeInOut.transform(0.25);
      expect(quarterWay, moreOrLessEquals(0.1287, epsilon: 1e-4));

      when(controller.value).thenReturn(quarterWay);
      activity.onAnimationTick();

      expect(
        ownerMetrics.offset,
        moreOrLessEquals(300 + 400 * quarterWay, epsilon: 1e-6),
        reason:
            'The offset should follow the curve once. Applying it twice '
            'would put the sheet at '
            '${300 + 400 * Curves.easeInOut.transform(quarterWay)}.',
      );
    });

    ({MockSheetModel owner, _TestAnimatedSheetActivity activity})
    springActivity({
      required double from,
      required double to,
      double velocity = 0,
    }) {
      final (_, owner) = createMockSheetModel(
        offset: from,
        snapGrid: SheetSnapGrid.stepless(
          minOffset: SheetOffset.absolute(min(from, to)),
        ),
        contentSize: const Size(400, 700),
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );
      when(controller.animateWith(any)).thenAnswer((_) => MockTickerFuture());

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: SheetOffset.absolute(to),
        motion: const SpringSheetMotion(),
        initialVelocity: velocity,
      )..init(owner);

      return (owner: owner, activity: activity);
    }

    Simulation capturedSimulation() =>
        verify(controller.animateWith(captureAny)).captured.single
            as Simulation;

    test('should drive a spring motion with a simulation', () {
      springActivity(from: 300, to: 700);
      final simulation = capturedSimulation();

      expect(simulation.x(0), moreOrLessEquals(0));
      expect(simulation.dx(0), moreOrLessEquals(0));
      expect(
        simulation.x(5),
        moreOrLessEquals(1),
        reason: 'The simulation runs in normalized progress, not in pixels.',
      );
    });

    test('should convert the initial velocity into progress per second', () {
      // 400 pixels of travel, so 800 px/s is 2 progress units per second.
      springActivity(from: 300, to: 700, velocity: 800);
      expect(capturedSimulation().dx(0), moreOrLessEquals(2));
    });

    test('should keep the velocity sign when animating downwards', () {
      // Travelling -400 px, already moving down at -800 px/s: still 2/s
      // towards the destination.
      springActivity(from: 700, to: 300, velocity: -800);
      expect(capturedSimulation().dx(0), moreOrLessEquals(2));
    });

    test('should report its velocity in pixels per second', () {
      final env = springActivity(from: 300, to: 700);
      when(controller.velocity).thenReturn(2);
      expect(
        env.activity.velocity,
        moreOrLessEquals(800),
        reason:
            'The controller runs in progress per second; the sheet moves in '
            'pixels per second.',
      );
    });

    // The curved counterpart of this is 'should absorb viewport changes'
    // below, which hands the remaining duration to a SettlingSheetActivity.
    // A spring has no remaining duration, so it re-aims instead.
    test('should re-aim a spring motion when the destination moves', () {
      final (ownerMetrics, owner) = createMockSheetModel(
        offset: 250,
        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(250),
        ),
        contentSize: const Size(400, 850),
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );
      when(controller.animateWith(any)).thenAnswer((_) => MockTickerFuture());

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetOffset(1),
        motion: const SpringSheetMotion(),
      )..init(owner);

      when(controller.value).thenReturn(0.25);
      when(controller.velocity).thenReturn(0.5);
      activity.onAnimationTick();

      // The on-screen keyboard appears and pushes the content up, moving the
      // resolved destination.
      final oldMeasurements = ownerMetrics.copyWith();
      ownerMetrics
        ..contentSize = const Size(400, 850)
        ..contentMargin = EdgeInsets.only(bottom: 50)
        ..contentBaseline = 50;

      activity.applyNewLayout(oldMeasurements);

      verifyNever(owner.settleTo(any, any));
      final captured =
          verify(
                owner.animateTo(
                  const SheetOffset(1),
                  motion: anyNamed('motion'),
                  velocity: captureAnyNamed('velocity'),
                ),
              ).captured.single
              as double;
      expect(
        captured,
        greaterThan(0),
        reason: 'The current speed should carry across the re-aim.',
      );
    });

    test('should absorb viewport changes', () {
      final (ownerMetrics, owner) = createMockSheetModel(
        offset: 250,

        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(250),
        ),
        contentSize: const Size(400, 850),
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetOffset(1),
        motion: CurvedSheetMotion(
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        ),
      )..init(owner);

      when(controller.value).thenReturn(0.0);
      activity.onAnimationTick();
      expect(ownerMetrics.offset, 250);

      when(controller.value).thenReturn(0.25);
      when(
        controller.lastElapsedDuration,
      ).thenReturn(const Duration(milliseconds: 75));
      activity.onAnimationTick();
      expect(ownerMetrics.offset, 400);

      // The following lines simulate a viewport change, in which:
      // 1. The viewport's bottom inset increases, simulating the
      //    appearance of an on-screen keyboard.
      // 2. The content is then pushed up to avoid being overlapped by
      //    the keyboard.
      // This scenario mimics the behavior when opening a keyboard
      // on a sheet that uses SheetContentScaffold.
      final oldMeasurements = ownerMetrics.copyWith();
      ownerMetrics
        ..contentSize = const Size(400, 850)
        ..contentMargin = EdgeInsets.only(bottom: 50)
        ..contentBaseline = 50;

      activity.applyNewLayout(oldMeasurements);
      expect(ownerMetrics.offset, 400);
      verify(
        owner.settleTo(const SheetOffset(1), const Duration(milliseconds: 225)),
      );
    });
  });

  group('BallisticSheetActivity', () {
    testWithVsync('should stop when a physics detects overflow', (
      tester,
    ) async {
      const frameTime = Duration(milliseconds: 17);

      final mockSheetContext = MockSheetContext();
      when(mockSheetContext.vsync).thenReturn(const TestVSync());

      final mockSheetModel = MockSheetModel();
      final mockPhysics = MockSheetPhysics();
      final mockSimulation = MockSimulation();
      when(mockSheetModel.context).thenReturn(mockSheetContext);
      when(mockSheetModel.physics).thenReturn(mockPhysics);
      when(mockSheetModel.offset).thenReturn(350);
      when(mockSheetModel.hasMetrics).thenReturn(true);

      final activity = BallisticSheetActivity(simulation: mockSimulation);
      tester.addTearDown(activity.dispose);

      activity.init(mockSheetModel);
      await tester.flushMicrotasks();

      when(mockSimulation.x(any)).thenReturn(365);
      when(mockSimulation.isDone(any)).thenReturn(false);
      when(mockPhysics.computeOverflow(any, any)).thenReturn(0);
      await tester.elapse(frameTime);
      verify(mockSheetModel.offset = 365);

      when(mockSimulation.x(any)).thenReturn(380);
      when(mockSheetModel.offset).thenReturn(365);
      await tester.elapse(frameTime);
      verify(mockSheetModel.offset = 380);

      when(mockSheetModel.offset).thenReturn(380);
      when(mockSimulation.x(any)).thenReturn(395);
      await tester.elapse(frameTime);
      verify(mockSheetModel.offset = 395);

      when(mockSheetModel.offset).thenReturn(395);
      when(mockSimulation.x(any)).thenReturn(410);
      when(mockSimulation.isDone(any)).thenReturn(true);
      when(mockPhysics.computeOverflow(any, any)).thenReturn(10);
      await tester.elapse(frameTime);
      verify(mockSheetModel.offset = 400);
      verify(mockSheetModel.goBallistic(0));
    });
  });

  group('SettlingSheetActivity', () {
    late MockSheetModel owner;
    late MutableSheetMetrics ownerMetrics;
    late MockTicker internalTicker;
    late TickerCallback? internalOnTickCallback;

    setUp(() {
      (ownerMetrics, owner) = createMockSheetModel(
        offset: 300,

        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(300),
        ),
        contentSize: const Size(400, 600),
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );
      internalTicker = MockTicker();
      final tickerProvider = MockTickerProvider();
      final context = MockSheetContext();
      when(context.vsync).thenReturn(tickerProvider);
      when(tickerProvider.createTicker(any)).thenAnswer((invocation) {
        internalOnTickCallback =
            invocation.positionalArguments[0] as TickerCallback;
        return internalTicker;
      });
      when(owner.context).thenReturn(context);
    });

    tearDown(() {
      internalOnTickCallback = null;
    });

    test('Create with velocity', () {
      final activity = SettlingSheetActivity(
        destination: const SheetOffset(0),
        velocity: 100,
      );

      expect(activity.destination, const SheetOffset(0));
      expect(activity.duration, isNull);
      expect(activity.velocity, 100);
      expect(activity.shouldIgnorePointer, isFalse);
    });

    test('Create with duration', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const SheetOffset(0),
      );

      expect(activity.destination, const SheetOffset(0));
      expect(activity.duration, const Duration(milliseconds: 300));
      expect(activity.shouldIgnorePointer, isFalse);
      expect(() => activity.velocity, isNotInitialized);
    });

    test('Velocity should be set when the activity is initialized', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const SheetOffset(1),
      );
      expect(() => activity.velocity, isNotInitialized);

      activity.init(owner);
      expect(activity.velocity, 1000); // (300pixels / 300ms) = 1000 offset/s
    });

    test('Progressively updates current position toward destination', () {
      final activity = SettlingSheetActivity(
        destination: const SheetOffset(1),
        velocity: 300,
      );

      activity.init(owner);
      verify(internalTicker.start());

      internalOnTickCallback!(const Duration(milliseconds: 200));
      expect(ownerMetrics.offset, 360); // 300 * 0.2 = 60 offset in 200ms

      internalOnTickCallback!(const Duration(milliseconds: 400));
      expect(ownerMetrics.offset, 420); // 300 * 0.2 = 60 offset in 200ms

      internalOnTickCallback!(const Duration(milliseconds: 500));
      expect(ownerMetrics.offset, 450); // 300 * 0.1 = 30 offset in 100ms

      internalOnTickCallback!(const Duration(milliseconds: 800));
      expect(ownerMetrics.offset, 540); // 300 * 0.3 = 90 offset in 300ms

      internalOnTickCallback!(const Duration(milliseconds: 1000));
      expect(ownerMetrics.offset, 600); // 300 * 0.2 = 60 offset in 200ms
    });

    test('Should start an idle activity when it reaches destination', () {
      final _ = SettlingSheetActivity(
        destination: const SheetOffset(1),
        velocity: 300,
      )..init(owner);

      ownerMetrics.offset = 540;
      internalOnTickCallback!(const Duration(milliseconds: 1000));
      verify(owner.goIdle(targetOffset: const SheetOffset(1)));
    });

    test('Should absorb viewport changes', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const SheetOffset(1),
      )..init(owner);

      expect(activity.velocity, 1000); // (300 offset / 0.3s) = 1000 offset/s

      internalOnTickCallback!(const Duration(milliseconds: 50));
      expect(ownerMetrics.offset, 350); // 1000 * 0.05 = 50 offset in 50ms

      final oldMeasurements = ownerMetrics.copyWith();
      // Show the on-screen keyboard.
      ownerMetrics
        ..contentMargin = EdgeInsets.only(bottom: 30)
        ..contentBaseline = 30;

      activity.applyNewLayout(oldMeasurements);
      expect(
        ownerMetrics.offset,
        350,
        reason: 'Visual position should not change when viewport changes.',
      );
      expect(
        activity.velocity,
        1120, // 280 offset / 0.25s = 1120 offset/s
        reason: 'Velocity should be updated when viewport changes.',
      );

      internalOnTickCallback!(const Duration(milliseconds: 100));
      expect(ownerMetrics.offset, 406); // 1120 * 0.05 = 56 offset in 50ms
    });
  });

  group('IdleSheetActivity', () {
    test(
      'should keep the only 20% of the content visible when keyboard appears',
      () {
        final (ownerMetrics, owner) = createMockSheetModel(
          offset: 160,
          snapGrid: SheetSnapGrid(
            snaps: [const SheetOffset(0.2), const SheetOffset(1)],
          ),
          contentSize: const Size(400, 800),
          viewportSize: const Size(400, 900),
          devicePixelRatio: 1,
          physics: kDefaultSheetPhysics,
        );
        final activity = IdleSheetActivity(targetOffset: const SheetOffset(0.2))
          ..init(owner);

        final oldMeasurements = ownerMetrics.copyWith();
        ownerMetrics
          ..contentMargin = EdgeInsets.only(bottom: 50)
          ..contentBaseline = 50;
        activity.applyNewLayout(oldMeasurements);
        expect(ownerMetrics.offset, 210);
      },
    );

    test('should maintain previous position when content size changes', () {
      final (ownerMetrics, owner) = createMockSheetModel(
        offset: 250,
        snapGrid: SheetSnapGrid(
          snaps: [const SheetOffset(0.5), const SheetOffset(1)],
        ),
        contentSize: Size(400, 500),
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
        physics: kDefaultSheetPhysics,
      );

      final activity = IdleSheetActivity(targetOffset: const SheetOffset(0.5))
        ..init(owner);

      final oldMeasurements = owner.copyWith();
      ownerMetrics.contentSize = Size(400, 600);
      activity.applyNewLayout(oldMeasurements);
      expect(owner.offset, 300);
      // Still in the idle activity.
      verifyNever(owner.beginActivity(any));
    });
  });
}

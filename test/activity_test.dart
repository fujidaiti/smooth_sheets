import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/activity.dart';

import 'src/matchers.dart';
import 'src/stubbing.dart';

class _TestAnimatedSheetActivity extends AnimatedSheetActivity {
  _TestAnimatedSheetActivity({
    required AnimationController controller,
    required super.destination,
    required super.duration,
    required super.curve,
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
        initialPosition: const SheetOffset.absolute(300),
        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(300),
        ),
        contentExtent: 700,
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetOffset.absolute(700),
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
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

    test('should absorb viewport changes', () {
      final (ownerMetrics, owner) = createMockSheetModel(
        offset: 250,
        initialPosition: const SheetOffset.absolute(250),
        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(250),
        ),
        contentExtent: 850,
        viewportSize: const Size(400, 900),
        devicePixelRatio: 1,
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetOffset.relative(1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      )..init(owner);

      when(controller.value).thenReturn(0.0);
      activity.onAnimationTick();
      expect(ownerMetrics.offset, 250);

      when(controller.value).thenReturn(0.25);
      when(controller.lastElapsedDuration)
          .thenReturn(const Duration(milliseconds: 75));
      activity.onAnimationTick();
      expect(ownerMetrics.offset, 400);

      // The following lines simulate a viewport change, in which:
      // 1. The viewport's bottom inset increases, simulating the
      //    appearance of an on-screen keyboard.
      // 2. The content is then pushed up to avoid being overlapped by
      //    the keyboard.
      // This scenario mimics the behavior when opening a keyboard
      // on a sheet that uses SheetContentScaffold.
      final oldMeasurements = ownerMetrics.measurements;
      ownerMetrics.measurements = ownerMetrics.measurements.copyWith(
        contentExtent: 850,
        layoutSpec: SheetLayoutSpec(
          viewportSize: const Size(400, 900),
          viewportPadding: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
          viewportStaticOverlap: EdgeInsets.zero,
          resizeContentToAvoidBottomOverlap: true,
        ),
      );

      activity.didChangeMeasurements(oldMeasurements);
      expect(ownerMetrics.offset, 400);
      verify(owner.settleTo(
        const SheetOffset.relative(1),
        const Duration(milliseconds: 225),
      ));
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
        initialPosition: const SheetOffset.relative(0.5),
        snapGrid: SheetSnapGrid.stepless(
          minOffset: const SheetOffset.absolute(300),
        ),
        contentExtent: 600,
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
        destination: const SheetOffset.absolute(0),
        velocity: 100,
      );

      expect(activity.destination, const SheetOffset.absolute(0));
      expect(activity.duration, isNull);
      expect(activity.velocity, 100);
      expect(activity.shouldIgnorePointer, isFalse);
    });

    test('Create with duration', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const SheetOffset.absolute(0),
      );

      expect(activity.destination, const SheetOffset.absolute(0));
      expect(activity.duration, const Duration(milliseconds: 300));
      expect(activity.shouldIgnorePointer, isFalse);
      expect(() => activity.velocity, isNotInitialized);
    });

    test(
      'Velocity should be set when the activity is initialized',
      () {
        final activity = SettlingSheetActivity.withDuration(
          const Duration(milliseconds: 300),
          destination: const SheetOffset.relative(1),
        );
        expect(() => activity.velocity, isNotInitialized);

        activity.init(owner);
        expect(activity.velocity, 1000); // (300pixels / 300ms) = 1000 offset/s
      },
    );

    test('Progressively updates current position toward destination', () {
      final activity = SettlingSheetActivity(
        destination: const SheetOffset.relative(1),
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

    test(
      'Should start an idle activity when it reaches destination',
      () {
        final _ = SettlingSheetActivity(
          destination: const SheetOffset.relative(1),
          velocity: 300,
        )..init(owner);

        ownerMetrics.offset = 540;
        internalOnTickCallback!(const Duration(milliseconds: 1000));
        verify(owner.goIdle());
      },
    );

    test('Should absorb viewport changes', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const SheetOffset.relative(1),
      )..init(owner);

      expect(activity.velocity, 1000); // (300 offset / 0.3s) = 1000 offset/s

      internalOnTickCallback!(const Duration(milliseconds: 50));
      expect(ownerMetrics.offset, 350); // 1000 * 0.05 = 50 offset in 50ms

      final oldMeasurements = ownerMetrics.measurements;
      // Show the on-screen keyboard.
      ownerMetrics.measurements = oldMeasurements.copyWith(
        layoutSpec: SheetLayoutSpec(
          viewportSize: const Size(400, 900),
          viewportPadding: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.only(bottom: 30),
          viewportStaticOverlap: EdgeInsets.zero,
          resizeContentToAvoidBottomOverlap: true,
        ),
      );
      activity.didChangeMeasurements(oldMeasurements);
      expect(ownerMetrics.offset, 350,
          reason: 'Visual position should not change when viewport changes.');
      expect(activity.velocity, 1120, // 280 offset / 0.25s = 1120 offset/s
          reason: 'Velocity should be updated when viewport changes.');

      internalOnTickCallback!(const Duration(milliseconds: 100));
      expect(ownerMetrics.offset, 406); // 1120 * 0.05 = 56 offset in 50ms
    });
  });

  group('IdleSheetActivity', () {
    test(
      'should keep the only 50% of the content visible when keyboard appears',
      () {
        final (ownerMetrics, owner) = createMockSheetModel(
          offset: 160,
          initialPosition: const SheetOffset.relative(0.2),
          snapGrid: SheetSnapGrid(
            snaps: [
              const SheetOffset.relative(0.2),
              const SheetOffset.relative(1),
            ],
          ),
          contentExtent: 800,
          viewportSize: const Size(400, 900),
          viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
          devicePixelRatio: 1,
          physics: kDefaultSheetPhysics,
        );

        final oldMeasurements = ownerMetrics.measurements;
        ownerMetrics.measurements = SheetLayoutMeasurements(
          layoutSpec: SheetLayoutSpec(
            viewportSize: const Size(400, 900),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: true,
          ),
          contentExtent: 850,
        );
        IdleSheetActivity()
          ..init(owner)
          ..didChangeMeasurements(oldMeasurements);
        expect(ownerMetrics.offset, 220);
      },
    );

    test(
      'should maintain previous position when content size changes',
      () {
        final (ownerMetrics, owner) = createMockSheetModel(
          offset: 250,
          initialPosition: const SheetOffset.relative(0.5),
          snapGrid: SheetSnapGrid(
            snaps: [
              const SheetOffset.relative(0.5),
              const SheetOffset.relative(1),
            ],
          ),
          contentExtent: 500,
          viewportSize: const Size(400, 900),
          devicePixelRatio: 1,
          physics: kDefaultSheetPhysics,
        );
        expect(ownerMetrics.offset, 250);

        final oldMeasurements = owner.measurements;
        owner.measurements = owner.measurements.copyWith(
          contentExtent: 600,
        );
        IdleSheetActivity()
          ..init(owner)
          ..didChangeMeasurements(oldMeasurements);
        expect(owner.offset, 300);
        // Still in the idle activity.
        verifyNever(owner.beginActivity(any));
      },
    );
  });
}

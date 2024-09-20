import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';

import '../src/matchers.dart';
import '../src/stubbing.dart';

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
    late MockSheetExtent owner;
    late MockAnimationController controller;

    setUp(() {
      owner = MockSheetExtent();
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
      when(owner.metrics).thenReturn(
        const SheetMetrics(
          pixels: 300,
          minExtent: Extent.pixels(300),
          maxExtent: Extent.pixels(700),
          contentSize: Size(400, 700),
          viewportSize: Size(400, 900),
          viewportInsets: EdgeInsets.zero,
        ),
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const Extent.pixels(700),
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
      verify(owner.setPixels(300));

      when(controller.value).thenReturn(0.5);
      activity.onAnimationTick();
      verify(owner.setPixels(500));

      when(controller.value).thenReturn(1.0);
      activity.onAnimationTick();
      verify(owner.setPixels(700));
    });

    test('should absorb viewport changes', () {
      var metrics = const SheetMetrics(
        pixels: 300,
        minExtent: Extent.pixels(300),
        maxExtent: Extent.proportional(1),
        contentSize: Size(400, 900),
        viewportSize: Size(400, 900),
        viewportInsets: EdgeInsets.zero,
      );
      when(owner.metrics).thenAnswer((_) => metrics);
      when(owner.setPixels(any)).thenAnswer((invocation) {
        final pixels = invocation.positionalArguments[0] as double;
        metrics = metrics.copyWith(pixels: pixels);
      });

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const Extent.proportional(1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      )..init(owner);

      when(controller.value).thenReturn(0.0);
      activity.onAnimationTick();
      expect(metrics.pixels, 300);

      when(controller.value).thenReturn(0.25);
      when(controller.lastElapsedDuration)
          .thenReturn(const Duration(milliseconds: 75));
      activity.onAnimationTick();
      expect(metrics.pixels, 450);

      // The following lines simulate a viewport change, in which:
      // 1. The viewport's bottom inset increases, simulating the
      //    appearance of an on-screen keyboard.
      // 2. The content size then reduces to avoid overlapping with the
      //    increased bottom inset.
      // This scenario mimics the behavior when opening a keyboard
      // on a sheet that uses SheetContentScaffold.
      final oldViewportInsets = metrics.viewportInsets;
      final oldContentSize = metrics.contentSize;
      metrics = metrics.copyWith(
        viewportInsets: const EdgeInsets.only(bottom: 50),
        contentSize: const Size(400, 850),
      );
      activity.didChangeViewportDimensions(null, oldViewportInsets);
      activity.didChangeContentSize(oldContentSize);
      activity.didFinalizeDimensions(oldContentSize, null, oldViewportInsets);
      expect(metrics.pixels, 400);
      expect(metrics.viewPixels, 450,
          reason: 'Visual position should not change when viewport changes.');
      verify(owner.settleTo(
        const Extent.proportional(1),
        const Duration(milliseconds: 225),
      ));
    });
  });

  group('SettlingSheetActivity', () {
    late MockSheetExtent owner;
    late MockTicker internalTicker;
    late TickerCallback? internalOnTickCallback;

    const initialMetrics = SheetMetrics(
      pixels: 300,
      minExtent: Extent.proportional(0.5),
      maxExtent: Extent.proportional(1),
      contentSize: Size(400, 600),
      viewportSize: Size(400, 900),
      viewportInsets: EdgeInsets.zero,
    );

    setUp(() {
      owner = MockSheetExtent();
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
        destination: const Extent.pixels(0),
        velocity: 100,
      );

      expect(activity.destination, const Extent.pixels(0));
      expect(activity.duration, isNull);
      expect(activity.velocity, 100);
      expect(activity.shouldIgnorePointer, isFalse);
    });

    test('Create with duration', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const Extent.pixels(0),
      );

      expect(activity.destination, const Extent.pixels(0));
      expect(activity.duration, const Duration(milliseconds: 300));
      expect(activity.shouldIgnorePointer, isFalse);
      expect(() => activity.velocity, isNotInitialized);
    });

    test(
      'Velocity should be set when the activity is initialized',
      () {
        final activity = SettlingSheetActivity.withDuration(
          const Duration(milliseconds: 300),
          destination: const Extent.proportional(1),
        );
        expect(() => activity.velocity, isNotInitialized);

        when(owner.metrics).thenReturn(initialMetrics);
        activity.init(owner);
        expect(activity.velocity, 1000); // (300pixels / 300ms) = 1000 pixels/s
      },
    );

    test('Progressively updates current position toward destination', () {
      final activity = SettlingSheetActivity(
        destination: const Extent.proportional(1),
        velocity: 300,
      );

      activity.init(owner);
      verify(internalTicker.start());

      when(owner.metrics).thenReturn(initialMetrics);
      internalOnTickCallback!(const Duration(milliseconds: 200));
      verify(owner.setPixels(360)); // 300 * 0.2 = 60 pixels in 200ms

      when(owner.metrics).thenReturn(initialMetrics.copyWith(pixels: 360));
      internalOnTickCallback!(const Duration(milliseconds: 400));
      verify(owner.setPixels(420)); // 300 * 0.2 = 60 pixels in 200ms

      when(owner.metrics).thenReturn(initialMetrics.copyWith(pixels: 420));
      internalOnTickCallback!(const Duration(milliseconds: 500));
      verify(owner.setPixels(450)); // 300 * 0.1 = 30 pixels in 100ms

      when(owner.metrics).thenReturn(initialMetrics.copyWith(pixels: 450));
      internalOnTickCallback!(const Duration(milliseconds: 800));
      verify(owner.setPixels(540)); // 300 * 0.3 = 90 pixels in 300ms

      when(owner.metrics).thenReturn(initialMetrics.copyWith(pixels: 540));
      internalOnTickCallback!(const Duration(milliseconds: 1000));
      verify(owner.setPixels(600)); // 300 * 0.2 = 60 pixels in 200ms
    });

    test(
      'Should start an idle activity when it reaches destination',
      () {
        final _ = SettlingSheetActivity(
          destination: const Extent.proportional(1),
          velocity: 300,
        )..init(owner);

        when(owner.metrics).thenReturn(initialMetrics.copyWith(pixels: 540));
        internalOnTickCallback!(const Duration(milliseconds: 1000));
        verify(owner.goIdle());
      },
    );

    test('Should absorb viewport changes', () {
      var metrics = initialMetrics;
      when(owner.metrics).thenAnswer((_) => metrics);
      when(owner.setPixels(any)).thenAnswer((invocation) {
        final pixels = invocation.positionalArguments[0] as double;
        metrics = metrics.copyWith(pixels: pixels);
      });

      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const Extent.proportional(1),
      )..init(owner);

      expect(activity.velocity, 1000); // (300 pixels / 0.3s) = 1000 pixels/s

      internalOnTickCallback!(const Duration(milliseconds: 50));
      expect(metrics.pixels, 350); // 1000 * 0.05 = 50 pixels in 50ms

      // Show the on-screen keyboard.
      metrics = metrics.copyWith(
        viewportInsets: const EdgeInsets.only(bottom: 30),
      );
      final oldViewportInsets = initialMetrics.viewportInsets;
      final oldContentSize = initialMetrics.contentSize;
      activity.didChangeViewportDimensions(null, oldViewportInsets);
      activity.didChangeContentSize(oldContentSize);
      activity.didFinalizeDimensions(oldContentSize, null, oldViewportInsets);
      expect(metrics.pixels, 320,
          reason: 'Visual position should not change when viewport changes.');
      expect(activity.velocity, 1120, // 280 pixels / 0.25s = 1120 pixels/s
          reason: 'Velocity should be updated when viewport changes.');

      internalOnTickCallback!(const Duration(milliseconds: 100));
      expect(metrics.pixels, 376); // 1120 * 0.05 = 56 pixels in 50ms
    });
  });

  group('IdleSheetActivity', () {
    late MockSheetExtent owner;
    late SheetMetrics metrics;

    setUp(() {
      owner = MockSheetExtent();
      when(owner.physics).thenReturn(kDefaultSheetPhysics);
      when(owner.metrics).thenAnswer((_) => metrics);
      when(owner.setPixels(any)).thenAnswer((invocation) {
        final pixels = invocation.positionalArguments[0] as double;
        metrics = metrics.copyWith(pixels: pixels);
      });
    });

    test('should maintain previous extent when keyboard appears', () {
      final activity = IdleSheetActivity()..init(owner);
      const oldContentSize = Size(400, 900);
      const oldViewportInsets = EdgeInsets.zero;
      metrics = const SheetMetrics(
        pixels: 450,
        minExtent: Extent.proportional(0.5),
        maxExtent: Extent.proportional(1),
        contentSize: Size(400, 850),
        viewportSize: Size(400, 900),
        viewportInsets: EdgeInsets.only(bottom: 50),
      );
      activity
        ..didChangeContentSize(oldContentSize)
        ..didChangeViewportDimensions(oldContentSize, oldViewportInsets)
        ..didFinalizeDimensions(oldContentSize, null, oldViewportInsets);
      expect(metrics.pixels, 425);
    });

    test(
      'should maintain previous extent when content size changes, '
      'without animation if gap is small',
      () {
        final activity = IdleSheetActivity()..init(owner);
        const oldContentSize = Size(400, 600);
        metrics = const SheetMetrics(
          pixels: 300,
          minExtent: Extent.proportional(0.5),
          maxExtent: Extent.proportional(1),
          contentSize: Size(400, 580),
          viewportSize: Size(400, 900),
          viewportInsets: EdgeInsets.zero,
        );
        activity
          ..didChangeContentSize(oldContentSize)
          ..didFinalizeDimensions(oldContentSize, null, null);
        expect(metrics.pixels, 290);
        // Still in the idle activity.
        verifyNever(owner.beginActivity(any));
      },
    );

    test(
      'should maintain previous extent when content size changes, '
      'with animation if gap is large',
      () {
        final activity = IdleSheetActivity()..init(owner);
        const oldContentSize = Size(400, 600);
        metrics = const SheetMetrics(
          pixels: 300,
          minExtent: Extent.proportional(0.5),
          maxExtent: Extent.proportional(1),
          contentSize: Size(400, 500),
          viewportSize: Size(400, 900),
          viewportInsets: EdgeInsets.zero,
        );
        activity
          ..didChangeContentSize(oldContentSize)
          ..didFinalizeDimensions(oldContentSize, null, null);
        expect(metrics.pixels, 300);
        verify(
          owner.animateTo(
            const Extent.proportional(0.5),
            duration: anyNamed('duration'),
            curve: anyNamed('curve'),
          ),
        );
      },
    );
  });
}

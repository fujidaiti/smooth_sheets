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
      final (ownerMetrics, owner) = createMockSheetPosition(
        pixels: 300,
        minPosition: const SheetAnchor.pixels(300),
        maxPosition: const SheetAnchor.pixels(700),
        contentSize: const Size(400, 700),
        viewportSize: const Size(400, 900),
        viewportInsets: EdgeInsets.zero,
        devicePixelRatio: 1,
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetAnchor.pixels(700),
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
      expect(ownerMetrics.pixels, 300);

      when(controller.value).thenReturn(0.5);
      activity.onAnimationTick();
      expect(ownerMetrics.pixels, 500);

      when(controller.value).thenReturn(1.0);
      activity.onAnimationTick();
      expect(ownerMetrics.pixels, 700);
    });

    test('should absorb viewport changes', () {
      final (ownerMetrics, owner) = createMockSheetPosition(
        pixels: 300,
        minPosition: const SheetAnchor.pixels(300),
        maxPosition: const SheetAnchor.proportional(1),
        contentSize: const Size(400, 900),
        viewportSize: const Size(400, 900),
        viewportInsets: EdgeInsets.zero,
        devicePixelRatio: 1,
      );

      final activity = _TestAnimatedSheetActivity(
        controller: controller,
        destination: const SheetAnchor.proportional(1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      )..init(owner);

      when(controller.value).thenReturn(0.0);
      activity.onAnimationTick();
      expect(ownerMetrics.pixels, 300);

      when(controller.value).thenReturn(0.25);
      when(controller.lastElapsedDuration)
          .thenReturn(const Duration(milliseconds: 75));
      activity.onAnimationTick();
      expect(ownerMetrics.pixels, 450);

      // The following lines simulate a viewport change, in which:
      // 1. The viewport's bottom inset increases, simulating the
      //    appearance of an on-screen keyboard.
      // 2. The content size then reduces to avoid overlapping with the
      //    increased bottom inset.
      // This scenario mimics the behavior when opening a keyboard
      // on a sheet that uses SheetContentScaffold.
      final oldViewportInsets = ownerMetrics.viewportInsets;
      final oldContentSize = ownerMetrics.contentSize;
      ownerMetrics
        ..maybeViewportInsets = const EdgeInsets.only(bottom: 50)
        ..maybeContentSize = const Size(400, 850);

      activity.didChangeViewportDimensions(null);
      activity.didChangeContentSize(oldContentSize);
      activity.didChangeViewportInsets(oldViewportInsets);
      activity.finalizePosition(oldContentSize, null, oldViewportInsets);
      expect(ownerMetrics.pixels, 400);
      expect(ownerMetrics.viewPixels, 450,
          reason: 'Visual position should not change when viewport changes.');
      verify(owner.settleTo(
        const SheetAnchor.proportional(1),
        const Duration(milliseconds: 225),
      ));
    });
  });

  group('SettlingSheetActivity', () {
    late MockSheetPosition owner;
    late MutableSheetMetrics ownerMetrics;
    late MockTicker internalTicker;
    late TickerCallback? internalOnTickCallback;

    setUp(() {
      (ownerMetrics, owner) = createMockSheetPosition(
        pixels: 300,
        minPosition: const SheetAnchor.proportional(0.5),
        maxPosition: const SheetAnchor.proportional(1),
        contentSize: const Size(400, 600),
        viewportSize: const Size(400, 900),
        viewportInsets: EdgeInsets.zero,
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
        destination: const SheetAnchor.pixels(0),
        velocity: 100,
      );

      expect(activity.destination, const SheetAnchor.pixels(0));
      expect(activity.duration, isNull);
      expect(activity.velocity, 100);
      expect(activity.shouldIgnorePointer, isFalse);
    });

    test('Create with duration', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const SheetAnchor.pixels(0),
      );

      expect(activity.destination, const SheetAnchor.pixels(0));
      expect(activity.duration, const Duration(milliseconds: 300));
      expect(activity.shouldIgnorePointer, isFalse);
      expect(() => activity.velocity, isNotInitialized);
    });

    test(
      'Velocity should be set when the activity is initialized',
      () {
        final activity = SettlingSheetActivity.withDuration(
          const Duration(milliseconds: 300),
          destination: const SheetAnchor.proportional(1),
        );
        expect(() => activity.velocity, isNotInitialized);

        activity.init(owner);
        expect(activity.velocity, 1000); // (300pixels / 300ms) = 1000 pixels/s
      },
    );

    test('Progressively updates current position toward destination', () {
      final activity = SettlingSheetActivity(
        destination: const SheetAnchor.proportional(1),
        velocity: 300,
      );

      activity.init(owner);
      verify(internalTicker.start());

      internalOnTickCallback!(const Duration(milliseconds: 200));
      expect(ownerMetrics.pixels, 360); // 300 * 0.2 = 60 pixels in 200ms

      internalOnTickCallback!(const Duration(milliseconds: 400));
      expect(ownerMetrics.pixels, 420); // 300 * 0.2 = 60 pixels in 200ms

      internalOnTickCallback!(const Duration(milliseconds: 500));
      expect(ownerMetrics.pixels, 450); // 300 * 0.1 = 30 pixels in 100ms

      internalOnTickCallback!(const Duration(milliseconds: 800));
      expect(ownerMetrics.pixels, 540); // 300 * 0.3 = 90 pixels in 300ms

      internalOnTickCallback!(const Duration(milliseconds: 1000));
      expect(ownerMetrics.pixels, 600); // 300 * 0.2 = 60 pixels in 200ms
    });

    test(
      'Should start an idle activity when it reaches destination',
      () {
        final _ = SettlingSheetActivity(
          destination: const SheetAnchor.proportional(1),
          velocity: 300,
        )..init(owner);

        ownerMetrics.maybePixels = 540;
        internalOnTickCallback!(const Duration(milliseconds: 1000));
        verify(owner.goIdle());
      },
    );

    test('Should absorb viewport changes', () {
      final activity = SettlingSheetActivity.withDuration(
        const Duration(milliseconds: 300),
        destination: const SheetAnchor.proportional(1),
      )..init(owner);

      expect(activity.velocity, 1000); // (300 pixels / 0.3s) = 1000 pixels/s

      internalOnTickCallback!(const Duration(milliseconds: 50));
      expect(ownerMetrics.pixels, 350); // 1000 * 0.05 = 50 pixels in 50ms

      final oldViewportInsets = ownerMetrics.viewportInsets;
      final oldContentSize = ownerMetrics.contentSize;
      // Show the on-screen keyboard.
      ownerMetrics.maybeViewportInsets = const EdgeInsets.only(bottom: 30);
      activity.didChangeViewportDimensions(null);
      activity.didChangeViewportInsets(oldViewportInsets);
      activity.didChangeContentSize(oldContentSize);
      activity.finalizePosition(oldContentSize, null, oldViewportInsets);
      expect(ownerMetrics.pixels, 320,
          reason: 'Visual position should not change when viewport changes.');
      expect(activity.velocity, 1120, // 280 pixels / 0.25s = 1120 pixels/s
          reason: 'Velocity should be updated when viewport changes.');

      internalOnTickCallback!(const Duration(milliseconds: 100));
      expect(ownerMetrics.pixels, 376); // 1120 * 0.05 = 56 pixels in 50ms
    });
  });

  group('IdleSheetActivity', () {
    test('should maintain previous position when keyboard appears', () {
      final (ownerMetrics, owner) = createMockSheetPosition(
        pixels: 450,
        minPosition: const SheetAnchor.proportional(0.5),
        maxPosition: const SheetAnchor.proportional(1),
        contentSize: const Size(400, 850),
        viewportSize: const Size(400, 900),
        viewportInsets: const EdgeInsets.only(bottom: 50),
        devicePixelRatio: 1,
        physics: kDefaultSheetPhysics,
      );

      final activity = IdleSheetActivity()..init(owner);
      const oldContentSize = Size(400, 900);
      const oldViewportInsets = EdgeInsets.zero;
      activity
        ..didChangeContentSize(oldContentSize)
        ..didChangeViewportDimensions(oldContentSize)
        ..didChangeViewportInsets(oldViewportInsets)
        ..finalizePosition(oldContentSize, null, oldViewportInsets);
      expect(ownerMetrics.pixels, 425);
    });

    test(
      'should maintain previous position when content size changes, '
      'without animation if gap is small',
      () {
        final (ownerMetrics, owner) = createMockSheetPosition(
          pixels: 300,
          minPosition: const SheetAnchor.proportional(0.5),
          maxPosition: const SheetAnchor.proportional(1),
          contentSize: const Size(400, 580),
          viewportSize: const Size(400, 900),
          viewportInsets: EdgeInsets.zero,
          devicePixelRatio: 1,
          physics: kDefaultSheetPhysics,
        );

        final activity = IdleSheetActivity()..init(owner);
        const oldContentSize = Size(400, 600);
        activity
          ..didChangeContentSize(oldContentSize)
          ..finalizePosition(oldContentSize, null, null);
        expect(ownerMetrics.pixels, 290);
        // Still in the idle activity.
        verifyNever(owner.beginActivity(any));
      },
    );

    test(
      'should maintain previous position when content size changes, '
      'with animation if gap is large',
      () {
        final (ownerMetrics, owner) = createMockSheetPosition(
          pixels: 300,
          minPosition: const SheetAnchor.proportional(0.5),
          maxPosition: const SheetAnchor.proportional(1),
          contentSize: const Size(400, 500),
          viewportSize: const Size(400, 900),
          viewportInsets: EdgeInsets.zero,
          devicePixelRatio: 1,
          physics: kDefaultSheetPhysics,
        );

        final activity = IdleSheetActivity()..init(owner);
        const oldContentSize = Size(400, 600);
        activity
          ..didChangeContentSize(oldContentSize)
          ..finalizePosition(oldContentSize, null, null);
        expect(ownerMetrics.pixels, 300);
        verify(
          owner.animateTo(
            const SheetAnchor.proportional(0.5),
            duration: anyNamed('duration'),
            curve: anyNamed('curve'),
          ),
        );
      },
    );
  });
}

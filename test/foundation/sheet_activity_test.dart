import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

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
          minPixels: 300,
          maxPixels: 700,
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
        minPixels: 300,
        maxPixels: 900,
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
      verify(owner.setPixels(300));

      when(controller.value).thenReturn(0.25);
      activity.onAnimationTick();
      verify(owner.setPixels(450));

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
        maxPixels: 850,
        viewportInsets: const EdgeInsets.only(bottom: 50),
        contentSize: const Size(400, 850),
      );
      activity.didChangeViewportDimensions(null, oldViewportInsets);
      activity.didChangeContentSize(oldContentSize);
      activity.didFinalizeDimensions(oldContentSize, null, oldViewportInsets);
      verify(owner.setPixels(400));
      expect(metrics.viewPixels, 450,
          reason: 'Visual position should not change when viewport changes.');

      when(controller.value).thenReturn(0.5);
      activity.onAnimationTick();
      verify(owner.setPixels(550));

      when(controller.value).thenReturn(0.75);
      activity.onAnimationTick();
      verify(owner.setPixels(700));

      when(controller.value).thenReturn(1.0);
      activity.onAnimationTick();
      verify(owner.setPixels(850));
    });
  });
}

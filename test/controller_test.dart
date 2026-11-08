import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('SheetController.jumpTo', () {
    late SheetController controller;

    setUp(() => controller = SheetController());

    tearDown(() => controller.dispose());

    Widget boilerplate({required double height}) {
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: height,
          child: SheetViewport(
            child: Sheet(
              key: Key('sheet'),
              controller: controller,
              initialOffset: SheetOffset(1),
              snapGrid: SheetSnapGrid(
                snaps: [
                  SheetOffset.proportionalToViewport(0.2),
                  SheetOffset(1),
                ],
              ),
              child: SizedBox.fromSize(size: Size.fromHeight(300)),
            ),
          ),
        ),
      );
    }

    testWidgets('moves the sheet immediately without an animation', (
      tester,
    ) async {
      await tester.pumpWidget(boilerplate(height: 600));

      controller.jumpTo(SheetOffset.proportionalToViewport(0.5));

      expect(controller.metrics?.offset, 300);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump();
      expect(tester.getRect(find.byId('sheet')).top, 300);
    });

    testWidgets('keeps resolving the target when the viewport changes', (
      tester,
    ) async {
      await tester.pumpWidget(boilerplate(height: 600));
      controller.jumpTo(SheetOffset.proportionalToViewport(0.5));
      await tester.pump();

      await tester.pumpWidget(boilerplate(height: 500));

      expect(controller.metrics?.offset, 250);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(Duration(seconds: 1));
      expect(controller.metrics?.offset, 250);
    });

    testWidgets('completes the future of an animation it interrupts', (
      tester,
    ) async {
      await tester.pumpWidget(boilerplate(height: 600));
      var isDone = false;
      unawaited(
        controller
            .animateTo(SheetOffset.proportionalToViewport(0.2))
            .then((_) => isDone = true),
      );
      await tester.pump();
      await tester.pump(Duration(milliseconds: 50));

      controller.jumpTo(SheetOffset.proportionalToViewport(0.5));
      await tester.pump();

      expect(isDone, isTrue);
      expect(controller.metrics?.offset, 300);
    });

    testWidgets('lets a later drag take over', (tester) async {
      await tester.pumpWidget(boilerplate(height: 600));
      controller.jumpTo(SheetOffset.proportionalToViewport(0.5));
      await tester.pump();

      await tester.fling(find.byId('sheet'), Offset(0, 50), 1000);
      await tester.pumpAndSettle();

      expect(controller.metrics?.offset, 120);
    });
  });
}

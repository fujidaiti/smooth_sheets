import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';

import '../src/keyboard_inset_simulation.dart';

class _TestApp extends StatelessWidget {
  const _TestApp({
    this.useMaterial = false,
    required this.child,
  });

  final bool useMaterial;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (useMaterial) {
      return MaterialApp(
        home: child,
      );
    } else {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: child,
        ),
      );
    }
  }
}

class _TestSheetContent extends StatelessWidget {
  const _TestSheetContent({
    this.height = 500,
  });

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.white,
    );
  }
}

void main() {
  testWidgets('Inherited controller should be attached', (tester) async {
    final controller = SheetController();
    await tester.pumpWidget(
      SheetControllerScope(
        controller: controller,
        child: const _TestApp(
          child: SheetViewport(
            child: DraggableSheet(
              child: _TestSheetContent(),
            ),
          ),
        ),
      ),
    );

    expect(controller.hasClient, isTrue,
        reason: 'The controller should have a client.');
  });

  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/14
  testWidgets('Opening keyboard does not interrupt sheet animation',
      (tester) async {
    final controller = SheetController();
    final sheetKey = GlobalKey();
    final keyboardSimulationKey = GlobalKey<KeyboardInsetSimulationState>();

    await tester.pumpWidget(
      _TestApp(
        useMaterial: true,
        child: KeyboardInsetSimulation(
          key: keyboardSimulationKey,
          keyboardHeight: 200,
          child: SheetViewport(
            child: DraggableSheet(
              key: sheetKey,
              controller: controller,
              minPosition: const SheetAnchor.pixels(200),
              initialPosition: const SheetAnchor.pixels(200),
              child: const Material(
                child: _TestSheetContent(
                  height: 500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(controller.metrics.pixels, 200,
        reason: 'The sheet should be at the initial position.');
    expect(controller.metrics.minPixels < controller.metrics.maxPixels, isTrue,
        reason: 'The sheet should be draggable.');

    // Start animating the sheet to the max position.
    unawaited(
      controller.animateTo(
        const SheetAnchor.proportional(1),
        duration: const Duration(milliseconds: 250),
      ),
    );
    // Then, show the keyboard while the animation is running.
    unawaited(
      keyboardSimulationKey.currentState!
          .showKeyboard(const Duration(milliseconds: 250)),
    );
    await tester.pumpAndSettle();
    expect(MediaQuery.viewInsetsOf(sheetKey.currentContext!).bottom, 200,
        reason: 'The keyboard should be fully shown.');
    expect(
      controller.metrics.pixels,
      controller.metrics.maxPixels,
      reason: 'After the keyboard is fully shown, '
          'the entire sheet should also be visible.',
    );
  });

  group('SheetKeyboardDismissible', () {
    late FocusNode focusNode;
    late ScrollController scrollController;
    late Widget testWidget;

    setUp(() {
      focusNode = FocusNode();
      scrollController = ScrollController();
      testWidget = _TestApp(
        useMaterial: true,
        child: SheetKeyboardDismissible(
          dismissBehavior: const SheetKeyboardDismissBehavior.onDrag(
            isContentScrollAware: true,
          ),
          child: SheetViewport(
            child: DraggableSheet(
              child: Material(
                child: TextField(
                  focusNode: focusNode,
                  scrollController: scrollController,
                  maxLines: 2,
                ),
              ),
            ),
          ),
        ),
      );
    });

    tearDown(() {
      focusNode.dispose();
      scrollController.dispose();
    });

    testWidgets('should dismiss the keyboard when dragging', (tester) async {
      await tester.pumpWidget(testWidget);

      final textField = find.byType(TextField);
      await tester.showKeyboard(textField);
      expect(focusNode.hasFocus, isTrue,
          reason: 'The keyboard should be shown.');

      await tester.drag(textField, const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse,
          reason: 'Downward dragging should dismiss the keyboard.');
    });

    testWidgets('should dismiss the keyboard when scrolling', (tester) async {
      await tester.pumpWidget(testWidget);

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Hello, world! ' * 100);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue,
          reason: 'The keyboard should be shown.');
      expect(scrollController.position.extentBefore, greaterThan(0),
          reason: 'The text field should be able to scroll downwards.');

      await tester.drag(textField, const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse,
          reason: 'Downward dragging should dismiss the keyboard.');
    });
  });
}

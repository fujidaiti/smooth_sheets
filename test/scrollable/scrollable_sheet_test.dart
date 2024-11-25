import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_controller.dart';
import 'package:smooth_sheets/src/foundation/sheet_position_scope.dart';
import 'package:smooth_sheets/src/scrollable/scrollable_sheet_position.dart';
import 'package:smooth_sheets/src/scrollable/sheet_content_scroll_position.dart';

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
    super.key,
    this.height = 500,
    this.itemCount = 30,
    // Disable the snapping effect by default in tests.
    this.onTapItem,
  });

  final double? height;
  final int itemCount;
  final void Function(int index)? onTapItem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.white,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: List.generate(
            itemCount,
            (index) => ListTile(
              title: Text('Item $index'),
              onTap: onTapItem != null ? () => onTapItem!(index) : null,
            ),
          ),
        ),
      ),
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
            child: ScrollableSheet(
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
            child: ScrollableSheet(
              key: sheetKey,
              controller: controller,
              minPosition: const SheetAnchor.pixels(200),
              initialPosition: const SheetAnchor.pixels(200),
              child: const _TestSheetContent(height: 500),
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
    // Then, show the keyboard while the sheet is animating.
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

  group('Press-and-hold gesture should stop momentum scrolling', () {
    // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/190
    testWidgets(
      'in a plain ListView',
      (tester) async {
        const targetKey = Key('Target');
        final controller = SheetController();
        late ScrollController scrollController;

        await tester.pumpWidget(
          _TestApp(
            child: SheetViewport(
              child: ScrollableSheet(
                controller: controller,
                child: Builder(
                  builder: (context) {
                    // TODO(fujita): Refactor this line after #116 is resolved.
                    scrollController = PrimaryScrollController.of(context);
                    return _TestSheetContent(
                      key: targetKey,
                      itemCount: 1000,
                      height: null,
                      // The items need to be clickable to cause the issue.
                      onTapItem: (index) {},
                    );
                  },
                ),
              ),
            ),
          ),
        );

        const dragDistance = 200.0;
        const flingSpeed = 2000.0;
        await tester.fling(
          find.byKey(targetKey),
          const Offset(0, -1 * dragDistance), // Fling up
          flingSpeed,
        );

        final offsetAfterFling = scrollController.offset;
        // Don't know why, but we need to call `pump` at least 2 times
        // to forward the animation clock.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        final offsetBeforePress = scrollController.offset;
        expect(offsetBeforePress, greaterThan(offsetAfterFling),
            reason: 'Momentum scrolling should be in progress.');

        // Press and hold the finger on the target widget.
        await tester.press(find.byKey(targetKey));
        // Wait for the momentum scrolling to stop.
        await tester.pumpAndSettle();
        final offsetAfterPress = scrollController.offset;
        expect(
          offsetAfterPress,
          equals(offsetBeforePress),
          reason: 'Momentum scrolling should be stopped immediately '
              'by pressing and holding.',
        );
      },
    );

    // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/214
    testWidgets('in a PageView with multiple ListViews', (tester) async {
      late final ScrollController scrollController;

      await tester.pumpWidget(
        _TestApp(
          child: SheetViewport(
            child: ScrollableSheet(
              child: Builder(
                builder: (context) {
                  // TODO(fujita): Refactor this line after #116 is resolved.
                  scrollController = PrimaryScrollController.of(context);
                  return Material(
                    child: PageView(
                      controller: PageController(),
                      children: [
                        for (var i = 0; i < 2; i++)
                          ListView.builder(
                            key: Key('ListView #$i'),
                            itemCount: 100,
                            itemBuilder: (context, index) {
                              return ListTile(
                                onTap: () {},
                                title: Text('Item $index'),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      const listViewKey = Key('ListView #0');
      const dragDistance = 200.0;
      const flingSpeed = 2000.0;
      await tester.fling(
        find.byKey(listViewKey),
        const Offset(0, -1 * dragDistance), // Fling up
        flingSpeed,
      );

      final offsetAfterFling = scrollController.offset;
      // Don't know why, but we need to call `pump` at least 2 times
      // to forward the animation clock.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final offsetBeforePress = scrollController.offset;
      expect(offsetBeforePress, greaterThan(offsetAfterFling),
          reason: 'Momentum scrolling should be in progress.');

      // Press and hold the finger on the target widget.
      await tester.press(find.byKey(listViewKey));
      // Wait for the momentum scrolling to stop.
      await tester.pumpAndSettle();
      final offsetAfterPress = scrollController.offset;
      expect(
        offsetAfterPress,
        equals(offsetBeforePress),
        reason: 'Momentum scrolling should be stopped immediately '
            'by pressing and holding.',
      );
    });
  });

  group('SheetKeyboardDismissible', () {
    late FocusNode focusNode;
    late Widget testWidget;

    setUp(() {
      focusNode = FocusNode();
      testWidget = _TestApp(
        useMaterial: true,
        child: SheetKeyboardDismissible(
          dismissBehavior: const SheetKeyboardDismissBehavior.onDrag(
            isContentScrollAware: true,
          ),
          child: SheetViewport(
            child: ScrollableSheet(
              child: Material(
                child: Column(
                  children: [
                    TextField(focusNode: focusNode),
                    Expanded(
                      child: ListView(
                        children: List.generate(
                          30,
                          (index) => ListTile(
                            title: Text('Item $index'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });

    tearDown(() {
      focusNode.dispose();
    });

    testWidgets('should dismiss the keyboard when dragging', (tester) async {
      await tester.pumpWidget(testWidget);

      await tester.showKeyboard(find.byType(TextField));
      expect(focusNode.hasFocus, isTrue,
          reason: 'The keyboard should be shown.');

      await tester.drag(find.byType(ListView), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse,
          reason: 'Downward dragging should dismiss the keyboard.');
    });

    testWidgets('should dismiss the keyboard when scrolling', (tester) async {
      await tester.pumpWidget(testWidget);

      final textField = find.byType(TextField).first;
      await tester.showKeyboard(textField);
      expect(focusNode.hasFocus, isTrue,
          reason: 'The keyboard should be shown.');

      await tester.drag(find.byType(ListView), const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse,
          reason: 'Upward scrolling should dismiss the keyboard.');
    });
  });

  // Regression tests for:
  // - https://github.com/fujidaiti/smooth_sheets/issues/207
  // - https://github.com/fujidaiti/smooth_sheets/issues/212
  group('Infinite ballistic scroll activity test', () {
    late ScrollController scrollController;
    late ScrollableSheetPosition sheetPosition;
    late Widget testWidget;

    setUp(() {
      testWidget = SheetViewport(
        child: ScrollableSheet(
          child: Builder(
            builder: (context) {
              scrollController = PrimaryScrollController.of(context);
              sheetPosition = SheetPositionScope.of(context);
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: 1200,
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('top edge', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      expect(scrollController.position.pixels, 0);

      // Start a ballistic animation from a position extremely close to,
      // but not equal, to the initial position.
      scrollController.position.correctPixels(-0.000000001);
      sheetPosition.goBallisticWithScrollPosition(
        velocity: 0,
        scrollPosition: scrollController.position as SheetContentScrollPosition,
      );
      await tester.pumpAndSettle();
      expect(scrollController.position.pixels, 0);
      expect(sheetPosition.activity, isA<IdleSheetActivity>(),
          reason: 'Should not enter an infinite recursion '
              'of BallisticScrollDrivenSheetActivity');
    });

    testWidgets('bottom edge', (tester) async {
      await tester.pumpWidget(testWidget);
      scrollController.jumpTo(600.0);
      await tester.pumpAndSettle();
      expect(scrollController.position.extentAfter, 0,
          reason: 'Ensure that the scroll view cannot be scrolled anymore');

      // Start a ballistic animation from a position extremely close to,
      // but not equal, to the current position.
      scrollController.position.correctPixels(600.000000001);
      sheetPosition.goBallisticWithScrollPosition(
        velocity: 0,
        scrollPosition: scrollController.position as SheetContentScrollPosition,
      );
      await tester.pumpAndSettle();
      expect(scrollController.position.pixels, 600.0);
      expect(sheetPosition.activity, isA<IdleSheetActivity>(),
          reason: 'Should not enter an infinite recursion '
              'of BallisticScrollDrivenSheetActivity');
    });
  });
}

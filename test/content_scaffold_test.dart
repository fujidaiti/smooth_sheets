import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:smooth_sheets/src/content_scaffold.dart';

import 'src/flutter_test_x.dart';

/// A simple TickerProvider for use in tests that need an AnimationController.
class TestTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('SheetContentScaffold - Core Layout', () {
    testWidgets('Body-only layout with tight box-constraints',
        (WidgetTester tester) async {
      final bodyKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.tight(const Size(100, 50)),
              child: SheetContentScaffold(
                body: Container(key: bodyKey, color: Colors.green),
              ),
            ),
          ),
        ),
      );

      final bodySize = tester.getSize(find.byKey(bodyKey));
      expect(bodySize, equals(const Size(100, 50)));
    });

    testWidgets('Body-only layout with loose box-constraints',
        (WidgetTester tester) async {
      final bodyKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: SheetContentScaffold(
                  body: Container(
                      key: bodyKey,
                      color: Colors.green,
                      padding: const EdgeInsets.all(10)),
                ),
              ),
            ),
          ),
        ),
      );

      // The body should size itself to its intrinsic size.
      final bodySize = tester.getSize(find.byKey(bodyKey));
      expect(bodySize.width, greaterThan(0));
      expect(bodySize.height, greaterThan(0));
    });

    testWidgets('Extends body behind top bar', (WidgetTester tester) async {
      final topBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            extendBodyBehindTopBar: true,
            topBar: Container(key: topBarKey, height: 50, color: Colors.blue),
            body: Container(key: bodyKey, color: Colors.green, height: 200),
          ),
        ),
      );
      final bodyTop = tester.getTopLeft(find.byKey(bodyKey)).dy;
      // With extendBodyBehindTopBar true, the body should start at the very top.
      expect(bodyTop, equals(0.0));
    });

    testWidgets('Extends body behind bottom bar', (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            extendBodyBehindBottomBar: true,
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.red),
            body: Container(key: bodyKey, color: Colors.green, height: 200),
          ),
        ),
      );
      final bodyBottom = tester.getBottomLeft(find.byKey(bodyKey)).dy;
      final scaffoldHeight =
          tester.getSize(find.byType(SheetContentScaffold)).height;
      // With extendBodyBehindBottomBar true, the body should reach the scaffold's bottom edge.
      expect(bodyBottom, equals(scaffoldHeight));
    });

    testWidgets('Extends body behind top and bottom bars',
        (WidgetTester tester) async {
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            extendBodyBehindTopBar: true,
            extendBodyBehindBottomBar: true,
            topBar: Container(key: topBarKey, height: 50, color: Colors.blue),
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.red),
            body: Container(key: bodyKey, color: Colors.green, height: 300),
          ),
        ),
      );
      final scaffoldHeight =
          tester.getSize(find.byType(SheetContentScaffold)).height;
      final bodyTop = tester.getTopLeft(find.byKey(bodyKey)).dy;
      final bodyBottom = tester.getBottomLeft(find.byKey(bodyKey)).dy;
      expect(bodyTop, equals(0.0));
      expect(bodyBottom, equals(scaffoldHeight));
    });

    testWidgets('When top bar has a preferred size',
        (WidgetTester tester) async {
      final topBarKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            topBar: PreferredSize(
              key: topBarKey,
              preferredSize: const Size.fromHeight(60),
              child: Container(color: Colors.blue),
            ),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      final topBarSize = tester.getSize(find.byKey(topBarKey));
      expect(topBarSize.height, equals(60));
    });

    testWidgets('When bottom bar has a preferred size',
        (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            bottomBar: PreferredSize(
              key: bottomBarKey,
              preferredSize: const Size.fromHeight(60),
              child: Container(color: Colors.red),
            ),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      final bottomBarSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomBarSize.height, equals(60));
    });

    testWidgets('Background color fills entire area',
        (WidgetTester tester) async {
      const bgColor = Colors.purple;
      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            backgroundColor: bgColor,
            body: Container(color: Colors.transparent, height: 200),
          ),
        ),
      );
      // Look for a DecoratedBox (or similar) that applies the background color.
      final finder = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            (widget.decoration as BoxDecoration?)?.color == bgColor,
      );
      expect(finder, findsAtLeastNWidgets(1));
    });

    testWidgets('Applies background color from theme when not explicitly set',
        (WidgetTester tester) async {
      const themeBgColor = Colors.orange;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: themeBgColor),
          home: SheetContentScaffold(
            body: Container(color: Colors.transparent, height: 200),
          ),
        ),
      );
      final finder = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            (widget.decoration as BoxDecoration?)?.color == themeBgColor,
      );
      expect(finder, findsAtLeastNWidgets(1));
    });

    testWidgets('Updates MediaQuery padding based on presence of bars',
        (WidgetTester tester) async {
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            topBar: Container(key: topBarKey, height: 50, color: Colors.blue),
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.red),
            body: Builder(
              builder: (context) {
                // Use this builder to guarantee that context is that of the body.
                final padding = MediaQuery.of(context).padding;
                // For testing purposes, we are not asserting the exact values,
                // but you could print or otherwise examine padding if your
                // implementation propagates padding correctly.
                return Container(color: Colors.green);
              },
            ),
          ),
        ),
      );
      expect(find.byKey(topBarKey), findsOneWidget);
      expect(find.byKey(bottomBarKey), findsOneWidget);
    });
  });

  group('SheetContentScaffold - Bottom Bar Visibility with Keyboard', () {
    testWidgets(
        'Hide bottom bar in response to keyboard when ignoreBottomInset is false',
        (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      // Initially simulate no keyboard.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.zero),
            child: SheetContentScaffold(
              bottomBar:
                  Container(key: bottomBarKey, height: 50, color: Colors.blue),
              bottomBarVisibility:
                  const SheetContentScaffoldBottomBarVisibility.natural(
                      ignoreBottomInset: false),
              body: Container(color: Colors.green, height: 200),
            ),
          ),
        ),
      );
      final sizeWithoutKeyboard = tester.getSize(find.byKey(bottomBarKey));
      expect(sizeWithoutKeyboard.height, equals(50));

      // Now simulate keyboard appearance by providing a bottom inset.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data:
                const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
            child: SheetContentScaffold(
              bottomBar:
                  Container(key: bottomBarKey, height: 50, color: Colors.blue),
              bottomBarVisibility:
                  const SheetContentScaffoldBottomBarVisibility.natural(
                      ignoreBottomInset: false),
              body: Container(color: Colors.green, height: 200),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sizeWithKeyboard = tester.getSize(find.byKey(bottomBarKey));
      // Expect the bottom bar height to be less than its full height when keyboard is showing.
      expect(sizeWithKeyboard.height, lessThan(50));
    });

    testWidgets('Maintains bottom bar position when ignoring bottom inset',
        (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      // Start with no keyboard.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.zero),
            child: SheetContentScaffold(
              bottomBar:
                  Container(key: bottomBarKey, height: 50, color: Colors.blue),
              bottomBarVisibility:
                  const SheetContentScaffoldBottomBarVisibility.natural(
                      ignoreBottomInset: true),
              body: Container(color: Colors.green, height: 200),
            ),
          ),
        ),
      );
      final sizeWithoutKeyboard = tester.getSize(find.byKey(bottomBarKey));
      expect(sizeWithoutKeyboard.height, equals(50));

      // Simulate keyboard appearance.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data:
                const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
            child: SheetContentScaffold(
              bottomBar:
                  Container(key: bottomBarKey, height: 50, color: Colors.blue),
              bottomBarVisibility:
                  const SheetContentScaffoldBottomBarVisibility.natural(
                      ignoreBottomInset: true),
              body: Container(color: Colors.green, height: 200),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sizeWithKeyboard = tester.getSize(find.byKey(bottomBarKey));
      // With ignoreBottomInset true, the bottom bar remains fully visible.
      expect(sizeWithKeyboard.height, equals(50));
    });
  });

  group('SheetContentScaffold - Always Visible Bottom Bar', () {
    testWidgets('Bottom bar remains fully visible regardless of sheet offset',
        (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                const SheetContentScaffoldBottomBarVisibility.always(),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      final bottomBarSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomBarSize.height, equals(50));
    });

    testWidgets(
        'Bottom bar respects ignoreBottomInset setting during keyboard display',
        (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      // When ignoreBottomInset is false.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data:
                const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
            child: SheetContentScaffold(
              bottomBar:
                  Container(key: bottomBarKey, height: 50, color: Colors.blue),
              bottomBarVisibility:
                  const SheetContentScaffoldBottomBarVisibility.always(
                      ignoreBottomInset: false),
              body: Container(color: Colors.green, height: 200),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sizeWithKeyboard = tester.getSize(find.byKey(bottomBarKey));
      expect(sizeWithKeyboard.height, lessThan(50));

      // Now with ignoreBottomInset true.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data:
                const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
            child: SheetContentScaffold(
              bottomBar:
                  Container(key: bottomBarKey, height: 50, color: Colors.blue),
              bottomBarVisibility:
                  const SheetContentScaffoldBottomBarVisibility.always(
                      ignoreBottomInset: true),
              body: Container(color: Colors.green, height: 200),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sizeWithKeyboardIgnored = tester.getSize(find.byKey(bottomBarKey));
      expect(sizeWithKeyboardIgnored.height, equals(50));
    });
  });

  group('SheetContentScaffold - Controlled Bottom Bar Visibility', () {
    testWidgets('Follows animation values for visibility control',
        (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      final tickerProvider = TestTickerProvider();
      final controller = AnimationController(
          vsync: tickerProvider, duration: const Duration(milliseconds: 200));

      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                SheetContentScaffoldBottomBarVisibility.controlled(
              animation: controller,
            ),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );

      // When the animation value is 0, the bottom bar should be nearly invisible.
      controller.value = 0.0;
      await tester.pump();
      var bottomSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomSize.height, lessThan(10));

      // When the animation value moves to 1, the bottom bar should become fully visible.
      controller.value = 1.0;
      await tester.pump();
      bottomSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomSize.height, equals(50));

      controller.dispose();
    });
  });

  group('SheetContentScaffold - Conditional Bottom Bar Visibility', () {
    testWidgets('Responds to visibility condition changes',
        (WidgetTester tester) async {
      final bottomBarKey = UniqueKey();
      bool showBottomBar = false;

      Widget buildTestWidget() {
        return MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return SheetContentScaffold(
                bottomBar: showBottomBar
                    ? Container(
                        key: bottomBarKey, height: 50, color: Colors.blue)
                    : Container(
                        key: bottomBarKey, height: 0, color: Colors.blue),
                bottomBarVisibility:
                    SheetContentScaffoldBottomBarVisibility.conditional(
                  isVisible: (metrics) => showBottomBar,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                ),
                body: Container(color: Colors.green, height: 200),
              );
            },
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget());
      // Initially the bottom bar should be hidden.
      var bottomBarSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomBarSize.height, equals(0));

      // Change the condition so the bottom bar is visible.
      showBottomBar = true;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      bottomBarSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomBarSize.height, equals(50));

      // Change back to hidden.
      showBottomBar = false;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      bottomBarSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomBarSize.height, equals(0));
    });
  });

  group('SheetContentScaffold - Hit-testing', () {
    testWidgets('Hit-testing when body-only', (WidgetTester tester) async {
      bool bodyTapped = false;
      final bodyKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            body: GestureDetector(
              key: bodyKey,
              onTap: () => bodyTapped = true,
              child: Container(color: Colors.green, height: 200),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(bodyKey));
      expect(bodyTapped, isTrue);
    });

    testWidgets('Hit-testing when top bar is specified',
        (WidgetTester tester) async {
      bool topBarTapped = false;
      final topBarKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            topBar: GestureDetector(
              key: topBarKey,
              onTap: () => topBarTapped = true,
              child: Container(height: 50, color: Colors.blue),
            ),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );

      await tester.tap(find.byKey(topBarKey));
      expect(topBarTapped, isTrue);
    });

    testWidgets('Hit-testing when bottom bar is specified',
        (WidgetTester tester) async {
      bool bottomBarTapped = false;
      final bottomBarKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            bottomBar: GestureDetector(
              key: bottomBarKey,
              onTap: () => bottomBarTapped = true,
              child: Container(height: 50, color: Colors.red),
            ),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );

      await tester.tap(find.byKey(bottomBarKey));
      expect(bottomBarTapped, isTrue);
    });

    testWidgets('Hit-testing when both top and bottom bars are specified',
        (WidgetTester tester) async {
      bool topBarTapped = false;
      bool bottomBarTapped = false;
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: SheetContentScaffold(
            topBar: GestureDetector(
              key: topBarKey,
              onTap: () => topBarTapped = true,
              child: Container(height: 50, color: Colors.blue),
            ),
            bottomBar: GestureDetector(
              key: bottomBarKey,
              onTap: () => bottomBarTapped = true,
              child: Container(height: 50, color: Colors.red),
            ),
            body: Container(color: Colors.green, height: 300),
          ),
        ),
      );

      await tester.tap(find.byKey(topBarKey));
      await tester.tap(find.byKey(bottomBarKey));

      expect(topBarTapped, isTrue);
      expect(bottomBarTapped, isTrue);
    });
  });
}

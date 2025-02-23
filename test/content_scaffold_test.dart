import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';

/// A simple TickerProvider for use in tests that need an AnimationController.
class TestTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('SheetContentScaffold - Core Layout', () {
    ({Widget testWidget}) boilerplate({
      SheetLayoutSpec? parentLayoutSpec,
      required WidgetBuilder builder,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(
          viewInsets: parentLayoutSpec?.viewportInsets ?? EdgeInsets.zero,
        ),
        child: SheetMediaQuery(
          layoutSpec: parentLayoutSpec ??
              SheetLayoutSpec(
                viewportSize: testScreenSize,
                viewportPadding: EdgeInsets.zero,
                viewportInsets: EdgeInsets.zero,
                resizeContentToAvoidBottomInset: false,
              ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Builder(builder: builder),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets('Body-only layout with tight box-constraints', (tester) async {
      final scaffoldKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.tight(testScreenSize),
            child: SheetContentScaffold(
              key: scaffoldKey,
              body: SizedBox.shrink(key: bodyKey),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
      expect(tester.getSize(find.byKey(bodyKey)), testScreenSize);
    });

    testWidgets('Body-only layout with loose box-constraints', (tester) async {
      final scaffoldKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints.loose(testScreenSize),
            child: SheetContentScaffold(
              key: scaffoldKey,
              body: SizedBox(key: bodyKey, height: 200),
            ),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getSize(find.byKey(scaffoldKey)),
        Size(testScreenSize.width, 200),
      );
      expect(
        tester.getLocalRect(
          find.byKey(bodyKey),
          ancestor: find.byKey(scaffoldKey),
        ),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets(
      'TopBar-Body layout with tight box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.tight(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                body: SizedBox.shrink(key: bodyKey),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            50,
            testScreenSize.width,
            testScreenSize.height - 50,
          ),
        );
      },
    );

    testWidgets(
      'TopBar-Body layout with loose box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.loose(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                body: Container(key: bodyKey, height: 200),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(scaffoldKey)),
          Size(testScreenSize.width, 250),
        );
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 50, testScreenSize.width, 200),
        );
      },
    );

    testWidgets(
      'Body-BottomBar layout with tight box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.tight(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: SizedBox.shrink(key: bodyKey),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, testScreenSize.height - 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 50,
            testScreenSize.width,
            50,
          ),
        );
      },
    );

    testWidgets(
      'Body-BottomBar layout with loose box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.loose(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: Container(key: bodyKey, height: 200),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(scaffoldKey)),
          Size(testScreenSize.width, 250),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 200, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 200),
        );
      },
    );

    testWidgets(
      'TopBar-Body-BottomBar layout with tight box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.tight(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: SizedBox.shrink(key: bodyKey),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(tester.getSize(find.byKey(scaffoldKey)), testScreenSize);
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            testScreenSize.height - 50,
            testScreenSize.width,
            50,
          ),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(
            0,
            50,
            testScreenSize.width,
            testScreenSize.height - 100,
          ),
        );
      },
    );

    testWidgets(
      'TopBar-Body-BottomBar layout with loose box-constraints',
      (tester) async {
        final scaffoldKey = UniqueKey();
        final topBarKey = UniqueKey();
        final bottomBarKey = UniqueKey();
        final bodyKey = UniqueKey();
        final env = boilerplate(
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints.loose(testScreenSize),
              child: SheetContentScaffold(
                key: scaffoldKey,
                topBar: Container(key: topBarKey, height: 50),
                bottomBar: Container(key: bottomBarKey, height: 50),
                body: Container(key: bodyKey, height: 200),
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(
          tester.getSize(find.byKey(scaffoldKey)),
          Size(testScreenSize.width, 300),
        );
        expect(
          tester.getLocalRect(
            find.byKey(topBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 0, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bottomBarKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 250, testScreenSize.width, 50),
        );
        expect(
          tester.getLocalRect(
            find.byKey(bodyKey),
            ancestor: find.byKey(scaffoldKey),
          ),
          Rect.fromLTWH(0, 50, testScreenSize.width, 200),
        );
      },
    );

    testWidgets('Extends body behind top bar', (tester) async {
      final topBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            extendBodyBehindTopBar: true,
            topBar: Container(key: topBarKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(topBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Extends body behind bottom bar', (tester) async {
      final bottomBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            extendBodyBehindBottomBar: true,
            bottomBar: Container(key: bottomBarKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(bottomBarKey)),
        Rect.fromLTWH(0, 150, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('Extends body behind top and bottom bars', (tester) async {
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();
      final bodyKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            extendBodyBehindTopBar: true,
            extendBodyBehindBottomBar: true,
            topBar: Container(key: topBarKey, height: 50),
            bottomBar: Container(key: bottomBarKey, height: 50),
            body: Container(key: bodyKey, height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(topBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bottomBarKey)),
        Rect.fromLTWH(0, 150, testScreenSize.width, 50),
      );
      expect(
        tester.getLocalRect(find.byKey(bodyKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 200),
      );
    });

    testWidgets('When top bar has a preferred size', (tester) async {
      final topBarKey = UniqueKey();
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          topBar: PreferredSize(
            key: topBarKey,
            preferredSize: const Size.fromHeight(60),
            child: Container(),
          ),
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(topBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 60),
      );
    });

    testWidgets('When bottom bar has a preferred size', (tester) async {
      final bottomBarKey = UniqueKey();
      final env = boilerplate(
        builder: (context) {
          return SheetContentScaffold(
            bottomBar: PreferredSize(
              key: bottomBarKey,
              preferredSize: const Size.fromHeight(60),
              child: Container(),
            ),
            body: Container(height: 200),
          );
        },
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.getLocalRect(find.byKey(bottomBarKey)),
        Rect.fromLTWH(0, 0, testScreenSize.width, 60),
      );
    });

    testWidgets('Background color fills entire area', (tester) async {
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          backgroundColor: Colors.purple,
          body: Container(height: 200),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.widget(find.byType(Material)),
        isA<Material>().having((m) => m.color, 'color', Colors.purple),
      );
    });

    testWidgets('Applies background color from theme when not explicitly set',
        (tester) async {
      final env = boilerplate(
        builder: (context) => Theme(
          data: ThemeData(
            scaffoldBackgroundColor: Colors.purple,
          ),
          child: SheetContentScaffold(
            body: Container(height: 200),
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(
        tester.widget(find.byType(Material)),
        isA<Material>().having((m) => m.color, 'color', Colors.purple),
      );
    });

    testWidgets('Updates MediaQuery padding based on presence of bars',
        (tester) async {
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();
      final env = boilerplate(
        builder: (context) => SheetContentScaffold(
          topBar: Container(key: topBarKey, height: 50, color: Colors.blue),
          bottomBar:
              Container(key: bottomBarKey, height: 50, color: Colors.red),
          body: Builder(
            builder: (context) {
              final padding = MediaQuery.of(context).padding;
              return Container(color: Colors.green);
            },
          ),
        ),
      );

      await tester.pumpWidget(env.testWidget);
      expect(find.byKey(topBarKey), findsOneWidget);
      expect(find.byKey(bottomBarKey), findsOneWidget);
    });
  });

  group('SheetContentScaffold - Bottom Bar Visibility with Keyboard', () {
    testWidgets(
        'Hide bottom bar in response to keyboard when ignoreBottomInset is false',
        (tester) async {
      final bottomBarKey = UniqueKey();
      // Initially simulate no keyboard.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                const BottomBarVisibility.natural(ignoreBottomInset: false),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      final sizeWithoutKeyboard = tester.getSize(find.byKey(bottomBarKey));
      expect(sizeWithoutKeyboard.height, equals(50));

      // Now simulate keyboard appearance by providing a bottom inset.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                const BottomBarVisibility.natural(ignoreBottomInset: false),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sizeWithKeyboard = tester.getSize(find.byKey(bottomBarKey));
      // Expect the bottom bar height to be less than its full height when keyboard is showing.
      expect(sizeWithKeyboard.height, lessThan(50));
    });

    testWidgets('Maintains bottom bar position when ignoring bottom inset',
        (tester) async {
      final bottomBarKey = UniqueKey();
      // Start with no keyboard.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                const BottomBarVisibility.natural(ignoreBottomInset: true),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      final sizeWithoutKeyboard = tester.getSize(find.byKey(bottomBarKey));
      expect(sizeWithoutKeyboard.height, equals(50));

      // Simulate keyboard appearance.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                const BottomBarVisibility.natural(ignoreBottomInset: true),
            body: Container(color: Colors.green, height: 200),
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
        (tester) async {
      final bottomBarKey = UniqueKey();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility: const BottomBarVisibility.always(),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      final bottomBarSize = tester.getSize(find.byKey(bottomBarKey));
      expect(bottomBarSize.height, equals(50));
    });

    testWidgets(
        'Bottom bar respects ignoreBottomInset setting during keyboard display',
        (tester) async {
      final bottomBarKey = UniqueKey();
      // When ignoreBottomInset is false.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                const BottomBarVisibility.always(ignoreBottomInset: false),
            body: Container(color: Colors.green, height: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sizeWithKeyboard = tester.getSize(find.byKey(bottomBarKey));
      expect(sizeWithKeyboard.height, lessThan(50));

      // Now with ignoreBottomInset true.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100)),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility:
                const BottomBarVisibility.always(ignoreBottomInset: true),
            body: Container(color: Colors.green, height: 200),
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
        (tester) async {
      final bottomBarKey = UniqueKey();
      final tickerProvider = TestTickerProvider();
      final controller = AnimationController(
          vsync: tickerProvider, duration: const Duration(milliseconds: 200));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
            bottomBar:
                Container(key: bottomBarKey, height: 50, color: Colors.blue),
            bottomBarVisibility: BottomBarVisibility.controlled(
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
    testWidgets('Responds to visibility condition changes', (tester) async {
      final bottomBarKey = UniqueKey();
      bool showBottomBar = false;

      Widget buildTestWidget() {
        return MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
            bottomBar: showBottomBar
                ? Container(key: bottomBarKey, height: 50, color: Colors.blue)
                : Container(key: bottomBarKey, height: 0, color: Colors.blue),
            bottomBarVisibility: BottomBarVisibility.conditional(
              isVisible: (metrics) => showBottomBar,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
            ),
            body: Container(color: Colors.green, height: 200),
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
    ({Widget testWidget}) boilerplate({
      required Widget body,
      Widget? topBar,
      Widget? bottomBar,
    }) {
      final testWidget = MediaQuery(
        data: MediaQueryData(),
        child: SheetMediaQuery(
          layoutSpec: SheetLayoutSpec(
            viewportSize: testScreenSize,
            viewportPadding: EdgeInsets.zero,
            viewportInsets: EdgeInsets.zero,
            resizeContentToAvoidBottomInset: false,
          ),
          child: Center(
            child: SizedBox(
              width: 600,
              height: 400,
              child: SheetContentScaffold(
                key: Key('scaffold'),
                topBar: topBar,
                bottomBar: bottomBar,
                body: body,
              ),
            ),
          ),
        ),
      );

      return (testWidget: testWidget);
    }

    testWidgets('Hit-testing when body-only', (tester) async {
      final bodyKey = UniqueKey();
      final env = boilerplate(
        body: ColoredBox(
          key: bodyKey,
          color: Colors.white,
          child: SizedBox.expand(),
        ),
      );
      await tester.pumpWidget(env.testWidget);

      tester.hitTestAt(find.byKey(bodyKey), location: Offset(100, 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Hit-testing when top bar is specified', (tester) async {
      bool topBarTapped = false;
      final topBarKey = UniqueKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
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

    testWidgets('Hit-testing when bottom bar is specified', (tester) async {
      bool bottomBarTapped = false;
      final bottomBarKey = UniqueKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
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
        (tester) async {
      bool topBarTapped = false;
      bool bottomBarTapped = false;
      final topBarKey = UniqueKey();
      final bottomBarKey = UniqueKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: SheetContentScaffold(
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

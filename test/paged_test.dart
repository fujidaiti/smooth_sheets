import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/foundation/snap_grid.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';
import 'src/matchers.dart';

void main() {
  group('PagedSheet basics', () {
    ({
      Widget testWidget,
      ValueGetter<NavigatorState> getNavigator,
      Rect Function(WidgetTester) getSheetRect,
    }) boilerplate({
      required ValueGetter<Route<dynamic>> initialRoute,
    }) {
      final navigatorKey = GlobalKey<NavigatorState>();
      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: SheetViewport(
          child: PagedSheet(
            child: Navigator(
              key: navigatorKey,
              onGenerateRoute: (_) {
                return initialRoute();
              },
            ),
          ),
        ),
      );

      return (
        testWidget: testWidget,
        getNavigator: () {
          return navigatorKey.currentState!;
        },
        getSheetRect: (tester) {
          return tester.getRect(find.byType(PagedSheet));
        },
      );
    }

    testWidgets(
      'The position before a push transition should be restored '
      'when back to that route',
      (tester) async {
        final env = boilerplate(
          initialRoute: () {
            return PagedSheetRoute(
              snapGrid: SheetSnapGrid(
                snaps: [
                  SheetOffset.absolute(100),
                  SheetOffset.relative(1),
                ],
              ),
              builder: (_) => _TestPage(
                key: Key('a'),
                height: 300,
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        await tester.fling(find.byKey(Key('a')), Offset(0, 50), 500);
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 100);

        unawaited(
          env.getNavigator().push(
                PagedSheetRoute(
                  builder: (_) => _TestPage(
                    key: Key('b'),
                    height: 500,
                  ),
                ),
              ),
        );

        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 500);

        env.getNavigator().pop();
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 100);
      },
    );

    testWidgets(
      'Each route should be able to have different initial offset',
      (tester) async {
        final env = boilerplate(
          initialRoute: () {
            return PagedSheetRoute(
              snapGrid: SheetSnapGrid.stepless(),
              initialOffset: SheetOffset.absolute(100),
              builder: (_) => _TestPage(
                key: Key('a'),
                height: 300,
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        expect(env.getSheetRect(tester).top, testScreenSize.height - 100);

        unawaited(
          env.getNavigator().push(
                PagedSheetRoute(
                  snapGrid: SheetSnapGrid.stepless(),
                  initialOffset: SheetOffset.relative(0.5),
                  builder: (_) => _TestPage(
                    key: Key('b'),
                    height: 500,
                  ),
                ),
              ),
        );

        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 250);
      },
    );

    testWidgets(
      'Each route should be able to have different snap grid',
      (tester) async {
        final env = boilerplate(
          initialRoute: () {
            return PagedSheetRoute(
              snapGrid: SheetSnapGrid(
                snaps: [
                  SheetOffset.absolute(100),
                  SheetOffset.relative(1),
                ],
              ),
              builder: (_) => _TestPage(
                key: Key('a'),
                height: 300,
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        await tester.fling(find.byKey(Key('a')), Offset(0, 50), 500);
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 100);

        unawaited(
          env.getNavigator().push(
                PagedSheetRoute(
                  snapGrid: SheetSnapGrid.stepless(),
                  builder: (_) => _TestPage(
                    key: Key('b'),
                    height: 500,
                  ),
                ),
              ),
        );

        await tester.pumpAndSettle();
        await tester.drag(find.byKey(Key('b')), Offset(0, 100));
        expect(env.getSheetRect(tester).top, testScreenSize.height - 400);
      },
    );
  });

  group('PagedSheet transition test', () {
    ({
      Widget testWidget,
      GlobalKey<NavigatorState> navigatorKey,
      VoidCallback popRoute,
      void Function(String name, double height, [Duration? duration]) pushRoute,
      Rect Function(WidgetTester) getSheetRect,
    }) boilerplate({
      required String initialRoute,
      required double initialRouteHeight,
    }) {
      final navigatorKey = GlobalKey<NavigatorState>();
      const sheetKey = Key('sheet');
      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: SheetViewport(
          child: PagedSheet(
            key: sheetKey,
            offsetInterpolationCurve: Curves.linear,
            physics: const ClampingSheetPhysics(),
            child: Navigator(
              key: navigatorKey,
              initialRoute: initialRoute,
              onGenerateRoute: (_) {
                return PagedSheetRoute(
                  builder: (_) {
                    return _TestPage(
                      key: Key(initialRoute),
                      height: initialRouteHeight,
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      return (
        testWidget: testWidget,
        navigatorKey: navigatorKey,
        pushRoute: (name, height, [duration]) {
          navigatorKey.currentState!.push(
            PagedSheetRoute<dynamic>(
              transitionDuration: duration ?? const Duration(milliseconds: 300),
              builder: (_) {
                return _TestPage(
                  key: Key(name),
                  height: height,
                );
              },
            ),
          );
        },
        popRoute: () {
          navigatorKey.currentState!.pop();
        },
        getSheetRect: (tester) {
          return tester.getRect(find.byKey(sheetKey));
        },
      );
    }

    testWidgets('On initial build', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      expect(find.byKey(Key('a')), findsOneWidget);
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 300),
      );
    });

    testWidgets('When pushing a route', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      env.pushRoute('b', 500);

      await tester.pump();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 300),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 350),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 400),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 450),
      );

      await tester.pumpAndSettle();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 500),
      );

      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);
    });

    testWidgets('When pushing a route without animation', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      env.pushRoute('b', 500, Duration.zero);

      await tester.pump();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 500),
      );

      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      env.pushRoute('b', 500);
      env.pushRoute('c', 200);

      await tester.pump();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 300),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 275),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 250),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 225),
      );

      await tester.pumpAndSettle();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 200),
      );

      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')).hitTestable(), findsNothing);
      expect(find.byKey(Key('c')), findsOneWidget);
    });

    testWidgets('When popping a route', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      env.pushRoute('b', 500);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);

      env.popRoute();
      await tester.pump();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 500),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 450),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 400),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 350),
      );

      await tester.pumpAndSettle();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 300),
      );

      expect(find.byKey(Key('a')), findsOneWidget);
      expect(find.byKey(Key('b')), findsNothing);
    });

    testWidgets('When popping a route without animation', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      env.pushRoute('b', 500, Duration.zero);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 500),
      );

      env.popRoute();
      await tester.pump();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 300),
      );

      expect(find.byKey(Key('a')), findsOneWidget);
      expect(find.byKey(Key('b')), findsNothing);
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      env.pushRoute('b', 500);
      env.pushRoute('c', 200);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')).hitTestable(), findsNothing);
      expect(find.byKey(Key('c')), findsOneWidget);

      env.popRoute();
      env.popRoute();
      await tester.pump();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 200),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 225),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 250),
      );

      await tester.pump(Duration(milliseconds: 75));
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 275),
      );

      await tester.pumpAndSettle();
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 300),
      );

      expect(find.byKey(Key('a')), findsOneWidget);
      expect(find.byKey(Key('b')), findsNothing);
      expect(find.byKey(Key('c')), findsNothing);
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(
        Theme(
          data: ThemeData(platform: TargetPlatform.iOS),
          child: env.testWidget,
        ),
      );
      env.pushRoute('b', 500);
      await tester.pumpAndSettle();

      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 500),
      );

      // Start a swipe back gesture
      final pointerLocation = Offset(5, testScreenSize.height - 250);
      final gesture = await tester.startGesture(pointerLocation);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(env.navigatorKey.currentState!.userGestureInProgress, isTrue);

      final sheetTopHistory = <double>[];
      // Move the finger toward the right side of the screen.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await gesture.moveBy(const Offset(200, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);
      // End the swipe back gesture.
      await gesture.up();
      // Then a backward transition should be performed.
      await tester.pump(Duration(milliseconds: 50));
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await tester.pump(Duration(milliseconds: 50));
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await tester.pump(Duration(milliseconds: 50));
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await tester.pump(Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('a')), findsOneWidget);
      expect(find.byKey(Key('b')), findsNothing);
      expect(sheetTopHistory, isMonotonicallyIncreasing);
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 300),
      );
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(
        Theme(
          data: ThemeData(platform: TargetPlatform.iOS),
          child: env.testWidget,
        ),
      );
      env.pushRoute('b', 500);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);

      // Start a swipe back gesture
      final pointerLocation = Offset(5, testScreenSize.height - 250);
      final gesture = await tester.startGesture(pointerLocation);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(env.navigatorKey.currentState!.userGestureInProgress, isTrue);

      final sheetTopHistory = <double>[];
      // Move the finger toward the right side of the screen.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      sheetTopHistory.add(env.getSheetRect(tester).top);

      expect(sheetTopHistory, isMonotonicallyIncreasing);
      sheetTopHistory.clear();

      // Cancel the swipe back gesture.
      await gesture.up();
      // Then a forward transition should be performed.
      await tester.pump(Duration(milliseconds: 50));
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await tester.pump(Duration(milliseconds: 50));
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await tester.pump(Duration(milliseconds: 50));
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await tester.pump(Duration(milliseconds: 50));
      sheetTopHistory.add(env.getSheetRect(tester).top);
      await tester.pumpAndSettle();

      expect(sheetTopHistory, isMonotonicallyDecreasing);
      expect(find.byKey(Key('a')), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);
      expect(
        env.getSheetRect(tester).topLeft,
        Offset(0, testScreenSize.height - 500),
      );
    });
  });
}

class _TestPage extends StatelessWidget {
  const _TestPage({
    super.key,
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: height,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'flutter_test_config.dart';
import 'src/flutter_test_x.dart';
import 'src/matchers.dart';
import 'src/test_stateful_widget.dart';

void main() {
  group('PagedSheet Basic Test - Imperative API', () {
    ({
      Widget testWidget,
      Key sheetKey,
      ValueGetter<NavigatorState> getNavigator,
      Rect Function(WidgetTester) getSheetRect,
    }) boilerplate({
      required ValueGetter<Route<dynamic>> initialRoute,
    }) {
      final navigatorKey = GlobalKey<NavigatorState>();
      const sheetKey = Key('sheet');
      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: SheetViewport(
          child: PagedSheet(
            key: sheetKey,
            navigator: Navigator(
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
        sheetKey: sheetKey,
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
                  SheetOffset(1),
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
                  initialOffset: SheetOffset(0.5),
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
                  SheetOffset(1),
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

    testWidgets(
      'Pointer events should be ignored during a transition',
      (tester) async {
        final env = boilerplate(
          initialRoute: () {
            return PagedSheetRoute(
              snapGrid: SheetSnapGrid.stepless(),
              builder: (_) => _TestPage(
                key: Key('a'),
                height: 300,
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
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

        // Forwards the transition animation by half.
        await tester.pump(const Duration(milliseconds: 150));
        await tester.tap(find.byKey(env.sheetKey));
        expect(tester.takeException(), isFlutterError);

        await tester.pumpAndSettle();
        expect(find.byKey(Key('a')).hitTestable(), findsNothing);
        expect(find.byKey(Key('b')), findsOneWidget);
      },
    );

    testWidgets(
      'Each route should be able to have different drag configuration',
      (tester) async {
        final env = boilerplate(
          initialRoute: () {
            return PagedSheetRoute(
              snapGrid: SheetSnapGrid.stepless(),
              dragConfiguration: SheetDragConfiguration(),
              builder: (_) => _TestPage(
                key: Key('a'),
                height: 300,
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        var centerLocation = tester.getCenter(find.byKey(Key('a')));
        var gesture = await tester.startGesture(centerLocation);
        await gesture.moveBy(Offset(0, 50));
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 250,
            reason: 'The first page should be draggable.');

        await gesture.up();
        await tester.pumpAndSettle();
        unawaited(
          env.getNavigator().push(
                PagedSheetRoute(
                  snapGrid: SheetSnapGrid.stepless(),
                  dragConfiguration: null,
                  builder: (_) => _TestPage(
                    key: Key('b'),
                    height: 300,
                  ),
                ),
              ),
        );
        await tester.pumpAndSettle();
        centerLocation = tester.getCenter(find.byKey(Key('b')));
        gesture = await tester.startGesture(centerLocation);
        await gesture.moveBy(Offset(0, 50));
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 300,
            reason: 'The second page should not be draggable.');
      },
    );

    testWidgets(
      'Each route should be able to have different scroll configuration',
      (tester) async {
        final env = boilerplate(
          initialRoute: () {
            return PagedSheetRoute(
              snapGrid: SheetSnapGrid.stepless(),
              scrollConfiguration: SheetScrollConfiguration(),
              builder: (_) => _TestPage(
                key: Key('a'),
                height: 300,
                isScrollable: true,
              ),
            );
          },
        );

        await tester.pumpWidget(env.testWidget);
        var centerLocation = tester.getCenter(find.byKey(Key('a')));
        var gesture = await tester.startDrag(centerLocation);
        await gesture.moveBy(Offset(0, 50));
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 250,
            reason: 'The first page should be draggable.');

        // await gesture.up();
        await tester.pumpAndSettle();
        unawaited(
          env.getNavigator().push(
                PagedSheetRoute(
                  snapGrid: SheetSnapGrid.stepless(),
                  scrollConfiguration: null,
                  builder: (_) => _TestPage(
                    key: Key('b'),
                    height: 300,
                    isScrollable: true,
                  ),
                ),
              ),
        );
        await tester.pumpAndSettle();
        centerLocation = tester.getCenter(find.byKey(Key('b')));
        gesture = await tester.startDrag(centerLocation);
        await gesture.moveBy(Offset(0, 50));
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester).top, testScreenSize.height - 300,
            reason: 'The second page should not be draggable.');
      },
    );
  });

  group('PagedSheet Basic Test - Declarative API', () {
    ({
      Widget testWidget,
      ValueNotifier<List<Page<dynamic>>> pagesNotifier,
    }) boilerplate({
      required Page<dynamic> initialPage,
    }) {
      final pagesNotifier = ValueNotifier([initialPage]);
      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: SheetViewport(
          child: PagedSheet(
            key: Key('sheet'),
            navigator: ValueListenableBuilder(
              valueListenable: pagesNotifier,
              builder: (context, pages, child) {
                return Navigator(
                  pages: pages,
                  onDidRemovePage: (page) {
                    pagesNotifier.value = [...pages]..remove(page);
                  },
                );
              },
            ),
          ),
        ),
      );

      return (
        testWidget: testWidget,
        pagesNotifier: pagesNotifier,
      );
    }

    testWidgets(
      'Each route should be able to have different initial offset',
      (tester) async {
        final env = boilerplate(
          initialPage: PagedSheetPage(
            snapGrid: SheetSnapGrid.stepless(),
            initialOffset: SheetOffset.absolute(100),
            child: _TestPage(
              key: Key('a'),
              height: 300,
            ),
          ),
        );

        await tester.pumpWidget(env.testWidget);
        expect(tester.getRect(find.byId('sheet')).top, 500);

        env.pagesNotifier.value = [
          ...env.pagesNotifier.value,
          PagedSheetPage(
            snapGrid: SheetSnapGrid.stepless(),
            initialOffset: SheetOffset(0.5),
            child: _TestPage(
              key: Key('b'),
              height: 500,
            ),
          ),
        ];
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byId('sheet')).top, 350);
      },
    );
  });

  group('PagedSheet transition test with Imperative API', () {
    ({
      Widget testWidget,
      GlobalKey<NavigatorState> navigatorKey,
      VoidCallback popRoute,
      void Function(String name, double height, [Duration? duration]) pushRoute,
      Rect Function(WidgetTester) getSheetRect,
    }) boilerplate({
      required String initialRoute,
      required double initialRouteHeight,
      Curve offsetInterpolationCurve = Curves.linear,
    }) {
      final navigatorKey = GlobalKey<NavigatorState>();
      const sheetKey = Key('sheet');
      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: SheetViewport(
          child: PagedSheet(
            key: sheetKey,
            transitionCurve: offsetInterpolationCurve,
            physics: const ClampingSheetPhysics(),
            navigator: Navigator(
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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);
    });

    testWidgets('When pushing a route', (tester) async {
      final env = boilerplate(
        initialRoute: 'a',
        initialRouteHeight: 300,
      );
      await tester.pumpWidget(env.testWidget);
      env.pushRoute('b', 500);

      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 350);
      expect(env.getSheetRect(tester).height, 350);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 400);
      expect(env.getSheetRect(tester).height, 400);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 450);
      expect(env.getSheetRect(tester).height, 450);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 275);
      expect(env.getSheetRect(tester).height, 275);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 250);
      expect(env.getSheetRect(tester).height, 250);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 225);
      expect(env.getSheetRect(tester).height, 225);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 200);
      expect(env.getSheetRect(tester).height, 200);

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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 450);
      expect(env.getSheetRect(tester).height, 450);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 400);
      expect(env.getSheetRect(tester).height, 400);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 350);
      expect(env.getSheetRect(tester).height, 350);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

      env.popRoute();
      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 200);
      expect(env.getSheetRect(tester).height, 200);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 225);
      expect(env.getSheetRect(tester).height, 225);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 250);
      expect(env.getSheetRect(tester).height, 250);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 275);
      expect(env.getSheetRect(tester).height, 275);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

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

      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);

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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
    });

    testWidgets(
      'Should use the same curve for offset and size transition animations',
      (tester) async {
        const nonLinearCurve = Curves.easeIn;
        final env = boilerplate(
          initialRoute: 'a',
          initialRouteHeight: 300,
          offsetInterpolationCurve: nonLinearCurve,
        );
        await tester.pumpWidget(env.testWidget);
        env.pushRoute('b', 500);

        Rect rectAt(double t) => Rect.lerp(
              Rect.fromLTWH(0, 300, 800, 300),
              Rect.fromLTWH(0, 100, 800, 500),
              nonLinearCurve.transform(t),
            )!;

        await tester.pump();
        expect(env.getSheetRect(tester), rectAt(0));
        await tester.pump(Duration(milliseconds: 75));
        expect(env.getSheetRect(tester), rectAt(0.25));
        await tester.pump(Duration(milliseconds: 75));
        expect(env.getSheetRect(tester), rectAt(0.5));
        await tester.pump(Duration(milliseconds: 75));
        expect(env.getSheetRect(tester), rectAt(0.75));
        await tester.pumpAndSettle();
        expect(env.getSheetRect(tester), rectAt(1));
      },
    );
  });

  group('PagedSheet transition test with Pages API', () {
    ({
      Widget testWidget,
      GlobalKey<NavigatorState> navigatorKey,
      ValueSetter<List<Page<dynamic>>> setPages,
      Rect Function(WidgetTester) getSheetRect,
    }) boilerplate({
      required List<Page<dynamic>> initialPages,
    }) {
      const sheetKey = Key('sheet');
      final navigatorKey = GlobalKey<NavigatorState>();
      final statefulKey =
          GlobalKey<TestStatefulWidgetState<List<Page<dynamic>>>>();
      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: SheetViewport(
          child: PagedSheet(
            key: sheetKey,
            transitionCurve: Curves.linear,
            physics: const ClampingSheetPhysics(),
            navigator: TestStatefulWidget(
              key: statefulKey,
              initialState: initialPages,
              builder: (context, pages) {
                return Navigator(
                  key: navigatorKey,
                  onDidRemovePage: (_) {},
                  pages: pages,
                );
              },
            ),
          ),
        ),
      );

      return (
        testWidget: testWidget,
        navigatorKey: navigatorKey,
        setPages: (pages) {
          statefulKey.currentState!.state = pages;
        },
        getSheetRect: (tester) {
          return tester.getRect(find.byKey(sheetKey));
        },
      );
    }

    Page<dynamic> createPage({
      required String name,
      required double height,
      Duration transitionDuration = const Duration(milliseconds: 300),
    }) {
      return PagedSheetPage(
        name: name,
        key: ValueKey('Page($name)'),
        transitionDuration: transitionDuration,
        child: _TestPage(
          key: Key(name),
          height: height,
        ),
      );
    }

    testWidgets('On initial build', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final env = boilerplate(initialPages: [pageA]);
      await tester.pumpWidget(env.testWidget);
      expect(find.byKey(Key('a')), findsOneWidget);
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);
    });

    testWidgets('On initial build with multiple routes', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final pageB = createPage(name: 'b', height: 500);
      final pageC = createPage(name: 'c', height: 200);
      final env = boilerplate(initialPages: [pageA, pageB, pageC]);
      await tester.pumpWidget(env.testWidget);
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')).hitTestable(), findsNothing);
      expect(find.byKey(Key('c')), findsOneWidget);
      expect(env.getSheetRect(tester).top, testScreenSize.height - 200);
      expect(env.getSheetRect(tester).height, 200);
    });

    testWidgets('When pushing a route', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final env = boilerplate(initialPages: [pageA]);
      await tester.pumpWidget(env.testWidget);

      final pageB = createPage(name: 'b', height: 500);
      env.setPages([pageA, pageB]);

      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 350);
      expect(env.getSheetRect(tester).height, 350);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 400);
      expect(env.getSheetRect(tester).height, 400);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 450);
      expect(env.getSheetRect(tester).height, 450);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);
    });

    testWidgets('When pushing a route without animation', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final env = boilerplate(initialPages: [pageA]);
      await tester.pumpWidget(env.testWidget);

      final pageB = createPage(
        name: 'b',
        height: 500,
        transitionDuration: Duration.zero,
      );
      env.setPages([pageA, pageB]);

      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final env = boilerplate(initialPages: [pageA]);
      await tester.pumpWidget(env.testWidget);

      final pageB = createPage(name: 'b', height: 500);
      final pageC = createPage(name: 'c', height: 200);
      env.setPages([pageA, pageB, pageC]);

      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 275);
      expect(env.getSheetRect(tester).height, 275);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 250);
      expect(env.getSheetRect(tester).height, 250);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 225);
      expect(env.getSheetRect(tester).height, 225);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 200);
      expect(env.getSheetRect(tester).height, 200);

      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')).hitTestable(), findsNothing);
      expect(find.byKey(Key('c')), findsOneWidget);
    });

    testWidgets('When popping a route', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final pageB = createPage(name: 'b', height: 500);
      final env = boilerplate(initialPages: [pageA, pageB]);
      await tester.pumpWidget(env.testWidget);
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);

      env.setPages([pageA]);
      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 450);
      expect(env.getSheetRect(tester).height, 450);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 400);
      expect(env.getSheetRect(tester).height, 400);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 350);
      expect(env.getSheetRect(tester).height, 350);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

      expect(find.byKey(Key('a')), findsOneWidget);
      expect(find.byKey(Key('b')), findsNothing);
    });

    testWidgets('When popping a route without animation', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final pageB = createPage(
        name: 'b',
        height: 500,
        transitionDuration: Duration.zero,
      );
      final env = boilerplate(initialPages: [pageA, pageB]);
      await tester.pumpWidget(env.testWidget);
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')), findsOneWidget);
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

      env.setPages([pageA]);
      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

      expect(find.byKey(Key('a')), findsOneWidget);
      expect(find.byKey(Key('b')), findsNothing);
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final pageB = createPage(name: 'b', height: 500);
      final pageC = createPage(name: 'c', height: 200);
      final env = boilerplate(initialPages: [pageA, pageB, pageC]);
      await tester.pumpWidget(env.testWidget);
      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')).hitTestable(), findsNothing);
      expect(find.byKey(Key('c')), findsOneWidget);

      env.setPages([pageA]);
      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 200);
      expect(env.getSheetRect(tester).height, 200);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 225);
      expect(env.getSheetRect(tester).height, 225);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 250);
      expect(env.getSheetRect(tester).height, 250);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 275);
      expect(env.getSheetRect(tester).height, 275);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
      expect(env.getSheetRect(tester).height, 300);

      expect(find.byKey(Key('a')), findsOneWidget);
      expect(find.byKey(Key('b')), findsNothing);
      expect(find.byKey(Key('c')), findsNothing);
    });

    testWidgets('When replacing the entire page stack', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final pageB = createPage(name: 'b', height: 500);
      final env = boilerplate(initialPages: [pageA, pageB]);
      await tester.pumpWidget(env.testWidget);

      final pageC = createPage(name: 'c', height: 200);
      env.setPages([pageC]);
      await tester.pump();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
      expect(env.getSheetRect(tester).height, 500);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 425);
      expect(env.getSheetRect(tester).height, 425);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 350);
      expect(env.getSheetRect(tester).height, 350);

      await tester.pump(Duration(milliseconds: 75));
      expect(env.getSheetRect(tester).top, testScreenSize.height - 275);
      expect(env.getSheetRect(tester).height, 275);

      await tester.pumpAndSettle();
      expect(env.getSheetRect(tester).top, testScreenSize.height - 200);
      expect(env.getSheetRect(tester).height, 200);

      expect(find.byKey(Key('a')).hitTestable(), findsNothing);
      expect(find.byKey(Key('b')).hitTestable(), findsNothing);
      expect(find.byKey(Key('c')), findsOneWidget);
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final pageB = createPage(name: 'b', height: 500);
      final env = boilerplate(initialPages: [pageA, pageB]);
      await tester.pumpWidget(
        Theme(
          data: ThemeData(platform: TargetPlatform.iOS),
          child: env.testWidget,
        ),
      );
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);

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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 300);
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      final pageA = createPage(name: 'a', height: 300);
      final pageB = createPage(name: 'b', height: 500);
      final env = boilerplate(initialPages: [pageA, pageB]);
      await tester.pumpWidget(
        Theme(
          data: ThemeData(platform: TargetPlatform.iOS),
          child: env.testWidget,
        ),
      );
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
      expect(env.getSheetRect(tester).top, testScreenSize.height - 500);
    });
  });

  group('Regression test', () {
    // https://github.com/fujidaiti/smooth_sheets/issues/309
    testWidgets(
      'Unstable route transition when pop a route during snapping animation',
      (tester) async {
        final controller = SheetController();
        final navigatorKey = GlobalKey<NavigatorState>();
        const sheetKey = Key('sheet');
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SheetViewport(
              child: PagedSheet(
                key: sheetKey,
                controller: controller,
                navigator: Navigator(
                  key: navigatorKey,
                  onGenerateRoute: (_) {
                    return PagedSheetRoute(
                      builder: (_) => _TestPage(
                        key: Key('a'),
                        height: 300,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        unawaited(
          navigatorKey.currentState!.push(
            PagedSheetRoute(
              snapGrid: SheetSnapGrid(
                minFlingSpeed: 50,
                snaps: [SheetOffset(0.5), SheetOffset(1)],
              ),
              builder: (_) => _TestPage(
                key: Key('b'),
                height: 600,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byId('b'), findsOneWidget);
        expect(tester.getRect(find.byId('b')).top, 0);

        final offsetHistory = <double>[];
        controller.addListener(() {
          offsetHistory.add(controller.value!);
        });

        await tester.fling(find.byId('b'), Offset(0, 100), 200);
        await tester.pump(Duration(milliseconds: 500));
        final sheetTopBeforePop = tester.getRect(find.byId('b')).top;
        expect(
          sheetTopBeforePop,
          allOf(greaterThan(0), lessThan(300)),
          reason: 'The sheet is in the middle of the snapping animation',
        );

        navigatorKey.currentState!.pop();
        await tester.pump();
        expect(
          tester.getRect(find.byId('b')).top,
          sheetTopBeforePop,
          reason: 'The sheet position should be preserved',
        );

        await tester.pumpAndSettle();
        expect(offsetHistory, isMonotonicallyDecreasing);
      },
    );

    // https://github.com/fujidaiti/smooth_sheets/issues/305
    testWidgets(
      'Sheet cannot be dragged when the drag starts at shared top/bottom bar '
      'built in PagedSheet.builder',
      (tester) async {
        final controller = SheetController();
        final navigatorKey = GlobalKey<NavigatorState>();
        const topBarKey = Key('topBar');
        const bottomBarKey = Key('bottomBar');
        const pageKey = Key('page');

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SheetViewport(
              child: PagedSheet(
                controller: controller,
                builder: (context, child) {
                  return SheetContentScaffold(
                    extendBodyBehindTopBar: true,
                    extendBodyBehindBottomBar: true,
                    topBar: Container(
                      key: topBarKey,
                      height: 50,
                      color: Colors.blue,
                    ),
                    body: child,
                    bottomBar: Container(
                      key: bottomBarKey,
                      height: 50,
                      color: Colors.green,
                    ),
                  );
                },
                navigator: Navigator(
                  key: navigatorKey,
                  onGenerateRoute: (_) {
                    return PagedSheetRoute(
                      snapGrid: SheetSnapGrid.stepless(),
                      builder: (_) => _TestPage(key: pageKey, height: 300),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(controller.value, 300);

        // Drag from top bar
        final initialOffsetBeforeTopDrag = controller.value!;
        await tester.drag(find.byKey(topBarKey), const Offset(0, 50));
        await tester.pumpAndSettle();
        expect(controller.value, lessThan(initialOffsetBeforeTopDrag));

        // Reset to full offset
        unawaited(controller.animateTo(SheetOffset.absolute(300)));
        await tester.pumpAndSettle();
        expect(controller.value, 300);

        // Drag from bottom bar
        final initialOffsetBeforeBottomDrag = controller.value!;
        await tester.drag(find.byKey(bottomBarKey), const Offset(0, 50));
        await tester.pumpAndSettle();
        expect(controller.value, lessThan(initialOffsetBeforeBottomDrag));
      },
    );
  });
}

class _TestPage extends StatelessWidget {
  const _TestPage({
    super.key,
    required this.height,
    this.isScrollable = false,
  });

  final double height;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox.fromSize(
        size: Size.fromHeight(height),
        child: switch (isScrollable) {
          false => null,
          true => ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                );
              },
            ),
        },
      ),
    );
  }
}

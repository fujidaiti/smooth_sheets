import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class _Boilerplate extends StatelessWidget {
  const _Boilerplate({
    required this.modalRoute,
    this.navigatorKey,
  });

  final ModalSheetRoute<dynamic> modalRoute;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, modalRoute);
                },
                child: const Text('Open modal'),
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  group('Swipe-to-dismiss action test', () {
    Widget boilerplate(SwipeDismissSensitivity sensitivity) {
      return _Boilerplate(
        modalRoute: ModalSheetRoute<dynamic>(
          swipeDismissible: true,
          swipeDismissSensitivity: sensitivity,
          builder: (context) {
            return DraggableSheet(
              child: Container(
                key: const Key('sheet'),
                color: Colors.white,
                width: double.infinity,
                height: 600,
              ),
            );
          },
        ),
      );
    }

    testWidgets(
      'modal should be dismissed if swipe gesture has enough speed',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              minDragDistance: 1000,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.fling(
          find.byKey(const Key('sheet')),
          const Offset(0, 200),
          901, // ratio = velocity (901.0) / screen-height (900.0) > threshold-ratio
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsNothing);
      },
    );

    testWidgets(
      'modal should not be dismissed if swipe gesture has not enough speed',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              minDragDistance: 1000,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.fling(
          find.byKey(const Key('sheet')),
          const Offset(0, 200),
          899, // ratio = velocity (899.0) / screen-height (900.0) < threshold-ratio
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);
      },
    );

    testWidgets(
      'modal should be dismissed if drag distance is enough',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              minDragDistance: 100,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('sheet')),
          const Offset(0, 101),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsNothing);
      },
    );

    testWidgets(
      'modal should not be dismissed if drag distance is not enough',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(
            const SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              minDragDistance: 100,
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('sheet')),
          const Offset(0, 99),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);
      },
    );
  });

  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/233
  group('PopScope test', () {
    late bool isOnPopInvokedCalled;
    late Widget testWidget;

    setUp(() {
      isOnPopInvokedCalled = false;
      testWidget = _Boilerplate(
        modalRoute: ModalSheetRoute(
          swipeDismissible: true,
          builder: (context) {
            return DraggableSheet(
              child: PopScope(
                canPop: false,
                onPopInvoked: (didPop) {
                  isOnPopInvokedCalled = true;
                },
                child: Container(
                  key: const Key('sheet'),
                  color: Colors.white,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            );
          },
        ),
      );
    });

    testWidgets(
      'PopScope.onPopInvoked should be called when tap on barrier',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AnimatedModalBarrier));
        await tester.pumpAndSettle();
        expect(isOnPopInvokedCalled, isTrue);
      },
    );

    testWidgets(
      'PopScope.onPopInvoked should be called when swipe to dismiss',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        await tester.fling(
          find.byKey(const Key('sheet')),
          const Offset(0, 200),
          2000,
        );
        await tester.pumpAndSettle();
        expect(isOnPopInvokedCalled, isTrue);
      },
    );
  });

  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/250
  testWidgets(
    'userGestureInProgress and transition curve consistency test',
    (tester) async {
      var popInvoked = false;
      final route = ModalSheetRoute<dynamic>(
        swipeDismissible: true,
        transitionCurve: Curves.easeInOut,
        builder: (context) {
          return DraggableSheet(
            child: PopScope(
              canPop: false,
              onPopInvoked: (didPop) async {
                if (!didPop) {
                  popInvoked = true;
                  Navigator.pop(context);
                }
              },
              child: Container(
                key: const Key('sheet'),
                color: Colors.white,
                width: double.infinity,
                height: 400,
              ),
            ),
          );
        },
      );

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _Boilerplate(
          modalRoute: route,
          navigatorKey: navigatorKey,
        ),
      );

      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(route.effectiveCurve, Curves.easeInOut);

      // Start dragging
      final gesture = await tester.press(find.byKey(const Key('sheet')));
      await gesture.moveBy(const Offset(0, 50));
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(route.effectiveCurve, Curves.linear);

      await gesture.moveBy(const Offset(0, 50));
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(route.effectiveCurve, Curves.linear);

      // End dragging and then a pop animation starts
      await gesture.moveBy(const Offset(0, 100));
      await gesture.up();
      expect(popInvoked, isTrue);
      expect(route.animation!.status, AnimationStatus.reverse);
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(route.effectiveCurve, Curves.linear);

      await tester.pump(const Duration(milliseconds: 50));
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(route.effectiveCurve, Curves.linear);

      await tester.pump(const Duration(milliseconds: 50));
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(route.effectiveCurve, Curves.linear);

      // Ensure that the pop animation is completed
      await tester.pumpAndSettle();
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(route.effectiveCurve, Curves.easeInOut);
    },
  );
}

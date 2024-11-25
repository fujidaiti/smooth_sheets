import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class _Boilerplate extends StatelessWidget {
  const _Boilerplate({
    required this.modalRoute,
  });

  final ModalSheetRoute<dynamic> modalRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

class _BoilerplateWithGoRouter extends StatelessWidget {
  const _BoilerplateWithGoRouter({
    required this.modalPage,
    this.onExitModal,
  });

  final ModalSheetPage<dynamic> modalPage;
  final FutureOr<bool> Function()? onExitModal;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/modal'),
                    child: const Text('Open modal'),
                  ),
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'modal',
                pageBuilder: (context, state) => modalPage,
                onExit: onExitModal != null
                    ? (context, state) => onExitModal!()
                    : null,
              ),
            ],
          ),
        ],
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
            return SheetViewport(
              child: DraggableSheet(
                child: Container(
                  key: const Key('sheet'),
                  color: Colors.white,
                  width: double.infinity,
                  height: 600,
                ),
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
            return SheetViewport(
              child: DraggableSheet(
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

  // Regression tests for https://github.com/fujidaiti/smooth_sheets/issues/250
  // TODO: Add test cases using Navigator 2.0.
  group('Transition animation status and animation curve consistency test', () {
    ({
      Widget testWidget,
      ModalSheetRoute<dynamic> modalRoute,
      ValueGetter<bool> popInvoked,
    }) boilerplate() {
      var popInvoked = false;
      final modalRoute = ModalSheetRoute<dynamic>(
        swipeDismissible: true,
        transitionCurve: Curves.easeInOut,
        builder: (context) {
          return SheetViewport(
            child: DraggableSheet(
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
            ),
          );
        },
      );

      return (
        testWidget: _Boilerplate(modalRoute: modalRoute),
        modalRoute: modalRoute,
        popInvoked: () => popInvoked,
      );
    }

    testWidgets('Swipe-to-dismissed', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);

      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(env.modalRoute.animation!.isCompleted, isTrue);
      expect(env.modalRoute.effectiveCurve, Curves.easeInOut);

      // Start dragging.
      final gesture = await tester.press(find.byKey(const Key('sheet')));
      await gesture.moveBy(const Offset(0, 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      await gesture.moveBy(const Offset(0, 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      // End dragging and then a pop animation starts.
      await gesture.moveBy(const Offset(0, 100));
      await gesture.up();
      expect(env.popInvoked(), isTrue);
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      await tester.pump(const Duration(milliseconds: 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      await tester.pump(const Duration(milliseconds: 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      // Ensure that the pop animation is completed.
      await tester.pumpAndSettle();
      expect(env.modalRoute.animation!.isDismissed, isTrue);
      expect(env.modalRoute.effectiveCurve, Curves.easeInOut);
    });

    testWidgets('Swipe-to-dismiss canceled', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);

      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(env.modalRoute.animation!.isCompleted, isTrue);
      expect(env.modalRoute.effectiveCurve, Curves.easeInOut);

      // Start dragging.
      final gesture = await tester.press(find.byKey(const Key('sheet')));
      await gesture.moveBy(const Offset(0, 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      await gesture.moveBy(const Offset(0, 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      // Release the drag, triggering the modal
      // to settle back to its original position.
      await gesture.up();
      expect(env.popInvoked(), isFalse);
      expect(env.modalRoute.animation!.status, AnimationStatus.forward);
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      await tester.pump(const Duration(milliseconds: 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      await tester.pump(const Duration(milliseconds: 50));
      expect(env.modalRoute.animation!.isCompleted, isFalse);
      expect(env.modalRoute.animation!.isDismissed, isFalse);
      expect(env.modalRoute.effectiveCurve, Curves.linear);

      // Ensure that the pop animation is completed.
      await tester.pumpAndSettle();
      expect(env.modalRoute.animation!.isCompleted, isTrue);
      expect(env.modalRoute.effectiveCurve, Curves.easeInOut);
    });
  });

  // Regression tests for https://github.com/fujidaiti/smooth_sheets/issues/250
  group(
    'Transition animation status and animation curve consistency test '
    'with Navigator 2.0',
    () {
      ({
        Widget testWidget,
        ValueGetter<ModalSheetRouteMixin<dynamic>?> modalRoute,
        ValueGetter<bool> popInvoked,
      }) boilerplate() {
        var popInvoked = false;
        ModalSheetRouteMixin<dynamic>? modalRoute;
        final testWidget = _BoilerplateWithGoRouter(
          onExitModal: () {
            popInvoked = true;
            return true;
          },
          modalPage: ModalSheetPage(
            swipeDismissible: true,
            transitionCurve: Curves.easeInOut,
            child: Builder(
              builder: (context) {
                modalRoute =
                    ModalRoute.of(context)! as ModalSheetRouteMixin<dynamic>;

                return SheetViewport(
                  child: DraggableSheet(
                    child: Container(
                      key: const Key('sheet'),
                      color: Colors.white,
                      width: double.infinity,
                      height: 400,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        return (
          testWidget: testWidget,
          modalRoute: () => modalRoute,
          popInvoked: () => popInvoked,
        );
      }

      testWidgets('Swipe-to-dismissed', (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(env.modalRoute()!.animation!.isCompleted, isTrue);
        expect(env.modalRoute()!.effectiveCurve, Curves.easeInOut);

        // Start dragging.
        final gesture = await tester.press(find.byKey(const Key('sheet')));
        await gesture.moveBy(const Offset(0, 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        await gesture.moveBy(const Offset(0, 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        // End dragging and then a pop animation starts.
        await gesture.moveBy(const Offset(0, 100));
        await gesture.up();
        expect(env.popInvoked(), isTrue);
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        await tester.pump(const Duration(milliseconds: 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        await tester.pump(const Duration(milliseconds: 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        // Ensure that the pop animation is completed.
        await tester.pumpAndSettle();
        expect(env.modalRoute()!.animation!.isDismissed, isTrue);
        expect(env.modalRoute()!.effectiveCurve, Curves.easeInOut);
      });

      testWidgets('Swipe-to-dismiss canceled', (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(env.modalRoute()!.animation!.isCompleted, isTrue);
        expect(env.modalRoute()!.effectiveCurve, Curves.easeInOut);

        // Start dragging.
        final gesture = await tester.press(find.byKey(const Key('sheet')));
        await gesture.moveBy(const Offset(0, 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        await gesture.moveBy(const Offset(0, 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        // Release the drag, triggering the modal
        // to settle back to its original position.
        await gesture.up();
        expect(env.popInvoked(), isFalse);
        expect(env.modalRoute()!.animation!.status, AnimationStatus.forward);
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        await tester.pump(const Duration(milliseconds: 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        await tester.pump(const Duration(milliseconds: 50));
        expect(env.modalRoute()!.animation!.isCompleted, isFalse);
        expect(env.modalRoute()!.animation!.isDismissed, isFalse);
        expect(env.modalRoute()!.effectiveCurve, Curves.linear);

        // Ensure that the pop animation is completed.
        await tester.pumpAndSettle();
        expect(env.modalRoute()!.animation!.isCompleted, isTrue);
        expect(env.modalRoute()!.effectiveCurve, Curves.easeInOut);
      });
    },
  );
}

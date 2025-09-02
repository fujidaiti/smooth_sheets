import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';
import 'src/test_stateful_widget.dart';

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

class _BoilerplateWithPagesApi extends StatefulWidget {
  const _BoilerplateWithPagesApi({
    super.key,
    required this.initialPages,
  });

  final List<Page<dynamic>> initialPages;

  static Page<dynamic> createHomePage({
    VoidCallback? onPressOpenModalButton,
  }) {
    return MaterialPage(
      key: ObjectKey('home'),
      child: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: onPressOpenModalButton,
            child: const Text('Open modal'),
          ),
        ),
      ),
    );
  }

  @override
  State<_BoilerplateWithPagesApi> createState() =>
      _BoilerplateWithPagesApiState();
}

class _BoilerplateWithPagesApiState extends State<_BoilerplateWithPagesApi> {
  List<Page<dynamic>> get pages => _pages;
  late List<Page<dynamic>> _pages;
  set pages(List<Page<dynamic>> value) {
    setState(() => _pages = value);
  }

  @override
  void initState() {
    super.initState();
    _pages = [...widget.initialPages];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Navigator(
        pages: _pages,
        onDidRemovePage: (page) {
          setState(() => _pages.remove(page));
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
    Widget boilerplate({
      SwipeDismissSensitivity sensitivity = const SwipeDismissSensitivity(),
      bool swipeDismissible = true,
      Widget Function(Widget sheet)? builder,
    }) {
      return _Boilerplate(
        modalRoute: ModalSheetRoute<dynamic>(
          swipeDismissible: swipeDismissible,
          swipeDismissSensitivity: sensitivity,
          builder: (context) {
            final result = Sheet(
              child: Container(
                key: const Key('sheet'),
                color: Colors.white,
                width: double.infinity,
                height: 600,
              ),
            );
            return builder?.call(result) ?? result;
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
            sensitivity: const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              minDragOffset: SheetOffset.absolute(1000),
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
            sensitivity: const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              minDragOffset: SheetOffset.absolute(1000),
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
            sensitivity: const SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              minDragOffset: SheetOffset.absolute(100),
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
      'modal should be dismissed if drag distance is enough by expression',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(
            sensitivity: SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              minDragOffset: SheetOffset.expression((metrics) {
                return metrics.viewportSize.height * 0.6;
              }),
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('sheet')),
          const Offset(0, 361),
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
            sensitivity: const SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              minDragOffset: SheetOffset.absolute(100),
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

    testWidgets(
      'modal should not be dismissed if swipe-to-dismiss is disabled',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(
            swipeDismissible: false,
            sensitivity: const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              minDragOffset: SheetOffset.absolute(1000),
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.fling(
          find.byKey(const Key('sheet')),
          const Offset(0, 200),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);
      },
    );

    // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/170
    testWidgets(
      'swipeDismissible should be able to be changed dynamically',
      (tester) async {
        Page<dynamic> createModalPage({required bool swipeDismissible}) {
          return ModalSheetPage(
            key: const ValueKey('modal'),
            swipeDismissible: swipeDismissible,
            swipeDismissSensitivity: SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
            ),
            child: Sheet(
              child: Container(
                key: const Key('sheet'),
                color: Colors.white,
                width: double.infinity,
                height: 600,
              ),
            ),
          );
        }

        Future<void> performDismissingFling() async {
          await tester.fling(
            find.byKey(const Key('sheet')),
            const Offset(0, 200),
            1000, // Sufficient velocity to dismiss
          );
          await tester.pumpAndSettle();
        }

        final boilerplateKey = GlobalKey<_BoilerplateWithPagesApiState>();
        await tester.pumpWidget(
          _BoilerplateWithPagesApi(
            key: boilerplateKey,
            initialPages: [
              _BoilerplateWithPagesApi.createHomePage(),
              createModalPage(swipeDismissible: false),
            ],
          ),
        );
        expect(find.byId('sheet'), findsOneWidget);
        await performDismissingFling();
        expect(
          find.byId('sheet'),
          findsOneWidget,
          reason: 'Should not be dismissible when swipeDismissible is false',
        );

        // Update the page to make the modal dismissible.
        boilerplateKey.currentState!.pages = [
          _BoilerplateWithPagesApi.createHomePage(),
          createModalPage(swipeDismissible: true),
        ];
        await tester.pumpAndSettle();
        expect(find.byId('sheet'), findsOneWidget);
        await performDismissingFling();
        expect(
          find.byId('sheet'),
          findsNothing,
          reason: 'Should be dismissible when swipeDismissible is true',
        );
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
            return Sheet(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
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
      'existance of PopScope should take precedence over swipeDismissible flag',
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
        expect(find.byId('sheet'), findsOneWidget);
      },
    );

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

  group('SheetPopScope test', () {
    Widget boilerplate({
      required Widget Function(Widget sheet) popScopeBuilder,
      required bool swipeDismissible,
    }) {
      return _Boilerplate(
        modalRoute: ModalSheetRoute(
          swipeDismissible: swipeDismissible,
          swipeDismissSensitivity: const SwipeDismissSensitivity(
            minDragOffset: SheetOffset.absolute(100),
          ),
          builder: (context) {
            return Sheet(
              physics: const ClampingSheetPhysics(),
              child: popScopeBuilder(
                Container(
                  key: const Key('sheet'),
                  color: Colors.white,
                  width: double.infinity,
                  height: 400,
                ),
              ),
            );
          },
        ),
      );
    }

    Future<void> openModal(WidgetTesterX tester) async {
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(find.byId('sheet'), findsOneWidget);
      expect(tester.getRect(find.byId('sheet')).top, 200);
    }

    Future<TestGesture> performSwipeGesture(
      WidgetTesterX tester, {
      required bool shouldGestureEnabled,
    }) async {
      final gesture = await tester.startDrag(
        tester.getCenter(find.byId('sheet')),
        AxisDirection.down,
      );
      await gesture.moveBy(Offset(0, 100));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byId('sheet')).top,
        shouldGestureEnabled ? greaterThan(200) : 200,
        reason: shouldGestureEnabled
            ? 'Swipe gesture should be enabled.'
            : 'Swipe gesture should be disabled.',
      );
      await gesture.up();
      await tester.pumpAndSettle();
      return gesture;
    }

    testWidgets(
      'Can pop; Gesture is enabled',
      (tester) async {
        var isOnPopInvokedCalled = false;
        final testWidget = boilerplate(
          swipeDismissible: true,
          popScopeBuilder: (sheet) => SheetPopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, _) {
              isOnPopInvokedCalled = true;
            },
            child: sheet,
          ),
        );

        await tester.pumpWidget(testWidget);
        await openModal(tester);
        await performSwipeGesture(tester, shouldGestureEnabled: true);
        expect(isOnPopInvokedCalled, isTrue);
        expect(find.byId('sheet'), findsNothing);
      },
    );

    testWidgets(
      'Cannot pop; Gesture is enabled',
      (tester) async {
        var isOnPopInvokedCalled = false;
        final testWidget = boilerplate(
          swipeDismissible: true,
          popScopeBuilder: (sheet) => SheetPopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              isOnPopInvokedCalled = true;
            },
            child: sheet,
          ),
        );

        await tester.pumpWidget(testWidget);
        await openModal(tester);
        await performSwipeGesture(tester, shouldGestureEnabled: true);
        expect(isOnPopInvokedCalled, isTrue);
        expect(find.byId('sheet'), findsOneWidget);
      },
    );

    testWidgets('Cannot pop; Gesture is disabled', (tester) async {
      final testWidget = boilerplate(
        swipeDismissible: true,
        popScopeBuilder: (sheet) => SheetPopScope<dynamic>(
          canPop: false,
          onPopInvokedWithResult: null,
          child: sheet,
        ),
      );
      await tester.pumpWidget(testWidget);
      await openModal(tester);
      await performSwipeGesture(tester, shouldGestureEnabled: false);
      expect(find.byId('sheet'), findsOneWidget);
    });

    testWidgets(
      'Dynamically enable/disable the swipe gesture',
      (tester) async {
        const ({
          bool canPop,
          PopInvokedWithResultCallback<dynamic>? callback,
        }) initialPopScopeConfig = (canPop: false, callback: null);

        final popScopeStateKey = GlobalKey<
            TestStatefulWidgetState<
                ({
                  bool canPop,
                  PopInvokedWithResultCallback<dynamic>? callback,
                })>>();

        final testWidget = boilerplate(
          swipeDismissible: true,
          popScopeBuilder: (sheet) => TestStatefulWidget(
            key: popScopeStateKey,
            initialState: initialPopScopeConfig,
            builder: (context, config) => SheetPopScope(
              canPop: config.canPop,
              onPopInvokedWithResult: config.callback,
              child: sheet,
            ),
          ),
        );

        await tester.pumpWidget(testWidget);
        await openModal(tester);

        // 1. Cannot pop; Gesture is also disabled.
        await performSwipeGesture(tester, shouldGestureEnabled: false);
        expect(find.byId('sheet'), findsOneWidget);

        // 2. Cannot pop; Gesture is enabled.
        popScopeStateKey.currentState!.state =
            (canPop: false, callback: (_, __) {});
        await tester.pumpAndSettle();
        await performSwipeGesture(tester, shouldGestureEnabled: true);
        expect(find.byId('sheet'), findsOneWidget);

        // 3. Can pop; Gesture is enabled.
        popScopeStateKey.currentState!.state =
            (canPop: true, callback: (_, __) {});
        await tester.pumpAndSettle();
        await performSwipeGesture(tester, shouldGestureEnabled: true);
        expect(find.byId('sheet'), findsNothing);
      },
    );

    testWidgets(
      'If ModalSheetRoute.swipeDismissible is false, the modal should never '
      'be popped and the gesture should always be disabled, regardless of '
      'the existence of SheetPopScope',
      (tester) async {
        final testWidget = boilerplate(
          swipeDismissible: false,
          popScopeBuilder: (sheet) => SheetPopScope(
            canPop: true,
            onPopInvokedWithResult: (_, __) {},
            child: sheet,
          ),
        );

        await tester.pumpWidget(testWidget);
        await openModal(tester);
        await performSwipeGesture(tester, shouldGestureEnabled: false);
        expect(find.byId('sheet'), findsOneWidget);
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
          return Sheet(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
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

                return Sheet(
                  child: Container(
                    key: const Key('sheet'),
                    color: Colors.white,
                    width: double.infinity,
                    height: 400,
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

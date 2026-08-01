import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:smooth_sheets/src/modal.dart' show SheetVisibleFractionTween;
import 'package:smooth_sheets/src/model.dart' show ImmutableSheetMetrics;

import 'src/flutter_test_x.dart';
import 'src/test_stateful_widget.dart';

class _Boilerplate extends StatelessWidget {
  const _Boilerplate({required this.modalRoute});

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
  const _BoilerplateWithPagesApi({super.key, required this.initialPages});

  final List<Page<dynamic>> initialPages;

  static Page<dynamic> createHomePage({VoidCallback? onPressOpenModalButton}) {
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
  const _BoilerplateWithGoRouter({required this.modalPage, this.onExitModal});

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

    testWidgets('modal should be dismissed if swipe gesture has enough speed', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        boilerplate(
          sensitivity: const SwipeDismissSensitivity(
            minFlingVelocityRatio: 1.0,
            dismissalOffset: SheetOffset.absolute(0),
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
    });

    testWidgets(
      'modal should not be dismissed if swipe gesture has not enough speed',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          boilerplate(
            sensitivity: const SwipeDismissSensitivity(
              minFlingVelocityRatio: 1.0,
              dismissalOffset: SheetOffset.absolute(0),
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

    testWidgets('modal should be dismissed if drag distance is enough', (
      tester,
    ) async {
      await tester.pumpWidget(
        boilerplate(
          sensitivity: const SwipeDismissSensitivity(
            minFlingVelocityRatio: 5.0,
            dismissalOffset: SheetOffset.absolute(500),
          ),
        ),
      );

      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet')), findsOneWidget);

      await tester.drag(find.byKey(const Key('sheet')), const Offset(0, 101));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet')), findsNothing);
    });

    testWidgets(
      'modal should be dismissed if drag distance is enough by expression',
      (tester) async {
        await tester.pumpWidget(
          boilerplate(
            sensitivity: SwipeDismissSensitivity(
              minFlingVelocityRatio: 5.0,
              dismissalOffset: SheetOffset(0.4),
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('sheet')),
          const Offset(0, (600 * 0.6) + 1),
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
              dismissalOffset: SheetOffset.absolute(500),
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        await tester.drag(find.byKey(const Key('sheet')), const Offset(0, 100));
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
              dismissalOffset: SheetOffset.absolute(1000),
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
    testWidgets('swipeDismissible should be able to be changed dynamically', (
      tester,
    ) async {
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
    });
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

    testWidgets('PopScope.onPopInvoked should be called when tap on barrier', (
      tester,
    ) async {
      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AnimatedModalBarrier));
      await tester.pumpAndSettle();
      expect(isOnPopInvokedCalled, isTrue);
    });

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
            dismissalOffset: SheetOffset.absolute(500),
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

    testWidgets('Can pop; Gesture is enabled', (tester) async {
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
    });

    testWidgets('Cannot pop; Gesture is enabled', (tester) async {
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
    });

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

    testWidgets('Dynamically enable/disable the swipe gesture', (tester) async {
      const ({bool canPop, PopInvokedWithResultCallback<dynamic>? callback})
      initialPopScopeConfig = (canPop: false, callback: null);

      final popScopeStateKey =
          GlobalKey<
            TestStatefulWidgetState<
              ({bool canPop, PopInvokedWithResultCallback<dynamic>? callback})
            >
          >();

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
      popScopeStateKey.currentState!.state = (
        canPop: false,
        callback: (_, _) {},
      );
      await tester.pumpAndSettle();
      await performSwipeGesture(tester, shouldGestureEnabled: true);
      expect(find.byId('sheet'), findsOneWidget);

      // 3. Can pop; Gesture is enabled.
      popScopeStateKey.currentState!.state = (
        canPop: true,
        callback: (_, _) {},
      );
      await tester.pumpAndSettle();
      await performSwipeGesture(tester, shouldGestureEnabled: true);
      expect(find.byId('sheet'), findsNothing);
    });

    testWidgets(
      'If ModalSheetRoute.swipeDismissible is false, the modal should never '
      'be popped and the gesture should always be disabled, regardless of '
      'the existence of SheetPopScope',
      (tester) async {
        final testWidget = boilerplate(
          swipeDismissible: false,
          popScopeBuilder: (sheet) => SheetPopScope(
            canPop: true,
            onPopInvokedWithResult: (_, _) {},
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
    })
    boilerplate() {
      var popInvoked = false;
      final modalRoute = ModalSheetRoute<dynamic>(
        swipeDismissible: true,
        transitionCurve: Curves.easeInOut,
        swipeDismissSensitivity: SwipeDismissSensitivity(
          dismissalOffset: SheetOffset.absolute(250),
        ),
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
  group('Transition animation status and animation curve consistency test '
      'with Navigator 2.0', () {
    ({
      Widget testWidget,
      ValueGetter<ModalSheetRouteMixin<dynamic>?> modalRoute,
      ValueGetter<bool> popInvoked,
    })
    boilerplate() {
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
          swipeDismissSensitivity: SwipeDismissSensitivity(
            dismissalOffset: SheetOffset.absolute(250),
          ),
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
  });

  group('Modal barrier fade test', () {
    const barrierColor = Colors.black54;
    const sheetHeight = 100.0;

    ({Widget testWidget, ModalSheetRoute<dynamic> modalRoute}) boilerplate() {
      final modalRoute = ModalSheetRoute<dynamic>(
        swipeDismissible: true,
        barrierColor: barrierColor,
        builder: (context) {
          return Sheet(
            child: Container(
              key: const Key('sheet'),
              color: Colors.white,
              width: double.infinity,
              height: sheetHeight,
            ),
          );
        },
      );
      return (
        testWidget: _Boilerplate(modalRoute: modalRoute),
        modalRoute: modalRoute,
      );
    }

    double currentBarrierAlpha(WidgetTester tester) {
      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      );
      return barrier.color.value!.a;
    }

    testWidgets('barrier is fully opaque when the sheet is at rest', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(boilerplate().testWidget);
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(currentBarrierAlpha(tester), barrierColor.a);
    });

    testWidgets(
      'barrier fully fades once a small sheet is dragged off by its own '
      'height, even though that is far less than the full screen height',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(boilerplate().testWidget);
        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        final gesture = await tester.press(find.byKey(const Key('sheet')));
        // Drag down by exactly the sheet's own height (100), which is only
        // ~11% of the 900px screen height used by the route's transition.
        await gesture.moveBy(const Offset(0, sheetHeight));
        await tester.pump();

        expect(currentBarrierAlpha(tester), closeTo(0, 0.01));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'barrier fade tracks the fraction of the sheet dragged off, not the '
      'fraction of the screen',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(boilerplate().testWidget);
        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        final gesture = await tester.press(find.byKey(const Key('sheet')));
        // Drag down by half of the sheet's own height.
        await gesture.moveBy(const Offset(0, sheetHeight / 2));
        await tester.pump();

        // While a drag is in progress, barrierCurve is Curves.linear (see
        // ModalSheetRouteMixin.barrierCurve), so the barrier fades exactly
        // proportionally to the sheet-relative drag fraction, rather than
        // through the app's default easing curve (which is only used for
        // the non-drag open/close animation).
        final expectedAlpha = barrierColor.a * 0.5;
        expect(currentBarrierAlpha(tester), closeTo(expectedAlpha, 0.01));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'barrier fade still uses the default easing curve for the automatic '
      'open animation, unaffected by the drag-time linear override',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);
        await tester.tap(find.text('Open modal'));
        await tester.pump();

        // Advance partway through the (non-drag) open transition.
        await tester.pump(const Duration(milliseconds: 150));

        final t = env.modalRoute.animation!.value;
        final expectedAlpha = barrierColor.a * Curves.ease.transform(t);
        expect(currentBarrierAlpha(tester), closeTo(expectedAlpha, 0.01));

        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'barrier stays fully opaque while a drag is only moving the sheet '
      'between its own snaps, and only starts fading once the '
      'route-level dismiss transition engages',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final modalRoute = ModalSheetRoute<dynamic>(
          swipeDismissible: true,
          barrierColor: barrierColor,
          builder: (context) {
            return Sheet(
              // Two snap points (min 0.5, max 1), so minOffset != maxOffset,
              // unlike the single-snap sheet used by the other tests in
              // this group. This lets the sheet absorb some of the drag
              // itself (via its own offset) before handing off to the
              // route's dismiss gesture.
              snapGrid: const SheetSnapGrid(
                snaps: [SheetOffset(0.5), SheetOffset(1)],
              ),
              child: Container(
                key: const Key('sheet'),
                color: Colors.white,
                width: double.infinity,
                height: sheetHeight,
              ),
            );
          },
        );

        await tester.pumpWidget(_Boilerplate(modalRoute: modalRoute));
        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(currentBarrierAlpha(tester), barrierColor.a);

        final gesture = await tester.press(find.byKey(const Key('sheet')));

        // Drag by 25px, well within the sheet's own snap range (offset can
        // move from 100 down to 50 before the route engages), so this
        // delta is fully absorbed by the sheet's own offset (100 -> 75) --
        // the route's transition value must not move at all. Moving
        // between its own snaps like this isn't a dismissal, so the
        // barrier must stay fully opaque here, even though the sheet
        // itself is already partially off-screen.
        await gesture.moveBy(const Offset(0, 25));
        await tester.pump();

        expect(modalRoute.animation!.value, 1.0);
        expect(currentBarrierAlpha(tester), closeTo(barrierColor.a, 0.01));

        // Drag by another 25px (50px total), reaching the sheet's
        // minOffset exactly. Still fully absorbed by the sheet's own
        // offset, so the route's transition value still hasn't moved, and
        // the barrier is still fully opaque.
        await gesture.moveBy(const Offset(0, 25));
        await tester.pump();

        expect(modalRoute.animation!.value, 1.0);
        expect(currentBarrierAlpha(tester), closeTo(barrierColor.a, 0.01));

        // Drag by another 25px (75px total). The sheet has no more room to
        // absorb the delta (already at its minOffset), so the remainder
        // now shifts the route's transition value: the pop transition has
        // begun, and the barrier starts fading in sync with it, tracking
        // how much of the sheet's currently-visible 50px extent has been
        // pushed off-screen -- half of it (25px), in this case.
        await gesture.moveBy(const Offset(0, 25));
        await tester.pump();

        expect(modalRoute.animation!.value, lessThan(1.0));
        expect(
          currentBarrierAlpha(tester),
          closeTo(barrierColor.a * 0.5, 0.01),
        );

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });

  group('SheetVisibleFractionTween test', () {
    SheetMetrics metrics({
      required double offset,
      required double sheetHeight,
      required double viewportHeight,
    }) {
      return ImmutableSheetMetrics(
        offset: offset,
        minOffset: 0,
        maxOffset: sheetHeight,
        devicePixelRatio: 1,
        contentBaseline: 0,
        contentSize: Size(0, sheetHeight),
        size: Size(0, sheetHeight),
        viewportPadding: EdgeInsets.zero,
        viewportSize: Size(0, viewportHeight),
        contentMargin: EdgeInsets.zero,
      );
    }

    // Note: the input to `transform` here is the *curved* progress (e.g.
    // Curves.linear during a drag), not the route's raw animation value.
    // Curve application happens in a separate stage in buildModalBarrier();
    // see the 'Modal barrier fade test' group above for coverage of the
    // fully composed pipeline.

    test('returns the curved progress unchanged when metrics is null', () {
      final tween = SheetVisibleFractionTween(metrics: () => null);

      for (final curvedProgress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(tween.transform(curvedProgress), curvedProgress);
      }
    });

    test(
      'returns 1 at rest (curvedProgress=1) regardless of the '
      'sheet-to-viewport ratio or how much of the sheet itself is '
      'currently visible',
      () {
        for (final viewportHeight in [200.0, 900.0, 5000.0]) {
          for (final offset in [20.0, 50.0, 100.0]) {
            final tween = SheetVisibleFractionTween(
              metrics: () => metrics(
                offset: offset,
                sheetHeight: 100,
                viewportHeight: viewportHeight,
              ),
            );

            // Even a sheet that is only partially visible on its own (e.g.
            // resting at a snap smaller than its max height) is "fully
            // visible" by this tween's own definition as long as nothing
            // is displacing it (curvedProgress=1).
            expect(tween.transform(1), 1.0);
          }
        }
      },
    );

    test(
      'fraction is proportional to the sheet\'s current offset (how '
      'visible it already was), not its max height or the viewport height',
      () {
        // A small sheet (100px max height) on a much larger viewport
        // (900px). Half of the viewport-scaled progress (curvedProgress=
        // 0.5) means the route has shifted the whole viewport down by
        // 450px, which is far more than the sheet's own height (100px), so
        // the sheet should already be fully hidden (fraction clamped to 0).
        final smallSheetTween = SheetVisibleFractionTween(
          metrics: () =>
              metrics(offset: 100, sheetHeight: 100, viewportHeight: 900),
        );
        expect(smallSheetTween.transform(0.5), 0.0);

        // Dragging by only 50px (curvedProgress = 1 - 50/900) should fade
        // the small sheet by exactly half (50 out of its own 100px height).
        expect(smallSheetTween.transform(1 - 50 / 900), closeTo(0.5, 1e-9));

        // A sheet as tall as the viewport (900px) should instead track the
        // viewport-scaled progress 1:1.
        final fullHeightSheetTween = SheetVisibleFractionTween(
          metrics: () =>
              metrics(offset: 900, sheetHeight: 900, viewportHeight: 900),
        );
        expect(fullHeightSheetTween.transform(0.5), closeTo(0.5, 1e-9));

        // A sheet resting at a smaller snap (offset=50) than its max height
        // (100), so it's already only half-visible on its own even before
        // any displacement. Once displaced, the fraction is measured
        // against that 50px of *current* visibility, not the 100px max
        // height: dragging by 25px (half of the 50px currently visible)
        // fades it by exactly half.
        final peekingSheetTween = SheetVisibleFractionTween(
          metrics: () =>
              metrics(offset: 50, sheetHeight: 100, viewportHeight: 900),
        );
        expect(
          peekingSheetTween.transform(1 - 25 / 900),
          closeTo(0.5, 1e-9),
        );
      },
    );

    test('clamps to 0 when the apparent visible pixels are negative', () {
      final tween = SheetVisibleFractionTween(
        metrics: () =>
            metrics(offset: 20, sheetHeight: 100, viewportHeight: 900),
      );

      // curvedProgress=0 => full 900px shift, way more than the 20px
      // currently offset.
      expect(tween.transform(0), 0.0);
    });

    test('clamps to 1 when curvedProgress overshoots past 1', () {
      final tween = SheetVisibleFractionTween(
        // e.g. an overshoot during a spring-back animation.
        metrics: () =>
            metrics(offset: 100, sheetHeight: 100, viewportHeight: 900),
      );

      expect(tween.transform(1.1), 1.0);
    });

    test('returns 0 when the sheet has zero offset', () {
      final tween = SheetVisibleFractionTween(
        metrics: () => metrics(offset: 0, sheetHeight: 0, viewportHeight: 900),
      );

      expect(tween.transform(1), 0.0);
    });
  });

  group('ModalSheetRoute barrierBuilder test', () {
    Widget boilerplate({required ModalSheetRoute<dynamic> modalRoute}) {
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

    testWidgets('barrierBuilder should be called when provided', (
      tester,
    ) async {
      var wasBuilderCalled = false;
      ModalRoute<dynamic>? capturedRoute;
      VoidCallback? capturedCallback;

      final modalRoute = ModalSheetRoute<dynamic>(
        barrierBuilder: (route, onDismiss) {
          wasBuilderCalled = true;
          capturedRoute = route;
          capturedCallback = onDismiss;
          return Container(
            key: const Key('custom-barrier'),
            color: Colors.red.withValues(alpha: 0.5),
          );
        },
        builder: (context) {
          return Sheet(
            child: Container(
              key: const Key('sheet'),
              color: Colors.white,
              height: 400,
            ),
          );
        },
      );

      await tester.pumpWidget(boilerplate(modalRoute: modalRoute));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(wasBuilderCalled, isTrue);
      expect(capturedRoute, isNotNull);
      expect(capturedCallback, isNotNull);
      expect(find.byKey(const Key('custom-barrier')), findsOneWidget);
    });

    testWidgets('barrierBuilder should receive the correct route instance', (
      tester,
    ) async {
      ModalRoute<dynamic>? capturedRoute;

      final modalRoute = ModalSheetRoute<dynamic>(
        barrierColor: Colors.blue,
        barrierDismissible: false,
        barrierBuilder: (route, onDismiss) {
          capturedRoute = route;
          return Container(key: const Key('custom-barrier'));
        },
        builder: (context) {
          return Sheet(
            child: Container(
              key: const Key('sheet'),
              color: Colors.white,
              height: 400,
            ),
          );
        },
      );

      await tester.pumpWidget(boilerplate(modalRoute: modalRoute));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(capturedRoute, equals(modalRoute));
      expect(capturedRoute!.barrierColor, Colors.blue);
      expect(capturedRoute!.barrierDismissible, isFalse);
    });

    testWidgets('onDismiss callback should dismiss the modal when called', (
      tester,
    ) async {
      VoidCallback? capturedCallback;

      final modalRoute = ModalSheetRoute<dynamic>(
        barrierBuilder: (route, onDismiss) {
          capturedCallback = onDismiss;
          return GestureDetector(
            key: const Key('custom-barrier'),
            onTap: onDismiss,
            child: Container(color: Colors.red.withValues(alpha: 0.5)),
          );
        },
        builder: (context) {
          return Sheet(
            child: Container(
              key: const Key('sheet'),
              color: Colors.white,
              height: 400,
            ),
          );
        },
      );

      await tester.pumpWidget(boilerplate(modalRoute: modalRoute));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sheet')), findsOneWidget);
      expect(capturedCallback, isNotNull);

      capturedCallback!();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sheet')), findsNothing);
    });

    testWidgets('default barrier should be used when barrierBuilder is null', (
      tester,
    ) async {
      final modalRoute = ModalSheetRoute<dynamic>(
        barrierColor: Colors.black54,
        barrierBuilder: null,
        builder: (context) {
          return Sheet(
            child: Container(
              key: const Key('sheet'),
              color: Colors.white,
              height: 400,
            ),
          );
        },
      );

      await tester.pumpWidget(boilerplate(modalRoute: modalRoute));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sheet')), findsOneWidget);
      expect(find.byType(AnimatedModalBarrier), findsOneWidget);
    });

    testWidgets('onDismiss should only work when animation is completed', (
      tester,
    ) async {
      VoidCallback? capturedCallback;

      final modalRoute = ModalSheetRoute<dynamic>(
        transitionDuration: const Duration(milliseconds: 500),
        barrierBuilder: (route, onDismiss) {
          capturedCallback = onDismiss;
          return GestureDetector(
            key: const Key('custom-barrier'),
            onTap: onDismiss,
            child: Container(color: Colors.red.withValues(alpha: 0.5)),
          );
        },
        builder: (context) {
          return Sheet(
            child: Container(
              key: const Key('sheet'),
              color: Colors.white,
              height: 400,
            ),
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );

      await tester.tap(find.text('Open modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      capturedCallback!();
      await tester.pump();

      expect(find.byKey(const Key('sheet')), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}

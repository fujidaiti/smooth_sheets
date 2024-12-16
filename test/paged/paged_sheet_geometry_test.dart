import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/sheet_activity.dart';
import 'package:smooth_sheets/src/foundation/sheet_position.dart';
import 'package:smooth_sheets/src/paged/paged_sheet_geometry.dart';
import 'package:smooth_sheets/src/paged/paged_sheet_route.dart';
import 'package:smooth_sheets/src/paged/route_transition_observer.dart';

import '../src/stubbing.dart';
import '../src/stubbing.mocks.dart';
import '../src/test_ticker.dart';

void main() {
  // Required because AnimationController depends on SemanticsBinding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late PagedSheetGeometry geometryUnderTest;

  setUp(() {
    geometryUnderTest = PagedSheetGeometry(
      context: MockSheetContext(),
    );
  });

  tearDown(() {
    geometryUnderTest.dispose();
  });

  group('Lifecycle test', () {
    test('Before first build', () {
      expect(geometryUnderTest.maybePixels, isNull);
      expect(geometryUnderTest.maybeContentSize, isNull);
      expect(geometryUnderTest.maybeViewportSize, isNull);
      expect(geometryUnderTest.maybeViewportInsets, isNull);
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());
    });

    test('First build', () {
      _firstBuild(
        geometry: geometryUnderTest,
        viewportSize: const Size(400, 800),
        initialRouteContentSize: const Size(400, 400),
        initialOffset: const SheetAnchor.proportional(0.5),
        initialMinOffset: const SheetAnchor.proportional(0.5),
        initialMaxOffset: const SheetAnchor.proportional(1),
      );

      expect(geometryUnderTest.maybePixels, 200);
      expect(geometryUnderTest.maybeMinPixels, 200);
      expect(geometryUnderTest.maybeMaxPixels, 400);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));
      expect(geometryUnderTest.maybeViewportSize, const Size(400, 800));
      expect(geometryUnderTest.maybeViewportInsets, EdgeInsets.zero);
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());
    });

    test('Push a new route and then pop it', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        initialRouteContentSize: const Size(400, 400),
        viewportSize: const Size(400, 800),
        initialOffset: const SheetAnchor.proportional(0.5),
        initialMinOffset: const SheetAnchor.proportional(0.5),
        initialMaxOffset: const SheetAnchor.proportional(1),
      );

      final (newRoute, newRouteTransitionController) = _createRoute(
        initialOffset: const SheetAnchor.proportional(1),
        minOffset: const SheetAnchor.proportional(1),
        maxOffset: const SheetAnchor.proportional(1),
        transitionDuration: const Duration(milliseconds: 200),
      );

      final pushTransition = _startForwardTransition(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        newRoute: newRoute,
        newRouteContentSize: const Size(400, 600),
        newRouteTransitionController: newRouteTransitionController,
      );
      expect(geometryUnderTest.maybePixels, 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));
      expect(geometryUnderTest.activity, isA<RouteTransitionSheetActivity>());

      pushTransition
        ..tickAndSettle()
        ..end();
      expect(geometryUnderTest.maybePixels, 600);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());

      final popTransition = _startBackwardTransition(
        geometry: geometryUnderTest,
        currentRoute: newRoute,
        destinationRoute: initialRoute,
        currentRouteTransitionController: newRouteTransitionController,
      );
      expect(geometryUnderTest.maybePixels, 600);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));
      expect(geometryUnderTest.activity, isA<RouteTransitionSheetActivity>());

      popTransition
        ..tickAndSettle()
        ..end();
      expect(geometryUnderTest.maybePixels, 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());
    });
  });

  group('Transition test', () {
    test('Animate offset when pushing a new route', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        initialRouteContentSize: const Size(400, 400),
        viewportSize: const Size(400, 800),
        initialOffset: const SheetAnchor.proportional(0.5),
        initialMinOffset: const SheetAnchor.proportional(0.5),
        initialMaxOffset: const SheetAnchor.proportional(1),
      );

      final (newRoute, newRouteTransitionController) = _createRoute(
        initialOffset: const SheetAnchor.proportional(1),
        minOffset: const SheetAnchor.proportional(1),
        maxOffset: const SheetAnchor.proportional(1),
        transitionDuration: const Duration(milliseconds: 200),
      );

      final pushTransition = _startForwardTransition(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        newRoute: newRoute,
        newRouteContentSize: const Size(400, 600),
        newRouteTransitionController: newRouteTransitionController,
      );

      pushTransition.tick(Duration.zero);
      expect(geometryUnderTest.maybePixels, 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));

      const curve = kDefaultPagedSheetTransitionCurve;
      pushTransition.tick(const Duration(milliseconds: 50));
      expect(geometryUnderTest.maybePixels, 400 * curve.transform(0.25) + 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));

      pushTransition.tick(const Duration(milliseconds: 50));
      expect(geometryUnderTest.maybePixels, 400 * curve.transform(0.5) + 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));

      pushTransition.tick(const Duration(milliseconds: 50));
      expect(geometryUnderTest.maybePixels, 400 * curve.transform(0.75) + 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));

      pushTransition.tickAndSettle();
      expect(geometryUnderTest.maybePixels, 600);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));

      pushTransition.end();
      expect(geometryUnderTest.maybePixels, 600);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));
    });

    test('Animate offset when popping the current route', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        viewportSize: const Size(400, 800),
        initialRouteContentSize: const Size(400, 400),
        initialOffset: const SheetAnchor.proportional(0.5),
        initialMinOffset: const SheetAnchor.proportional(0.5),
        initialMaxOffset: const SheetAnchor.proportional(1),
      );

      final (newRoute, newRouteTransitionController) = _pushRoute(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        routeContentSize: const Size(400, 600),
        initialOffset: const SheetAnchor.proportional(1),
        minOffset: const SheetAnchor.proportional(1),
        maxOffset: const SheetAnchor.proportional(1),
        transitionDuration: const Duration(milliseconds: 200),
      );

      final popTransition = _startBackwardTransition(
        geometry: geometryUnderTest,
        currentRoute: newRoute,
        destinationRoute: initialRoute,
        currentRouteTransitionController: newRouteTransitionController,
      );

      popTransition.tick(Duration.zero);
      expect(geometryUnderTest.maybePixels, 600);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      const curve = kDefaultPagedSheetTransitionCurve;
      popTransition.tick(const Duration(milliseconds: 50));
      expect(
        geometryUnderTest.maybePixels,
        moreOrLessEquals(600 - 400 * curve.transform(0.25)),
      );
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      popTransition.tick(const Duration(milliseconds: 50));
      expect(
        geometryUnderTest.maybePixels,
        moreOrLessEquals(600 - 400 * curve.transform(0.5)),
      );
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      popTransition.tick(const Duration(milliseconds: 50));
      expect(
        geometryUnderTest.maybePixels,
        moreOrLessEquals(600 - 400 * curve.transform(0.75)),
      );
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      popTransition.tickAndSettle();
      expect(geometryUnderTest.maybePixels, 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      popTransition.end();
      expect(geometryUnderTest.maybePixels, 200);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));
    });

    test('Maintain offsets of each route throughout the transitions', () {});

    test('Sync offset with progress of the swipe-back gesture', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        viewportSize: const Size(400, 800),
        initialRouteContentSize: const Size(400, 400),
        initialOffset: const SheetAnchor.proportional(1),
        initialMinOffset: const SheetAnchor.proportional(1),
        initialMaxOffset: const SheetAnchor.proportional(1),
      );

      final (newRoute, newRouteTransitionController) = _pushRoute(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        routeContentSize: const Size(400, 600),
        initialOffset: const SheetAnchor.proportional(1),
        minOffset: const SheetAnchor.proportional(1),
        maxOffset: const SheetAnchor.proportional(1),
        transitionDuration: const Duration(milliseconds: 200),
      );

      final swipeBackGesture = _startUserGestureTransition(
        geometry: geometryUnderTest,
        currentRoute: newRoute,
        previousRoute: initialRoute,
        currentRouteTransitionController: newRouteTransitionController,
      );
      expect(geometryUnderTest.maybePixels, 600);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      swipeBackGesture.dragTo(0.75);
      expect(geometryUnderTest.maybePixels, 550);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      swipeBackGesture.dragTo(0.5);
      expect(geometryUnderTest.maybePixels, 500);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      swipeBackGesture.dragTo(0.25);
      expect(geometryUnderTest.maybePixels, 450);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      swipeBackGesture.releasePointer();
      expect(geometryUnderTest.maybePixels, 400);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 600));

      swipeBackGesture.end();
      expect(geometryUnderTest.maybePixels, 400);
      expect(geometryUnderTest.maybeContentSize, const Size(400, 400));
    });
  });
}

(MockBasePagedSheetRoute<dynamic>, TestAnimationController) _createRoute({
  required SheetAnchor initialOffset,
  required SheetAnchor minOffset,
  required SheetAnchor maxOffset,
  required Duration transitionDuration,
}) {
  final animationController = TestAnimationController(
    value: 0,
    duration: transitionDuration,
    reverseDuration: transitionDuration,
  );
  addTearDown(animationController.dispose);

  final route = MockBasePagedSheetRoute<dynamic>();
  when(route.initialOffset).thenReturn(initialOffset);
  when(route.minOffset).thenReturn(minOffset);
  when(route.maxOffset).thenReturn(maxOffset);

  return (route, animationController);
}

MockBasePagedSheetRoute<dynamic> _firstBuild({
  required PagedSheetGeometry geometry,
  required Size viewportSize,
  required Size initialRouteContentSize,
  required SheetAnchor initialOffset,
  required SheetAnchor initialMinOffset,
  required SheetAnchor initialMaxOffset,
}) {
  final (initialRoute, _) = _createRoute(
    initialOffset: initialOffset,
    minOffset: initialMinOffset,
    maxOffset: initialMaxOffset,
    transitionDuration: Duration.zero,
  );
  geometry
    ..applyNewViewportInsets(EdgeInsets.zero)
    ..applyNewViewportSize(viewportSize)
    ..addRoute(initialRoute)
    ..onTransition(NoRouteTransition(currentRoute: initialRoute))
    ..applyNewRouteContentSize(initialRoute, initialRouteContentSize)
    ..finalizePosition();

  return initialRoute;
}

typedef _TransitionHandle = ({
  void Function(Duration) tick,
  void Function() tickAndSettle,
  VoidCallback end,
});

_TransitionHandle _startForwardTransition({
  required PagedSheetGeometry geometry,
  required BasePagedSheetRoute currentRoute,
  required BasePagedSheetRoute newRoute,
  required Size newRouteContentSize,
  required TestAnimationController newRouteTransitionController,
}) {
  newRouteTransitionController.forward();
  geometry
    ..addRoute(newRoute)
    ..onTransition(
      ForwardRouteTransition(
        originRoute: currentRoute,
        destinationRoute: newRoute,
        animation: newRouteTransitionController,
      ),
    )
    ..applyNewRouteContentSize(newRoute, newRouteContentSize)
    ..finalizePosition();

  return (
    tick: (duration) {
      newRouteTransitionController.tick(duration);
      geometry.finalizePosition();
    },
    tickAndSettle: () {
      newRouteTransitionController.tickAndSettle();
      geometry.finalizePosition();
    },
    end: () {
      geometry
        ..onTransition(NoRouteTransition(currentRoute: newRoute))
        ..finalizePosition();
    },
  );
}

_TransitionHandle _startBackwardTransition({
  required PagedSheetGeometry geometry,
  required BasePagedSheetRoute currentRoute,
  required BasePagedSheetRoute destinationRoute,
  required TestAnimationController currentRouteTransitionController,
}) {
  currentRouteTransitionController.reverse();
  geometry
    ..onTransition(
      ForwardRouteTransition(
        originRoute: currentRoute,
        destinationRoute: destinationRoute,
        animation: currentRouteTransitionController.drive(
          Tween(begin: 1, end: 0),
        ),
      ),
    )
    ..finalizePosition();

  return (
    tick: (duration) {
      currentRouteTransitionController.tick(duration);
      geometry.finalizePosition();
    },
    tickAndSettle: () {
      currentRouteTransitionController.tickAndSettle();
      geometry.finalizePosition();
    },
    end: () {
      geometry
        ..onTransition(NoRouteTransition(currentRoute: destinationRoute))
        ..removeRoute(currentRoute)
        ..finalizePosition();
    },
  );
}

typedef _UserGestureTransitionHandle = ({
  ValueSetter<double> dragTo,
  VoidCallback releasePointer,
  VoidCallback end,
});

_UserGestureTransitionHandle _startUserGestureTransition({
  required PagedSheetGeometry geometry,
  required BasePagedSheetRoute currentRoute,
  required BasePagedSheetRoute previousRoute,
  required TestAnimationController currentRouteTransitionController,
}) {
  currentRouteTransitionController.value = 1;
  geometry
    ..onTransition(
      UserGestureRouteTransition(
        currentRoute: currentRoute,
        previousRoute: previousRoute,
        animation: currentRouteTransitionController.drive(
          Tween(begin: 1, end: 0),
        ),
      ),
    )
    ..finalizePosition();

  return (
    dragTo: (progress) {
      currentRouteTransitionController.value = progress;
      geometry.finalizePosition();
    },
    releasePointer: () {
      if (currentRouteTransitionController.value < 0.5) {
        currentRouteTransitionController.reverse();
      } else {
        currentRouteTransitionController.forward();
      }
      currentRouteTransitionController.tickAndSettle();
      geometry.finalizePosition();
    },
    end: () {
      geometry
        ..onTransition(
          NoRouteTransition(
            currentRoute: currentRouteTransitionController.isDismissed
                ? previousRoute
                : currentRoute,
          ),
        )
        ..finalizePosition();
    },
  );
}

(MockBasePagedSheetRoute<dynamic>, TestAnimationController) _pushRoute({
  required PagedSheetGeometry geometry,
  required BasePagedSheetRoute currentRoute,
  required Size routeContentSize,
  required SheetAnchor initialOffset,
  required SheetAnchor minOffset,
  required SheetAnchor maxOffset,
  required Duration transitionDuration,
}) {
  final (newRoute, controller) = _createRoute(
    initialOffset: initialOffset,
    minOffset: minOffset,
    maxOffset: maxOffset,
    transitionDuration: transitionDuration,
  );
  _startForwardTransition(
    geometry: geometry,
    currentRoute: currentRoute,
    newRoute: newRoute,
    newRouteContentSize: routeContentSize,
    newRouteTransitionController: controller,
  )
    ..tickAndSettle()
    ..end();

  return (newRoute, controller);
}

void _popRoute({
  required PagedSheetGeometry geometry,
  required BasePagedSheetRoute currentRoute,
  required BasePagedSheetRoute destinationRoute,
  required TestAnimationController currentRouteTransitionController,
}) {
  _startBackwardTransition(
    geometry: geometry,
    currentRoute: currentRoute,
    destinationRoute: destinationRoute,
    currentRouteTransitionController: currentRouteTransitionController,
  )
    ..tickAndSettle()
    ..end();
}

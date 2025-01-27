// ignore_for_file: prefer_const_constructors

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:smooth_sheets/src/foundation/activity.dart';
import 'package:smooth_sheets/src/foundation/model.dart';
import 'package:smooth_sheets/src/paged/paged_sheet_geometry.dart';
import 'package:smooth_sheets/src/paged/paged_sheet_route.dart';

import '../src/matchers.dart';
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
      expect(geometryUnderTest.value, isNull);
      expect(geometryUnderTest.hasMetrics, isFalse);
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());
    });

    test('First build', () {
      _firstBuild(
        geometry: geometryUnderTest,
        viewportSize: const Size(400, 800),
        initialRouteContentSize: const Size(400, 400),
        initialOffset: const SheetOffset.relative(0.5),
        initialMinOffset: const SheetOffset.relative(0.5),
        initialMaxOffset: const SheetOffset.relative(1),
      );

      expect(geometryUnderTest.offset, 200);
      expect(geometryUnderTest.minOffset, 200);
      expect(geometryUnderTest.maxOffset, 400);
      expect(
        geometryUnderTest.measurements,
        SheetMeasurements(
          contentSize: Size(400, 400),
          viewportSize: Size(400, 800),
          viewportInsets: EdgeInsets.zero,
        ),
      );
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());
    });

    test('Push a new route and then pop it', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        initialRouteContentSize: const Size(400, 400),
        viewportSize: const Size(400, 800),
        initialOffset: const SheetOffset.relative(0.5),
        initialMinOffset: const SheetOffset.relative(0.5),
        initialMaxOffset: const SheetOffset.relative(1),
      );

      final (newRoute, newRouteTransitionController) = _pushRoute(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        routeContentSize: const Size(400, 600),
        initialOffset: const SheetOffset.relative(1),
        minOffset: const SheetOffset.relative(1),
        maxOffset: const SheetOffset.relative(1),
        transitionDuration: const Duration(milliseconds: 200),
      );
      expect(geometryUnderTest.offset, 600);
      expect(geometryUnderTest.minOffset, 600);
      expect(geometryUnderTest.maxOffset, 600);
      expect(
        geometryUnderTest.measurements,
        SheetMeasurements(
          contentSize: Size(400, 600),
          viewportSize: Size(400, 800),
          viewportInsets: EdgeInsets.zero,
        ),
      );
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());

      _popRoute(
        geometry: geometryUnderTest,
        currentRoute: newRoute,
        destinationRoute: initialRoute,
        currentRouteTransitionController: newRouteTransitionController,
      );
      expect(geometryUnderTest.offset, 200);
      expect(geometryUnderTest.minOffset, 200);
      expect(geometryUnderTest.maxOffset, 400);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(
          contentSize: Size(400, 400),
          viewportSize: Size(400, 800),
          viewportInsets: EdgeInsets.zero,
        ),
      );
      expect(geometryUnderTest.activity, isA<IdleSheetActivity>());
    });
  });

  group('Transition test', () {
    test('Animate offset when pushing a new route', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        initialRouteContentSize: const Size(400, 400),
        viewportSize: const Size(400, 800),
        initialOffset: const SheetOffset.relative(0.5),
        initialMinOffset: const SheetOffset.relative(0.5),
        initialMaxOffset: const SheetOffset.relative(1),
      );

      final (newRoute, newRouteTransitionController) = _createRoute(
        initialOffset: const SheetOffset.relative(1),
        minOffset: const SheetOffset.relative(1),
        maxOffset: const SheetOffset.relative(1),
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
      expect(geometryUnderTest.offset, 200);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: Size(400, 400)),
      );

      const curve = kDefaultPagedSheetTransitionCurve;
      pushTransition.tick(const Duration(milliseconds: 50));
      expect(geometryUnderTest.offset, 400 * curve.transform(0.25) + 200);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 400)),
      );

      pushTransition.tick(const Duration(milliseconds: 50));
      expect(geometryUnderTest.offset, 400 * curve.transform(0.5) + 200);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 400)),
      );

      pushTransition.tick(const Duration(milliseconds: 50));
      expect(geometryUnderTest.offset, 400 * curve.transform(0.75) + 200);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 400)),
      );

      pushTransition.tickAndSettle();
      expect(geometryUnderTest.offset, 600);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 400)),
      );

      pushTransition.end();
      expect(geometryUnderTest.offset, 600);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );
    });

    test('Animate offset when popping the current route', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        viewportSize: const Size(400, 800),
        initialRouteContentSize: const Size(400, 400),
        initialOffset: const SheetOffset.relative(0.5),
        initialMinOffset: const SheetOffset.relative(0.5),
        initialMaxOffset: const SheetOffset.relative(1),
      );

      final (newRoute, newRouteTransitionController) = _pushRoute(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        routeContentSize: const Size(400, 600),
        initialOffset: const SheetOffset.relative(1),
        minOffset: const SheetOffset.relative(1),
        maxOffset: const SheetOffset.relative(1),
        transitionDuration: const Duration(milliseconds: 200),
      );

      final popTransition = _startBackwardTransition(
        geometry: geometryUnderTest,
        currentRoute: newRoute,
        destinationRoute: initialRoute,
        currentRouteTransitionController: newRouteTransitionController,
      );

      popTransition.tick(Duration.zero);
      expect(geometryUnderTest.offset, 600);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      const curve = kDefaultPagedSheetTransitionCurve;
      popTransition.tick(const Duration(milliseconds: 50));
      expect(
        geometryUnderTest.offset,
        moreOrLessEquals(600 - 400 * curve.transform(0.25)),
      );
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      popTransition.tick(const Duration(milliseconds: 50));
      expect(
        geometryUnderTest.offset,
        moreOrLessEquals(600 - 400 * curve.transform(0.5)),
      );
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      popTransition.tick(const Duration(milliseconds: 50));
      expect(
        geometryUnderTest.offset,
        moreOrLessEquals(600 - 400 * curve.transform(0.75)),
      );
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      popTransition.tickAndSettle();
      expect(geometryUnderTest.offset, 200);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      popTransition.end();
      expect(geometryUnderTest.offset, 200);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 400)),
      );
    });

    test('Maintain offsets of each route throughout the transitions', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        initialRouteContentSize: const Size(400, 400),
        viewportSize: const Size(400, 800),
        initialOffset: const SheetOffset.relative(0.5),
        initialMinOffset: const SheetOffset.relative(0.5),
        initialMaxOffset: const SheetOffset.relative(1),
      );

      final testActivity = _TestSheetActivity();
      geometryUnderTest.beginActivity(testActivity);
      testActivity.setOffset(400);
      expect(geometryUnderTest.offset, 400);

      final (newRoute, newRouteTransitionController) = _pushRoute(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        initialOffset: const SheetOffset.relative(1),
        minOffset: const SheetOffset.relative(1),
        maxOffset: const SheetOffset.relative(1),
        routeContentSize: const Size(400, 600),
        transitionDuration: const Duration(milliseconds: 200),
      );
      expect(geometryUnderTest.offset, 600);

      _popRoute(
        geometry: geometryUnderTest,
        currentRoute: newRoute,
        destinationRoute: initialRoute,
        currentRouteTransitionController: newRouteTransitionController,
      );
      expect(geometryUnderTest.offset, 450);
    });

    test('Sync offset with progress of the swipe-back gesture', () {
      final initialRoute = _firstBuild(
        geometry: geometryUnderTest,
        viewportSize: const Size(400, 800),
        initialRouteContentSize: const Size(400, 400),
        initialOffset: const SheetOffset.relative(1),
        initialMinOffset: const SheetOffset.relative(1),
        initialMaxOffset: const SheetOffset.relative(1),
      );

      final (newRoute, newRouteTransitionController) = _pushRoute(
        geometry: geometryUnderTest,
        currentRoute: initialRoute,
        routeContentSize: const Size(400, 600),
        initialOffset: const SheetOffset.relative(1),
        minOffset: const SheetOffset.relative(1),
        maxOffset: const SheetOffset.relative(1),
        transitionDuration: const Duration(milliseconds: 200),
      );

      final swipeBackGesture = _startUserGestureTransition(
        geometry: geometryUnderTest,
        currentRoute: newRoute,
        previousRoute: initialRoute,
        currentRouteTransitionController: newRouteTransitionController,
      );
      expect(geometryUnderTest.offset, 600);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      swipeBackGesture.dragTo(0.75);
      expect(geometryUnderTest.offset, 550);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      swipeBackGesture.dragTo(0.5);
      expect(geometryUnderTest.offset, 500);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      swipeBackGesture.dragTo(0.25);
      expect(geometryUnderTest.offset, 450);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      swipeBackGesture.releasePointer();
      expect(geometryUnderTest.offset, 400);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 600)),
      );

      swipeBackGesture.end();
      expect(geometryUnderTest.offset, 400);
      expect(
        geometryUnderTest.measurements,
        isMeasurements(contentSize: const Size(400, 400)),
      );
    });
  });
}

(MockBasePagedSheetRoute<dynamic>, TestAnimationController) _createRoute({
  required SheetOffset initialOffset,
  required SheetOffset minOffset,
  required SheetOffset maxOffset,
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
  required SheetOffset initialOffset,
  required SheetOffset initialMinOffset,
  required SheetOffset initialMaxOffset,
}) {
  final (initialRoute, _) = _createRoute(
    initialOffset: initialOffset,
    minOffset: initialMinOffset,
    maxOffset: initialMaxOffset,
    transitionDuration: Duration.zero,
  );
  geometry
    ..addRoute(initialRoute)
    ..didEndTransition(initialRoute)
    ..applyNewRouteContentSize(initialRoute, initialRouteContentSize)
    ..measurements = SheetMeasurements(
      contentSize: initialRouteContentSize,
      viewportSize: viewportSize,
      viewportInsets: EdgeInsets.zero,
    );

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
    ..didStartTransition(
      currentRoute,
      newRoute,
      newRouteTransitionController,
      isUserGestureInProgress: false,
    )
    ..applyNewRouteContentSize(newRoute, newRouteContentSize);

  return (
    tick: (duration) {
      newRouteTransitionController.tick(duration);
    },
    tickAndSettle: () {
      newRouteTransitionController.tickAndSettle();
    },
    end: () {
      geometry.didEndTransition(newRoute);
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
  geometry.didStartTransition(
    currentRoute,
    destinationRoute,
    currentRouteTransitionController,
  );

  return (
    tick: (duration) {
      currentRouteTransitionController.tick(duration);
    },
    tickAndSettle: () {
      currentRouteTransitionController.tickAndSettle();
    },
    end: () {
      geometry
        ..didEndTransition(destinationRoute)
        ..removeRoute(currentRoute);
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
  geometry.didStartTransition(
    currentRoute,
    previousRoute,
    currentRouteTransitionController,
    isUserGestureInProgress: true,
  );

  return (
    dragTo: (progress) {
      currentRouteTransitionController.value = progress;
    },
    releasePointer: () {
      if (currentRouteTransitionController.value < 0.5) {
        currentRouteTransitionController.reverse();
      } else {
        currentRouteTransitionController.forward();
      }
      currentRouteTransitionController.tickAndSettle();
    },
    end: () {
      geometry.didEndTransition(
        currentRouteTransitionController.isDismissed
            ? previousRoute
            : currentRoute,
      );
    },
  );
}

(MockBasePagedSheetRoute<dynamic>, TestAnimationController) _pushRoute({
  required PagedSheetGeometry geometry,
  required BasePagedSheetRoute currentRoute,
  required Size routeContentSize,
  required SheetOffset initialOffset,
  required SheetOffset minOffset,
  required SheetOffset maxOffset,
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

class _TestSheetActivity extends SheetActivity {
  void setOffset(double offset) => owner.setOffset(offset);
}

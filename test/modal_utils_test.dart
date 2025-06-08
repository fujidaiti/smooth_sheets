import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

class _MaterialBoilerplate extends StatelessWidget {
  const _MaterialBoilerplate({
    required this.onPressed,
    this.platform = TargetPlatform.android,
  });

  final VoidCallback onPressed;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: onPressed,
            child: const Text('Open modal'),
          ),
        ),
      ),
    );
  }
}

class _CupertinoBoilerplate extends StatelessWidget {
  const _CupertinoBoilerplate({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: CupertinoButton.filled(
            onPressed: onPressed,
            child: const Text('Open modal'),
          ),
        ),
      ),
    );
  }
}

Widget _testSheet({Key? key}) {
  return Sheet(
    child: Container(
      key: key ?? const Key('sheet'),
      color: Colors.white,
      width: double.infinity,
      height: 400,
    ),
  );
}

void main() {
  group('showAdaptiveModalSheet', () {
    testWidgets(
      'should show CupertinoModalSheet on iOS platform',
      (tester) async {
        Future<String?>? result;

        await tester.pumpWidget(
          _MaterialBoilerplate(
            platform: TargetPlatform.iOS,
            onPressed: () {
              result = showAdaptiveModalSheet<String>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sheet')), findsOneWidget);
        expect(result, isA<Future<String?>>());

        // Verify it's a Cupertino modal by checking the route type
        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!;
        expect(route, isA<CupertinoModalSheetRoute<dynamic>>());
      },
    );

    testWidgets(
      'should show CupertinoModalSheet on macOS platform',
      (tester) async {
        Future<String?>? result;

        await tester.pumpWidget(
          _MaterialBoilerplate(
            platform: TargetPlatform.macOS,
            onPressed: () {
              result = showAdaptiveModalSheet<String>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sheet')), findsOneWidget);
        expect(result, isA<Future<String?>>());

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!;
        expect(route, isA<CupertinoModalSheetRoute<dynamic>>());
      },
    );

    void testMaterialPlatform(String description, TargetPlatform platform) {
      testWidgets(description, (tester) async {
        Future<String?>? result;

        await tester.pumpWidget(
          _MaterialBoilerplate(
            platform: platform,
            onPressed: () {
              result = showAdaptiveModalSheet<String>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sheet')), findsOneWidget);
        expect(result, isA<Future<String?>>());

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!;
        expect(route, isA<ModalSheetRoute<dynamic>>());
      });
    }

    testMaterialPlatform(
        'should show ModalSheet on Android platform', TargetPlatform.android);
    testMaterialPlatform(
        'should show ModalSheet on Fuchsia platform', TargetPlatform.fuchsia);
    testMaterialPlatform(
        'should show ModalSheet on Linux platform', TargetPlatform.linux);
    testMaterialPlatform(
        'should show ModalSheet on Windows platform', TargetPlatform.windows);

    testWidgets(
      'should pass through all parameters correctly',
      (tester) async {
        const testKey = Key('custom-sheet');
        const testColor = Colors.red;
        const testDuration = Duration(milliseconds: 500);
        const testCurve = Curves.bounceIn;
        const testSensitivity = SwipeDismissSensitivity(
          minDragDistance: 50,
          minFlingVelocityRatio: 2.0,
        );

        await tester.pumpWidget(
          _MaterialBoilerplate(
            platform: TargetPlatform.android,
            onPressed: () {
              showAdaptiveModalSheet<void>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(key: testKey),
                useRootNavigator: false,
                barrierDismissible: false,
                swipeDismissible: true,
                barrierLabel: 'Test barrier',
                barrierColor: testColor,
                transitionDuration: testDuration,
                transitionCurve: testCurve,
                swipeDismissSensitivity: testSensitivity,
                routeSettings: const RouteSettings(name: 'test-route'),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(find.byKey(testKey), findsOneWidget);

        final route = ModalRoute.of(tester.element(find.byKey(testKey)))!
            as ModalSheetRoute<dynamic>;
        expect(route.barrierDismissible, isFalse);
        expect(route.barrierColor, testColor);
        expect(route.transitionDuration, testDuration);
        expect(route.settings.name, 'test-route');
      },
    );
  });

  group('showModalSheet', () {
    testWidgets(
      'should create and push ModalSheetRoute',
      (tester) async {
        Future<int?>? result;

        await tester.pumpWidget(
          _MaterialBoilerplate(
            onPressed: () {
              result = showModalSheet<int>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sheet')), findsOneWidget);
        expect(result, isA<Future<int?>>());

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!;
        expect(route, isA<ModalSheetRoute<int>>());
      },
    );

    testWidgets(
      'should apply default values correctly',
      (tester) async {
        await tester.pumpWidget(
          _MaterialBoilerplate(
            onPressed: () {
              showModalSheet<void>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
                as ModalSheetRoute<dynamic>;

        expect(route.barrierColor, Colors.black54);
        expect(route.transitionDuration, const Duration(milliseconds: 300));
        expect(route.transitionCurve, Curves.fastEaseInToSlowEaseOut);
        expect(route.barrierDismissible, isTrue);
        expect(route.maintainState, isTrue);
      },
    );

    testWidgets(
      'should handle custom parameters',
      (tester) async {
        const testColor = Colors.blue;
        const testDuration = Duration(milliseconds: 600);
        const testCurve = Curves.elasticIn;
        const testSensitivity = SwipeDismissSensitivity(
          minDragDistance: 75,
          minFlingVelocityRatio: 1.5,
        );
        const testPadding = EdgeInsets.all(16);

        await tester.pumpWidget(
          _MaterialBoilerplate(
            onPressed: () {
              showModalSheet<void>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
                useRootNavigator: false,
                maintainState: false,
                barrierDismissible: false,
                swipeDismissible: true,
                fullscreenDialog: true,
                barrierLabel: 'Custom barrier',
                barrierColor: testColor,
                transitionDuration: testDuration,
                transitionCurve: testCurve,
                swipeDismissSensitivity: testSensitivity,
                viewportPadding: testPadding,
                routeSettings: const RouteSettings(name: 'custom-modal'),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
                as ModalSheetRoute<dynamic>;

        expect(route.barrierColor, testColor);
        expect(route.transitionDuration, testDuration);
        expect(route.transitionCurve, testCurve);
        expect(route.barrierDismissible, isFalse);
        expect(route.maintainState, isFalse);
        expect(route.fullscreenDialog, isTrue);
        expect(route.settings.name, 'custom-modal');
      },
    );

    testWidgets(
      'should return result when modal is popped',
      (tester) async {
        const testResult = 42;
        late Future<int?> result;

        await tester.pumpWidget(
          _MaterialBoilerplate(
            onPressed: () {
              result = showModalSheet<int>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.pop(context, testResult),
                  child: const Text('Close with result'),
                ),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close with result'));
        await tester.pumpAndSettle();

        expect(await result, testResult);
      },
    );
  });

  group('showCupertinoModalSheet', () {
    testWidgets(
      'should create and push CupertinoModalSheetRoute',
      (tester) async {
        Future<int?>? result;

        await tester.pumpWidget(
          _CupertinoBoilerplate(
            onPressed: () {
              result = showCupertinoModalSheet<int>(
                context: tester.element(find.byType(CupertinoPageScaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.byType(CupertinoButton));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sheet')), findsOneWidget);
        expect(result, isA<Future<int?>>());

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!;
        expect(route, isA<CupertinoModalSheetRoute<int>>());
      },
    );

    testWidgets(
      'should apply default values correctly',
      (tester) async {
        await tester.pumpWidget(
          _CupertinoBoilerplate(
            onPressed: () {
              showCupertinoModalSheet<void>(
                context: tester.element(find.byType(CupertinoPageScaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.byType(CupertinoButton));
        await tester.pumpAndSettle();

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
                as CupertinoModalSheetRoute<dynamic>;

        expect(route.transitionDuration, const Duration(milliseconds: 300));
        expect(route.transitionCurve, Curves.fastEaseInToSlowEaseOut);
        expect(route.barrierDismissible, isTrue);
        expect(route.maintainState, isTrue);
      },
    );

    testWidgets(
      'should handle custom parameters',
      (tester) async {
        const testColor = Colors.purple;
        const testDuration = Duration(milliseconds: 450);
        const testCurve = Curves.bounceOut;
        const testSensitivity = SwipeDismissSensitivity(
          minDragDistance: 60,
          minFlingVelocityRatio: 3.0,
        );

        await tester.pumpWidget(
          _CupertinoBoilerplate(
            onPressed: () {
              showCupertinoModalSheet<void>(
                context: tester.element(find.byType(CupertinoPageScaffold)),
                builder: (context) => _testSheet(),
                useRootNavigator: false,
                maintainState: false,
                barrierDismissible: false,
                swipeDismissible: true,
                barrierLabel: 'Cupertino barrier',
                barrierColor: testColor,
                transitionDuration: testDuration,
                transitionCurve: testCurve,
                swipeDismissSensitivity: testSensitivity,
                routeSettings: const RouteSettings(name: 'cupertino-modal'),
              );
            },
          ),
        );

        await tester.tap(find.byType(CupertinoButton));
        await tester.pumpAndSettle();

        final route =
            ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
                as CupertinoModalSheetRoute<dynamic>;

        expect(route.barrierColor, testColor);
        expect(route.transitionDuration, testDuration);
        expect(route.transitionCurve, testCurve);
        expect(route.barrierDismissible, isFalse);
        expect(route.maintainState, isFalse);
        expect(route.settings.name, 'cupertino-modal');
      },
    );

    testWidgets(
      'should return result when modal is popped',
      (tester) async {
        const testResult = 'cupertino_result';
        late Future<String?> result;

        await tester.pumpWidget(
          _CupertinoBoilerplate(
            onPressed: () {
              result = showCupertinoModalSheet<String>(
                context: tester.element(find.byType(CupertinoPageScaffold)),
                builder: (context) => CupertinoButton.filled(
                  onPressed: () => Navigator.pop(context, testResult),
                  child: const Text('Close with result'),
                ),
              );
            },
          ),
        );

        await tester.tap(find.byType(CupertinoButton).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close with result'));
        await tester.pumpAndSettle();

        expect(await result, testResult);
      },
    );
  });

  group('Edge cases', () {
    testWidgets(
      'should work with null result type',
      (tester) async {
        late Future<void> result;

        await tester.pumpWidget(
          _MaterialBoilerplate(
            onPressed: () {
              result = showModalSheet<void>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        Navigator.pop(tester.element(find.byKey(const Key('sheet'))));
        await tester.pumpAndSettle();

        await result;
      },
    );

    testWidgets(
      'should handle barrier tap dismissal',
      (tester) async {
        late Future<String?> result;

        await tester.pumpWidget(
          _MaterialBoilerplate(
            onPressed: () {
              result = showAdaptiveModalSheet<String>(
                context: tester.element(find.byType(Scaffold)),
                builder: (context) => _testSheet(),
                barrierDismissible: true,
              );
            },
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('sheet')), findsOneWidget);

        // Tap on barrier to dismiss
        await tester
            .tapAt(const Offset(50, 50)); // Top-left corner should be barrier
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sheet')), findsNothing);
        expect(await result, isNull);
      },
    );
  });
}

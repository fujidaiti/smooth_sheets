import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('showModalSheet', () {
    testWidgets('creates and pushes ModalSheetRoute with default parameters',
        (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    buttonPressed = true;
                    await showModalSheet<String>(
                      context: context,
                      builder: (context) => const Text('Modal Sheet Content'),
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(buttonPressed, isTrue);
      expect(find.text('Modal Sheet Content'), findsOneWidget);
    });

    testWidgets('accepts custom parameters', (tester) async {
      const customColor = Colors.red;
      const customDuration = Duration(milliseconds: 500);
      const customCurve = Curves.bounceIn;
      const customPadding = EdgeInsets.all(16);

      late ModalSheetRoute<String> route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showModalSheet<String>(
                      context: context,
                      builder: (context) {
                        route =
                            ModalRoute.of(context)! as ModalSheetRoute<String>;
                        return const Text('Custom Modal');
                      },
                      barrierColor: customColor,
                      transitionDuration: customDuration,
                      transitionCurve: customCurve,
                      viewportPadding: customPadding,
                      swipeDismissible: true,
                      maintainState: false,
                    );
                  },
                  child: const Text('Open Custom Modal'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Custom Modal'));
      await tester.pumpAndSettle();

      expect(route.barrierColor, equals(customColor));
      expect(route.transitionDuration, equals(customDuration));
      expect(route.transitionCurve, equals(customCurve));
      expect(route.viewportPadding, equals(customPadding));
      expect(route.swipeDismissible, isTrue);
      expect(route.maintainState, isFalse);
    });

    testWidgets('returns value when popped', (tester) async {
      const expectedResult = 'test result';
      String? actualResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    actualResult = await showModalSheet<String>(
                      context: context,
                      builder: (context) => ElevatedButton(
                        onPressed: () => Navigator.pop(context, expectedResult),
                        child: const Text('Close with Result'),
                      ),
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close with Result'));
      await tester.pumpAndSettle();

      expect(actualResult, equals(expectedResult));
    });
  });

  group('showCupertinoModalSheet', () {
    testWidgets('creates and pushes CupertinoModalSheetRoute', (tester) async {
      late CupertinoModalSheetRoute<String> capturedRoute;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              return CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    onPressed: () async {
                      await showCupertinoModalSheet<String>(
                        context: context,
                        builder: (context) {
                          capturedRoute = ModalRoute.of(context)!
                              as CupertinoModalSheetRoute<String>;
                          return const Text('Cupertino Modal Content');
                        },
                      );
                    },
                    child: const Text('Open Cupertino Modal'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Cupertino Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Cupertino Modal Content'), findsOneWidget);
      expect(capturedRoute, isA<CupertinoModalSheetRoute<String>>());
    });

    testWidgets('accepts custom parameters', (tester) async {
      const customDuration = Duration(milliseconds: 400);
      const customCurve = Curves.elasticIn;

      late CupertinoModalSheetRoute<String> route;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              return CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    onPressed: () async {
                      await showCupertinoModalSheet<String>(
                        context: context,
                        builder: (context) {
                          route = ModalRoute.of(context)!
                              as CupertinoModalSheetRoute<String>;
                          return const Text('Custom Cupertino Modal');
                        },
                        transitionDuration: customDuration,
                        transitionCurve: customCurve,
                        swipeDismissible: true,
                        barrierDismissible: false,
                      );
                    },
                    child: const Text('Open Custom Cupertino Modal'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Custom Cupertino Modal'));
      await tester.pumpAndSettle();

      expect(route.transitionDuration, equals(customDuration));
      expect(route.transitionCurve, equals(customCurve));
      expect(route.swipeDismissible, isTrue);
      expect(route.barrierDismissible, isFalse);
    });
  });

  group('showAdaptiveModalSheet', () {
    testWidgets('uses ModalSheetRoute on non-Cupertino platforms',
        (tester) async {
      // Override platform for this test
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      late Route<String> capturedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) {
                        capturedRoute = ModalRoute.of(context)!;
                        return const Text('Adaptive Modal Content');
                      },
                    );
                  },
                  child: const Text('Open Adaptive Modal'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Modal Content'), findsOneWidget);
      expect(capturedRoute, isA<ModalSheetRoute<String>>());

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('uses CupertinoModalSheetRoute on iOS platform',
        (tester) async {
      // Override platform for this test
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      late Route<String> capturedRoute;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              return CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    onPressed: () async {
                      await showAdaptiveModalSheet<String>(
                        context: context,
                        builder: (context) {
                          capturedRoute = ModalRoute.of(context)!;
                          return const Text('Adaptive iOS Modal Content');
                        },
                      );
                    },
                    child: const Text('Open Adaptive Modal'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Adaptive iOS Modal Content'), findsOneWidget);
      expect(capturedRoute, isA<CupertinoModalSheetRoute<String>>());

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('uses CupertinoModalSheetRoute on macOS platform',
        (tester) async {
      // Override platform for this test
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      late Route<String> capturedRoute;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              return CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    onPressed: () async {
                      await showAdaptiveModalSheet<String>(
                        context: context,
                        builder: (context) {
                          capturedRoute = ModalRoute.of(context)!;
                          return const Text('Adaptive macOS Modal Content');
                        },
                      );
                    },
                    child: const Text('Open Adaptive Modal'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Adaptive macOS Modal Content'), findsOneWidget);
      expect(capturedRoute, isA<CupertinoModalSheetRoute<String>>());

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('forwards parameters correctly to underlying implementations',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      late ModalSheetRoute<String> route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) {
                        route =
                            ModalRoute.of(context)! as ModalSheetRoute<String>;
                        return const Text('Adaptive Modal');
                      },
                      swipeDismissible: true,
                      barrierDismissible: false,
                      maintainState: false,
                    );
                  },
                  child: const Text('Open Adaptive Modal'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Adaptive Modal'));
      await tester.pumpAndSettle();

      expect(route.swipeDismissible, isTrue);
      expect(route.barrierDismissible, isFalse);
      expect(route.maintainState, isFalse);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Navigation behavior', () {
    testWidgets('all functions respect useRootNavigator parameter',
        (tester) async {
      final rootNavigatorKey = GlobalKey<NavigatorState>();
      final nestedNavigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: Scaffold(
            body: Navigator(
              key: nestedNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => Builder(
                  builder: (context) {
                    return Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => showModalSheet<void>(
                            context: context,
                            useRootNavigator: true,
                            builder: (context) =>
                                const Text('Root Navigator Modal'),
                          ),
                          child: const Text('Open with Root Navigator'),
                        ),
                        ElevatedButton(
                          onPressed: () => showModalSheet<void>(
                            context: context,
                            useRootNavigator: false,
                            builder: (context) =>
                                const Text('Nested Navigator Modal'),
                          ),
                          child: const Text('Open with Nested Navigator'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Test with root navigator
      await tester.tap(find.text('Open with Root Navigator'));
      await tester.pumpAndSettle();
      expect(find.text('Root Navigator Modal'), findsOneWidget);
      expect(rootNavigatorKey.currentState!.canPop(), isTrue);

      // Close modal
      Navigator.of(tester.element(find.text('Root Navigator Modal')),
              rootNavigator: true)
          .pop();
      await tester.pumpAndSettle();

      // Test with nested navigator
      await tester.tap(find.text('Open with Nested Navigator'));
      await tester.pumpAndSettle();
      expect(find.text('Nested Navigator Modal'), findsOneWidget);
      expect(nestedNavigatorKey.currentState!.canPop(), isTrue);
    });
  });
}

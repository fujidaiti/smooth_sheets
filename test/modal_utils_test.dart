import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('showAdaptiveModalSheet', () {
    testWidgets('uses CupertinoModalSheetRoute on iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('sheet-content'),
                        child: const Text('Test Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(find.byKey(const ValueKey('sheet-content')), findsOneWidget);
    });

    testWidgets('uses CupertinoModalSheetRoute on macOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('sheet-content'),
                        child: const Text('Test Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(find.byKey(const ValueKey('sheet-content')), findsOneWidget);
    });

    testWidgets('uses ModalSheetRoute on Android', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('sheet-content'),
                        child: const Text('Test Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(find.byKey(const ValueKey('sheet-content')), findsOneWidget);
    });

    testWidgets('passes parameters correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showAdaptiveModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('sheet-content'),
                        child: const Text('Test Sheet'),
                      ),
                      swipeDismissible: true,
                      barrierDismissible: false,
                      maintainState: false,
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(find.byKey(const ValueKey('sheet-content')), findsOneWidget);
    });
  });

  group('showModalSheet', () {
    testWidgets('creates and pushes ModalSheetRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('modal-sheet-content'),
                        child: const Text('Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Modal Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Modal Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(
        find.byKey(const ValueKey('modal-sheet-content')),
        findsOneWidget,
      );
    });

    testWidgets('passes all parameters to ModalSheetRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('modal-sheet-content'),
                        child: const Text('Modal Sheet'),
                      ),
                      swipeDismissible: true,
                      barrierDismissible: false,
                      maintainState: false,
                      barrierColor: Colors.red.withValues(alpha: 0.5),
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionCurve: Curves.easeIn,
                    );
                  },
                  child: const Text('Open Modal Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Modal Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(
        find.byKey(const ValueKey('modal-sheet-content')),
        findsOneWidget,
      );
    });

    testWidgets('respects useRootNavigator parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showModalSheet<String>(
                      context: context,
                      useRootNavigator: false,
                      builder: (context) => Container(
                        key: const ValueKey('nested-modal-sheet'),
                        child: const Text('Nested Modal Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Nested Modal Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Nested Modal Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(
        find.byKey(const ValueKey('nested-modal-sheet')),
        findsOneWidget,
      );
    });
  });

  group('showCupertinoModalSheet', () {
    testWidgets('creates and pushes CupertinoModalSheetRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showCupertinoModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('cupertino-sheet-content'),
                        child: const Text('Cupertino Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Cupertino Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Cupertino Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(
        find.byKey(const ValueKey('cupertino-sheet-content')),
        findsOneWidget,
      );
    });

    testWidgets('passes all parameters to CupertinoModalSheetRoute',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showCupertinoModalSheet<String>(
                      context: context,
                      builder: (context) => Container(
                        key: const ValueKey('cupertino-sheet-content'),
                        child: const Text('Cupertino Sheet'),
                      ),
                      swipeDismissible: true,
                      barrierDismissible: false,
                      maintainState: false,
                      barrierColor: Colors.blue.withValues(alpha: 0.3),
                      transitionDuration: const Duration(milliseconds: 400),
                      transitionCurve: Curves.easeOut,
                    );
                  },
                  child: const Text('Open Cupertino Sheet'),
                ),
              );
            },
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Cupertino Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(
        find.byKey(const ValueKey('cupertino-sheet-content')),
        findsOneWidget,
      );
    });

    testWidgets('respects useRootNavigator parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showCupertinoModalSheet<String>(
                      context: context,
                      useRootNavigator: false,
                      builder: (context) => Container(
                        key: const ValueKey('nested-cupertino-sheet'),
                        child: const Text('Nested Cupertino Sheet'),
                      ),
                    );
                  },
                  child: const Text('Open Nested Cupertino Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap the button to open the sheet
      await tester.tap(find.text('Open Nested Cupertino Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet content is shown
      expect(
        find.byKey(const ValueKey('nested-cupertino-sheet')),
        findsOneWidget,
      );
    });
  });
}

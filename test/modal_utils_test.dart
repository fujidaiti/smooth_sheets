import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  group('showModalSheet', () {
    testWidgets('It pushes a ModalSheetRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showModalSheet<void>(
                  context: context,
                  builder: (context) => const SizedBox(),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump(); // Start animation
      await tester.pump(); // Let it finish

      expect(tester.pageRoute, isA<ModalSheetRoute<void>>());
    });
  });

  group('showCupertinoModalSheet', () {
    testWidgets('It pushes a CupertinoModalSheetRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showCupertinoModalSheet<void>(
                  context: context,
                  builder: (context) => const SizedBox(),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump(); // Start animation
      await tester.pump(); // Let it finish

      expect(tester.pageRoute, isA<CupertinoModalSheetRoute<void>>());
    });
  });

  group('showAdaptiveModalSheet', () {
    for (final platform in TargetPlatform.values) {
      testWidgets('It pushes a correct route on $platform', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: platform),
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showAdaptiveModalSheet<void>(
                    context: context,
                    builder: (context) => const SizedBox(),
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump(); // Start animation
        await tester.pump(); // Let it finish

        switch (platform) {
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            expect(tester.pageRoute, isA<CupertinoModalSheetRoute<void>>());
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            expect(tester.pageRoute, isA<ModalSheetRoute<void>>());
        }
      });
    }
  });
}

extension on WidgetTester {
  PageRoute<dynamic>? get pageRoute {
    if (any(find.byType(Navigator))) {
      final navigator = widget<Navigator>(find.byType(Navigator));
      final navigatorState =
          (navigator.key as GlobalObjectKey<NavigatorState>).currentState;
      // This is a bit of a hack to get the history, but it's needed for testing.
      // Trying to access private members to get the route history.
      dynamic last;
      navigatorState?.popUntil((route) {
        last = route;
        return true;
      });
      return last as PageRoute<dynamic>?;
    }
    return null;
  }
}

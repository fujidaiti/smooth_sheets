import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

const _sheetKey = Key('modal-sheet');
const _firstSheetPageKey = Key('first-sheet-page');
const _secondSheetPageKey = Key('second-sheet-page');

void main() {
  testWidgets('Basic behaviors', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        firstPageConfig: (
          height: 300,
          initialOffset: const SheetOffset(1),
          snapGrid: const SheetSnapGrid(
            snaps: [SheetOffset(0.5), SheetOffset(1)],
          ),
        ),
        secondPageConfig: (
          height: 600,
          initialOffset: const SheetOffset(1),
          snapGrid: const SheetSnapGrid.stepless(),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetKey), findsOneWidget);
    expect(find.byKey(_firstSheetPageKey), findsOneWidget);
    expect(
      tester.getRect(find.byKey(_sheetKey)),
      Rect.fromLTRB(0, 300, 800, 600),
      reason: 'The sheet should be fully visible at full extent',
    );

    await tester.tap(find.text('Go to second page'));
    await tester.pumpAndSettle();
    expect(find.byKey(_secondSheetPageKey), findsOneWidget);
    expect(
      tester.getRect(find.byKey(_sheetKey)),
      Rect.fromLTRB(0, 0, 800, 600),
      reason: 'The sheet should be fully visible',
    );

    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.byKey(_firstSheetPageKey), findsOneWidget);
    expect(find.byKey(_secondSheetPageKey), findsNothing);
    expect(
      tester.getRect(find.byKey(_sheetKey)),
      Rect.fromLTRB(0, 300, 800, 600),
      reason: 'The sheet should be fully visible',
    );

    // Go to the second page again.
    await tester.tap(find.text('Go to second page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close sheet'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(_sheetKey),
      findsNothing,
      reason: 'The sheet should be closed',
    );
  });

  // Regression test for https://github.com/fujidaiti/smooth_sheets/issues/188
  testWidgets(
    'context.replace should animate sheet extent',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          firstPageConfig: (
            height: 300,
            initialOffset: const SheetOffset(1),
            snapGrid: const SheetSnapGrid.stepless(),
          ),
          secondPageConfig: (
            height: 500,
            initialOffset: const SheetOffset(1),
            snapGrid: const SheetSnapGrid.stepless(),
          ),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(_firstSheetPageKey), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_sheetKey)),
        Rect.fromLTRB(0, 300, 800, 600),
      );

      // Use context.replace to replace the current page (GoRouter replace).
      await tester.tap(find.text('Replace with second page'));
      await tester.pumpAndSettle();

      expect(find.byKey(_firstSheetPageKey), findsNothing);
      expect(find.byKey(_secondSheetPageKey), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_sheetKey)),
        Rect.fromLTRB(0, 100, 800, 600),
        reason: 'The sheet extent should have animated to the new height',
      );
    },
  );
}

typedef _SheetPageConfig = ({
  double height,
  SheetSnapGrid snapGrid,
  SheetOffset initialOffset,
});

class _TestApp extends StatelessWidget {
  _TestApp({
    required this.firstPageConfig,
    required this.secondPageConfig,
  });

  final _SheetPageConfig firstPageConfig;
  final _SheetPageConfig secondPageConfig;

  late final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _HomePage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return _SheetShell(nestedNavigator: child);
        },
        routes: [
          GoRoute(
            path: '/sheet/first',
            pageBuilder: (context, state) {
              return PagedSheetPage(
                key: state.pageKey,
                initialOffset: firstPageConfig.initialOffset,
                snapGrid: firstPageConfig.snapGrid,
                child: _FirstSheetPage(height: firstPageConfig.height),
              );
            },
          ),
          GoRoute(
            path: '/sheet/second',
            pageBuilder: (context, state) {
              return PagedSheetPage(
                key: state.pageKey,
                initialOffset: secondPageConfig.initialOffset,
                snapGrid: secondPageConfig.snapGrid,
                child: _SecondSheetPage(height: secondPageConfig.height),
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/sheet/first'),
          child: const Text('Open sheet'),
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.nestedNavigator});

  final Widget nestedNavigator;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Scaffold(),
        SheetViewport(
          child: PagedSheet(
            key: _sheetKey,
            decoration: MaterialSheetDecoration(
              size: SheetSize.stretch,
              color: Colors.white,
            ),
            navigator: nestedNavigator,
          ),
        ),
      ],
    );
  }
}

class _FirstSheetPage extends StatelessWidget {
  const _FirstSheetPage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      key: _firstSheetPageKey,
      size: Size.fromHeight(height),
      child: Container(
        color: Colors.blue.shade200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.go('/sheet/second'),
              child: const Text('Go to second page'),
            ),
            TextButton(
              onPressed: () => context.replace('/sheet/second'),
              child: const Text('Replace with second page'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondSheetPage extends StatelessWidget {
  const _SecondSheetPage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      key: _secondSheetPageKey,
      size: Size.fromHeight(height),
      child: ColoredBox(
        color: Colors.purple.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.go('/sheet/first'),
              child: const Text('Go back'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Close sheet'),
            ),
          ],
        ),
      ),
    );
  }
}

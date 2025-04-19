import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

const _sheetKey = Key('modal-sheet');
const _firstSheetPageKey = Key('first-sheet-page');
const _secondSheetPageKey = Key('second-sheet-page');

void main() {
  Future<void> pumpTestApp(WidgetTester tester, RootStackRouter router) async {
    await tester.pumpWidget(_TestApp(router: router));
    // Auto-route needs additional frame to build the Navigator.
    await tester.pump();
  }

  testWidgets('Basic behaviors', (tester) async {
    await pumpTestApp(
      tester,
      _TestRouter(
        firstPageConfig: (
          height: 300,
          initialOffset: const SheetOffset(0.5),
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
      Rect.fromLTRB(0, 450, 800, 750),
      reason: 'The half of the sheet should be out of the screen',
    );

    await tester.flingFrom(Offset(400, 500), Offset(0, -50), 1000);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_sheetKey)),
      Rect.fromLTRB(0, 300, 800, 600),
      reason: 'The sheet should be fully visible',
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
      reason: 'The modal sheet should be closed',
    );
  });

  group('Regression test', () {
    // https://github.com/fujidaiti/smooth_sheets/issues/315
    testWidgets(
      'Initial offset is ignored when sheet is fullscreen on first build',
      (tester) async {
        await pumpTestApp(
          tester,
          _TestRouter(
            firstPageConfig: (
              height: 600,
              initialOffset: const SheetOffset(0.5),
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
          Rect.fromLTRB(0, 300, 800, 900),
          reason: 'The half of the sheet should be out of the screen',
        );
      },
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.router});

  final RootStackRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router.config(),
    );
  }
}

typedef _SheetPageConfig = ({
  double height,
  SheetSnapGrid snapGrid,
  SheetOffset initialOffset,
});

class _TestRouter extends RootStackRouter {
  _TestRouter({
    required this.firstPageConfig,
    required this.secondPageConfig,
  });

  final _SheetPageConfig firstPageConfig;
  final _SheetPageConfig secondPageConfig;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: PageInfo(
            '_HomeRoute',
            builder: (data) {
              return _HomePage();
            },
          ),
        ),
        CustomRoute<dynamic>(
          path: '/modal',
          page: PageInfo(
            '_ModalSheetRoute',
            builder: (data) {
              return _ModalSheetPage();
            },
          ),
          customRouteBuilder: <T>(context, child, page) {
            // Use ModalSheetRoute to show the sheet as a modal.
            return ModalSheetRoute(
              settings: page, // required
              builder: (_) => child,
            );
          },
          children: [
            CustomRoute<dynamic>(
              initial: true,
              path: 'first',
              page: PageInfo(
                '_FirstSheetRoute',
                builder: (data) {
                  return _FirstSheetPage(
                    height: firstPageConfig.height,
                  );
                },
              ),
              customRouteBuilder: <T>(context, child, page) {
                // Each route in the PagedSheet must be a PagedSheetRoute.
                return PagedSheetRoute(
                  settings: page, // required
                  initialOffset: firstPageConfig.initialOffset,
                  snapGrid: firstPageConfig.snapGrid,
                  builder: (_) => child,
                );
              },
            ),
            CustomRoute<dynamic>(
              path: 'second',
              page: PageInfo(
                '_SecondSheetRoute',
                builder: (data) {
                  return _SecondSheetPage(height: secondPageConfig.height);
                },
              ),
              customRouteBuilder: <T>(context, child, page) {
                return PagedSheetRoute(
                  settings: page, // required
                  initialOffset: secondPageConfig.initialOffset,
                  snapGrid: secondPageConfig.snapGrid,
                  builder: (_) => child,
                );
              },
            ),
          ],
        ),
      ];
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => AutoRouter.of(context).pushPath('/modal'),
          child: const Text('Open sheet'),
        ),
      ),
    );
  }
}

class _ModalSheetPage extends StatelessWidget {
  const _ModalSheetPage();

  @override
  Widget build(BuildContext context) {
    return PagedSheet(
      key: _sheetKey,
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        color: Colors.white,
      ),
      navigator: AutoRouter(),
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
        child: TextButton(
          onPressed: () => AutoRouter.of(context).pushPath('second'),
          child: const Text('Go to second page'),
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
              onPressed: () => AutoRouter.of(context).pop(),
              child: const Text('Go back'),
            ),
            const SizedBox(height: 16),
            TextButton(
              // Call pop() on the root router to pop the entire sheet.
              onPressed: () => AutoRouter.of(context).root.pop(),
              child: const Text('Close sheet'),
            ),
          ],
        ),
      ),
    );
  }
}

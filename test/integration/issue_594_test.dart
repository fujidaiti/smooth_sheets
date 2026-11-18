// Regression test for https://github.com/fujidaiti/smooth_sheets/issues/594
//
// An auto_route `EmptyShellRoute` inserts an extra "invisible" Navigator
// layer between `PagedSheet.navigator` and the actual `PagedSheetRoute`.
// This is a deeper variant of issue #315: `AutoRouter()` doesn't build its
// internal `Navigator` on the same frame it's first built, so for one frame
// it renders a fullscreen placeholder. With an `EmptyShellRoute`, there are
// two such `AutoRouter`s to resolve, so there can be a frame where that
// placeholder's size coincidentally matches the real, final content size
// (which happens whenever the route's content is fullscreen). When that
// happens, `SheetModel.applyNewLayout`'s "layout unchanged" fast path used
// to skip notifying the newly-started activity, leaving the sheet
// permanently stuck at offset 0 (fully below the viewport) instead of
// settling at `initialOffset`.
//
// Fixed generally (not with an auto_route-specific workaround) by having
// `SheetActivity` declare whether it needs a guaranteed initial call to
// `applyNewLayout`, and having `SheetModel.applyNewLayout` honor that even
// when the incoming layout is value-identical to the previous one.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

const _sheetKey = Key('modal-sheet');
const _firstSheetPageKey = Key('first-sheet-page');

void main() {
  Future<void> pumpTestApp(WidgetTester tester, RootStackRouter router) async {
    await tester.pumpWidget(_TestApp(router: router));
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'No EmptyShellRoute layer -> fullscreen sheet appears at the '
    'expected initialOffset',
    (tester) async {
      await pumpTestApp(
        tester,
        _TestRouter(useShellLayer: false, contentHeight: 600),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(_firstSheetPageKey), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_sheetKey)),
        const Rect.fromLTRB(0, 300, 800, 900),
        reason:
            'Half of the 600-tall sheet should be visible '
            '(initialOffset: 0.5)',
      );
    },
  );

  testWidgets(
    'EmptyShellRoute + fullscreen content -> sheet still appears at the '
    'expected initialOffset (issue #594)',
    (tester) async {
      await pumpTestApp(
        tester,
        _TestRouter(useShellLayer: true, contentHeight: 600),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(_firstSheetPageKey), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_sheetKey)),
        const Rect.fromLTRB(0, 300, 800, 900),
        reason:
            'Same as the baseline test above: the extra EmptyShellRoute '
            'layer must not prevent the sheet from settling at the '
            'expected initialOffset.',
      );
    },
  );

  testWidgets(
    'EmptyShellRoute + non-fullscreen content -> settles correctly',
    (tester) async {
      await pumpTestApp(
        tester,
        _TestRouter(useShellLayer: true, contentHeight: 300),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(_firstSheetPageKey), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_sheetKey)),
        const Rect.fromLTRB(0, 450, 800, 750),
        reason:
            'Half of the 300-tall sheet should be visible '
            '(initialOffset: 0.5)',
      );
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.router});

  final RootStackRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router.config());
  }
}

class _TestRouter extends RootStackRouter {
  _TestRouter({required this.useShellLayer, required this.contentHeight});

  final bool useShellLayer;
  final double contentHeight;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: '/',
      page: PageInfo('_HomeRoute', builder: (data) => const _HomePage()),
    ),
    CustomRoute<dynamic>(
      path: '/modal',
      page: PageInfo(
        '_ModalSheetRoute',
        builder: (data) => _ModalSheetPage(),
      ),
      customRouteBuilder: <T>(context, child, page) {
        return ModalSheetRoute(settings: page, builder: (_) => child);
      },
      children: [
        if (useShellLayer)
          AutoRoute(
            initial: true,
            path: 'shell',
            page: const EmptyShellRoute('_ShellRoute'),
            children: [_firstRoute()],
          )
        else
          _firstRoute(),
      ],
    ),
  ];

  CustomRoute<dynamic> _firstRoute() {
    return CustomRoute<dynamic>(
      initial: true,
      path: 'first',
      page: PageInfo(
        '_FirstSheetRoute',
        builder: (data) => _FirstSheetPage(height: contentHeight),
      ),
      customRouteBuilder: <T>(context, child, page) {
        return PagedSheetRoute(
          settings: page,
          initialOffset: const SheetOffset(0.5),
          snapGrid: const SheetSnapGrid(
            snaps: [SheetOffset(0.5), SheetOffset(1)],
          ),
          builder: (_) => child,
        );
      },
    );
  }
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
      child: Container(color: Colors.blue.shade200),
    );
  }
}

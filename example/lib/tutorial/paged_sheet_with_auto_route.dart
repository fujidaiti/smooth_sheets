import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

part 'paged_sheet_with_auto_route.gr.dart';

void main() {
  runApp(const PagedSheetWithAutoRouteExample());
}

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class _ExampleRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: _HomeRoute.page,
        ),
        CustomRoute(
          path: '/modal',
          page: _ModalSheetRoute.page,
          customRouteBuilder: <T>(context, child, page) {
            // Use ModalSheetRoute to show the sheet as a modal.
            return ModalSheetRoute(
              settings: page, // required
              builder: (_) => child,
            );
          },
          children: [
            CustomRoute(
              initial: true,
              path: 'first',
              page: _FirstSheetRoute.page,
              customRouteBuilder: <T>(context, child, page) {
                // Each route in the PagedSheet must be a PagedSheetRoute.
                return PagedSheetRoute(
                  settings: page, // required
                  initialOffset: const SheetOffset(0.5),
                  snapGrid: const SheetSnapGrid(
                    snaps: [SheetOffset(0.5), SheetOffset(1)],
                  ),
                  builder: (_) => child,
                );
              },
            ),
            CustomRoute(
              path: 'second',
              page: _SecondSheetRoute.page,
              customRouteBuilder: <T>(context, child, page) {
                return PagedSheetRoute(
                  settings: page, // required
                  builder: (_) => child,
                );
              },
            ),
          ],
        ),
      ];
}

class PagedSheetWithAutoRouteExample extends StatefulWidget {
  const PagedSheetWithAutoRouteExample({super.key});
  @override
  State<PagedSheetWithAutoRouteExample> createState() =>
      _PagedSheetWithAutoRouteExampleState();
}

class _PagedSheetWithAutoRouteExampleState
    extends State<PagedSheetWithAutoRouteExample> {
  late final _router = _ExampleRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router.config(),
    );
  }
}

@RoutePage()
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

@RoutePage()
class _ModalSheetPage extends StatelessWidget {
  const _ModalSheetPage();

  @override
  Widget build(BuildContext context) {
    return PagedSheet(
      key: const ValueKey('modal-sheet'),
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        color: Colors.white,
      ),
      // See https://github.com/Milad-Akarie/auto_route_library/tree/master?tab=readme-ov-file#nested-navigation
      navigator: AutoRouter(),
    );
  }
}

@RoutePage()
class _FirstSheetPage extends StatelessWidget {
  const _FirstSheetPage();

  @override
  Widget build(BuildContext context) {
    final layoutSpec = SheetMediaQuery.layoutSpecOf(context);
    return SizedBox.fromSize(
      key: const ValueKey('first-sheet-page'),
      size: Size.fromHeight(layoutSpec.viewportSize.height * 0.5),
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

@RoutePage()
class _SecondSheetPage extends StatelessWidget {
  const _SecondSheetPage();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: const ValueKey('second-sheet-page'),
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

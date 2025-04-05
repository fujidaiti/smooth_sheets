import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

// The code may seem verbose, but the core principle is straightforward.
// In this tutorial, you only need to learn the following:
//
// 1. Create a Navigator and wrap it in a PagedSheet.
// 2. Use *PagedSheetPage to create a page that belongs to the navigator.
void main() {
  runApp(const _DeclarativePagedSheetExample());
}

// To use declarative navigation, we utilize the 'go_router' package.
// However, any other package that works with Navigator 2.0
// or even your own implementation can also be used.
final router = GoRouter(
  initialLocation: '/a',
  routes: [
    // We use ShellRoute to create a Navigator
    // that will be used for nested navigation in the sheet.
    ShellRoute(
      builder: (context, state, child) {
        return _ExampleHome(nestedNavigator: child);
      },
      routes: [
        GoRoute(
          path: '/a',
          pageBuilder: (context, state) {
            return PagedSheetPage(
              key: state.pageKey,
              snapGrid: const SheetSnapGrid(
                snaps: [SheetOffset(0.8), SheetOffset(1)],
              ),
              child: const _ExampleSheetContent(
                title: '/a',
                heightFactor: 0.5,
                destinations: ['/a/details', '/b'],
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'details',
              pageBuilder: (context, state) {
                return PagedSheetPage(
                  key: state.pageKey,
                  child: const _ExampleSheetContent(
                    title: '/a/details',
                    heightFactor: 0.75,
                    destinations: ['/a/details/info'],
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: 'info',
                  pageBuilder: (context, state) {
                    return PagedSheetPage(
                      key: state.pageKey,
                      initialOffset: const SheetOffset(0.5),
                      snapGrid: const SheetSnapGrid(
                        snaps: [
                          SheetOffset(0.2),
                          SheetOffset(0.5),
                          SheetOffset(1),
                        ],
                      ),
                      child: const _ExampleSheetContent(
                        title: '/a/details/info',
                        heightFactor: 1.0,
                        destinations: ['/a', '/b', '/b/details'],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/b',
          pageBuilder: (context, state) {
            return PagedSheetPage(
              key: state.pageKey,
              child: const _ExampleSheetContent(
                title: 'B',
                heightFactor: 0.6,
                destinations: ['/b/details', '/a'],
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'details',
              pageBuilder: (context, state) {
                return PagedSheetPage(
                  key: state.pageKey,
                  child: const _ExampleSheetContent(
                    title: 'B Details',
                    heightFactor: 0.5,
                    destinations: ['/a'],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class _DeclarativePagedSheetExample extends StatelessWidget {
  const _DeclarativePagedSheetExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

class _ExampleHome extends StatelessWidget {
  const _ExampleHome({
    required this.nestedNavigator,
  });

  final Widget nestedNavigator;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Scaffold(),
        SheetViewport(
          child: _ExampleSheet(
            nestedNavigator: nestedNavigator,
          ),
        ),
      ],
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet({
    required this.nestedNavigator,
  });

  final Widget nestedNavigator;

  @override
  Widget build(BuildContext context) {
    return PagedSheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
      ),
      navigator: nestedNavigator,
    );
  }
}

class _ExampleSheetContent extends StatelessWidget {
  const _ExampleSheetContent({
    required this.title,
    required this.heightFactor,
    required this.destinations,
  });

  final String title;
  final double heightFactor;
  final List<String> destinations;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSecondaryContainer;
    final textStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        );

    // Tips: You can use SheetMediaQuery to get the layout information of the sheet
    // in the build method, such as the size of the viewport where the sheet is rendered.
    final sheetLayoutSpec = SheetMediaQuery.layoutSpecOf(context);

    return Container(
      color: Theme.of(context).colorScheme.secondaryContainer,
      width: double.infinity,
      height: sheetLayoutSpec.viewportSize.height * heightFactor,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(title, style: textStyle),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final dest in destinations)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                    ),
                    onPressed: () => context.go(dest),
                    child: Text('Go To $dest'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

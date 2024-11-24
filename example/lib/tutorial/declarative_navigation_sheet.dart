import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

// The code may seem verbose, but the core principle is straightforward.
// In this tutorial, you only need to learn the following:
//
// 1. Create a Navigator and wrap it in a NavigationSheet.
// 2. Use *NavigationSheetPage to create a page that belongs to the navigator.
// 3. Do not forget to register a NavigationSheetTransitionObserver to the navigator.
void main() {
  runApp(const _DeclarativeNavigationSheetExample());
}

// NavigationSheet requires a special NavigatorObserver in order to
// smoothly change its position during a route transition.
final transitionObserver = NavigationSheetTransitionObserver();

// To use declarative navigation, we utilize the 'go_router' package.
// However, any other package that works with Navigator 2.0
// or even your own implementation can also be used.
final router = GoRouter(
  initialLocation: '/a',
  routes: [
    // We use ShellRoute to create a Navigator
    // that will be used for nested navigation in the sheet.
    ShellRoute(
      // Do not forget this line!
      observers: [transitionObserver],
      builder: (context, state, child) {
        return _ExampleHome(nestedNavigator: child);
      },
      routes: [
        GoRoute(
          path: '/a',
          pageBuilder: (context, state) {
            // Use DraggableNavigationSheetPage for a draggable page.
            // If the page contains scrollable widget(s), consider using
            // ScrollableNavigationSheetPage instead.
            return DraggableNavigationSheetPage(
              key: state.pageKey,
              child: const _ExampleSheetContent(
                title: '/a',
                size: 0.5,
                destinations: ['/a/details', '/b'],
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'details',
              pageBuilder: (context, state) {
                return DraggableNavigationSheetPage(
                  key: state.pageKey,
                  child: const _ExampleSheetContent(
                    title: '/a/details',
                    size: 0.75,
                    destinations: ['/a/details/info'],
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: 'info',
                  pageBuilder: (context, state) {
                    return DraggableNavigationSheetPage(
                      key: state.pageKey,
                      child: const _ExampleSheetContent(
                        title: '/a/details/info',
                        size: 1.0,
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
            return DraggableNavigationSheetPage(
              key: state.pageKey,
              child: const _ExampleSheetContent(
                title: 'B',
                size: 0.6,
                destinations: ['/b/details', '/a'],
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'details',
              pageBuilder: (context, state) {
                return DraggableNavigationSheetPage(
                  key: state.pageKey,
                  child: const _ExampleSheetContent(
                    title: 'B Details',
                    size: 0.5,
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

class _DeclarativeNavigationSheetExample extends StatelessWidget {
  const _DeclarativeNavigationSheetExample();

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
    return NavigationSheet(
      transitionObserver: transitionObserver,
      child: Material(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: nestedNavigator,
      ),
    );
  }
}

class _ExampleSheetContent extends StatelessWidget {
  const _ExampleSheetContent({
    required this.title,
    required this.size,
    required this.destinations,
  });

  final String title;
  final double size;
  final List<String> destinations;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSecondaryContainer;
    final textStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Theme.of(context).colorScheme.secondaryContainer,
          width: constraints.maxWidth,
          height: constraints.maxHeight * size,
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
      },
    );
  }
}

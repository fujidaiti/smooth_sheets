import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

// This tutorial demonstrates how to use context.replace() with GoRouter
// to replace the current sheet page with a new one, animating the sheet
// extent smoothly during the transition.
void main() {
  runApp(const _PagedSheetReplaceWithGoRouterExample());
}

final _router = GoRouter(
  initialLocation: '/a',
  routes: [
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
              child: const _ExampleSheetContent(
                title: 'Page A',
                heightFactor: 0.4,
                color: Colors.teal,
              ),
            );
          },
        ),
        GoRoute(
          path: '/b',
          pageBuilder: (context, state) {
            return PagedSheetPage(
              key: state.pageKey,
              child: const _ExampleSheetContent(
                title: 'Page B',
                heightFactor: 0.7,
                color: Colors.deepPurple,
              ),
            );
          },
        ),
      ],
    ),
  ],
);

class _PagedSheetReplaceWithGoRouterExample extends StatelessWidget {
  const _PagedSheetReplaceWithGoRouterExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

class _ExampleHome extends StatelessWidget {
  const _ExampleHome({required this.nestedNavigator});

  final Widget nestedNavigator;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Scaffold(),
        SheetViewport(
          child: PagedSheet(
            decoration: MaterialSheetDecoration(
              size: SheetSize.stretch,
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
            ),
            navigator: nestedNavigator,
          ),
        ),
      ],
    );
  }
}

class _ExampleSheetContent extends StatelessWidget {
  const _ExampleSheetContent({
    required this.title,
    required this.heightFactor,
    required this.color,
  });

  final String title;
  final double heightFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sheetLayoutSpec = SheetMediaQuery.layoutSpecOf(context);
    final currentPath =
        GoRouterState.of(context).uri.path == '/a' ? '/a' : '/b';
    final replacementPath = currentPath == '/a' ? '/b' : '/a';

    return Container(
      color: color.withValues(alpha: 0.2),
      width: double.infinity,
      height: sheetLayoutSpec.viewportSize.height * heightFactor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Height: ${(heightFactor * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // Use context.replace() to replace the current route.
            // The sheet extent animates smoothly to the new page's size.
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: () => context.replace(replacementPath),
              child: Text('Replace with $replacementPath'),
            ),
          ],
        ),
      ),
    );
  }
}

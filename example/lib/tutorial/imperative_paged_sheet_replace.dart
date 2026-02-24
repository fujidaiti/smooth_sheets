import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

// This tutorial demonstrates how to use Navigator.replace() to swap the
// current sheet page with a new one. The sheet extent animates smoothly
// during the replacement transition.
void main() {
  runApp(const _ImperativePagedSheetReplaceExample());
}

class _ImperativePagedSheetReplaceExample extends StatelessWidget {
  const _ImperativePagedSheetReplaceExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Stack(
        children: [
          Scaffold(),
          SheetViewport(
            child: _ExampleSheet(),
          ),
        ],
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    final nestedNavigator = Navigator(
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          PagedSheetRoute(
            builder: (context) {
              return const _PageA();
            },
          ),
        ];
      },
    );

    return PagedSheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.stretch,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.primary,
      ),
      navigator: nestedNavigator,
    );
  }
}

class _PageA extends StatelessWidget {
  const _PageA();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.teal.withValues(alpha: 0.2),
          width: constraints.maxWidth,
          height: constraints.maxHeight * 0.4,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page A',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Height: 40%',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () => _replaceWith(context, isPageA: false),
                  child: const Text('Replace with Page B'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageB extends StatelessWidget {
  const _PageB();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.deepPurple.withValues(alpha: 0.2),
          width: constraints.maxWidth,
          height: constraints.maxHeight * 0.7,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page B',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Height: 70%',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple),
                  onPressed: () => _replaceWith(context, isPageA: true),
                  child: const Text('Replace with Page A'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Replaces the current route using [Navigator.replace].
void _replaceWith(BuildContext context, {required bool isPageA}) {
  final navigator = Navigator.of(context);
  final oldRoute = ModalRoute.of(context)!;
  final newRoute = PagedSheetRoute(
    builder: (_) => isPageA ? const _PageA() : const _PageB(),
  );
  navigator.replace(oldRoute: oldRoute, newRoute: newRoute);
}

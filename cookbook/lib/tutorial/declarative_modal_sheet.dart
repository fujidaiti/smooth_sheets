import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _DeclarativeModalSheetExample());
}

// To use declarative navigation, we utilize the 'go_router' package.
// However, any other package that works with Navigator 2.0
// or even your own implementation can also be used.
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const _ExampleHome();
      },
      routes: [
        GoRoute(
          path: 'modal-sheet',
          pageBuilder: (context, state) {
            // Use ModalSheetPage to show a modal sheet with Navigator 2.0.
            // It works with any *Sheet provided by this package!
            return ModalSheetPage(
              key: state.pageKey,
              child: const _ExampleSheet(),
            );
          },
        ),
      ],
    ),
  ],
);

class _DeclarativeModalSheetExample extends StatelessWidget {
  const _DeclarativeModalSheetExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

class _ExampleHome extends StatelessWidget {
  const _ExampleHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/modal-sheet'),
          child: const Text('Show Modal Sheet'),
        ),
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableSheet(
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          height: 500,
          width: double.infinity,
        ),
      ),
    );
  }
}

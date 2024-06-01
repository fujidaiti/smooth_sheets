import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Issue [#131](https://github.com/fujidaiti/smooth_sheets/issues/131):
/// Unwanted bouncing effect when opening keyboard on NavigationSheet
void main() {
  runApp(const Issue131());
}

class Issue131 extends StatelessWidget {
  const Issue131({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

final sheetTransitionObserver = NavigationSheetTransitionObserver();

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Home(),
      routes: [
        ShellRoute(
          observers: [sheetTransitionObserver],
          pageBuilder: (context, state, navigator) {
            return ModalSheetPage(
              child: ModalSheet(
                navigator: navigator,
                transitionObserver: sheetTransitionObserver,
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'intro',
              pageBuilder: (context, state) {
                return const DraggableNavigationSheetPage(
                  child: SheetContent(),
                );
              },
            )
          ],
        )
      ],
    ),
  ],
);

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/intro'),
          child: const Text('Show modal sheet'),
        ),
      ),
    );
  }
}

class ModalSheet extends StatelessWidget {
  const ModalSheet({
    super.key,
    required this.transitionObserver,
    required this.navigator,
  });

  final NavigationSheetTransitionObserver transitionObserver;
  final Widget navigator;

  @override
  Widget build(BuildContext context) {
    return NavigationSheet(
      transitionObserver: sheetTransitionObserver,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: navigator,
      ),
    );
  }
}

class SheetContent extends StatelessWidget {
  const SheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      body: SizedBox(
        height: 300,
        child: Center(
          child: TextFormField(),
        ),
      ),
    );
  }
}

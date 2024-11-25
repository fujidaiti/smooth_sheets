import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Example code of iOS style modal `NavigationSheet` with go_router.
void main() {
  runApp(const _App());
}

final transitionObserver = NavigationSheetTransitionObserver();

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
        path: '/',
        builder: (context, state) {
          return const _Home();
        },
        routes: [
          ShellRoute(
            observers: [transitionObserver],
            pageBuilder: (context, state, child) {
              return CupertinoModalSheetPage(
                key: state.pageKey,
                child: _Modal(nestedNavigator: child),
              );
            },
            routes: [
              GoRoute(
                path: 'modal',
                pageBuilder: (context, state) {
                  return DraggableNavigationSheetPage(
                    key: state.pageKey,
                    child: Container(color: Colors.white),
                  );
                },
              ),
            ],
          )
        ]),
  ],
);

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return CupertinoStackedTransition(
      cornerRadius: Tween(begin: 0, end: 20),
      child: Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/modal'),
            child: const Text('Show Sheet'),
          ),
        ),
      ),
    );
  }
}

class _Modal extends StatelessWidget {
  const _Modal({
    required this.nestedNavigator,
  });

  final Widget nestedNavigator;

  @override
  Widget build(BuildContext context) {
    return SheetViewport(
      child: NavigationSheet(
        transitionObserver: transitionObserver,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: nestedNavigator,
        ),
      ),
    );
  }
}

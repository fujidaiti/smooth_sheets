import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

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
                    child: const _ModalContent(),
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
    return NavigationSheet(
      transitionObserver: transitionObserver,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: nestedNavigator,
      ),
    );

    // The following code works fine.

    // return DraggableSheet(
    //   child: Container(
    //     color: Colors.white,
    //     width: double.infinity,
    //     height: 700,
    //   ),
    // );
  }
}

class _ModalContent extends StatelessWidget {
  const _ModalContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: 700,
    );
  }
}

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
              // Enable the swipe-to-dismiss behavior.
              swipeDismissible: true,
              // Use `SwipeDismissSensitivity` to tweak the sensitivity of the swipe-to-dismiss behavior.
              swipeDismissSensitivity: const SwipeDismissSensitivity(
                minFlingVelocityRatio: 2.0,
                dismissalOffset: SheetOffset.proportionalToViewport(0.4),
              ),
              // You don't need a SheetViewport for the modal sheet.
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
    // You can use PopScope to handle the swipe-to-dismiss gestures, as well as
    // the system back gestures and tapping on the barrier, all in one place.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await showConfirmationDialog(context);
          if (shouldPop == true && context.mounted) {
            context.go('/');
          }
        }
      },
      child: Sheet(
        decoration: MaterialSheetDecoration(
          size: SheetSize.stretch,
          color: Colors.red,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Container(
          height: 500,
          width: double.infinity,
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }

  Future<bool?> showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }
}

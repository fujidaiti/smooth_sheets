import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _ImperativeModalSheetExample());
}

class _ImperativeModalSheetExample extends StatelessWidget {
  const _ImperativeModalSheetExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatelessWidget {
  const _ExampleHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showModalSheet(context),
          child: const Text('Show Modal Sheet'),
        ),
      ),
    );
  }
}

void _showModalSheet(BuildContext context) {
  // Use ModalSheetRoute to show a modal sheet with imperative Navigator API.
  // It works with any *Sheet provided by this package!
  final modalRoute = ModalSheetRoute(
    // Enable the swipe-to-dismiss behavior.
    swipeDismissible: true,
    // Use `SwipeDismissSensitivity` to tweak the sensitivity of the swipe-to-dismiss behavior.
    swipeDismissSensitivity: const SwipeDismissSensitivity(
      minFlingVelocityRatio: 2.0,
      minDragDistance: 200.0,
    ),
    builder: (context) => const _ExampleSheet(),
  );

  Navigator.push(context, modalRoute);
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    // You can use PopScope to handle the swipe-to-dismiss gestures, as well as
    // the system back gestures and tapping on the barrier, all in one place.
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await showConfirmationDialog(context);
          if (shouldPop == true && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: DraggableSheet(
        minPosition: const SheetAnchor.proportional(0.5),
        child: Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const SizedBox(
            height: 700,
            width: double.infinity,
          ),
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

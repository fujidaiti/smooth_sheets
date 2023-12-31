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
    builder: (context) => const _ExampleSheet(),
  );

  Navigator.push(context, modalRoute);
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

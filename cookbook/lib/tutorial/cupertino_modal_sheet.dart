import 'package:flutter/cupertino.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _CupertinoModalSheetExample());
}

class _CupertinoModalSheetExample extends StatelessWidget {
  const _CupertinoModalSheetExample();

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatelessWidget {
  const _ExampleHome();

  @override
  Widget build(BuildContext context) {
    return CupertinoStackedTransition(
      child: CupertinoPageScaffold(
        child: Center(
          child: CupertinoButton.filled(
            onPressed: () => _showModalSheet(context),
            child: const Text('Show Modal Sheet'),
          ),
        ),
      ),
    );
  }
}

void _showModalSheet(BuildContext context) {
  final modalRoute = CupertinoModalSheetRoute(
    builder: (context) => const _ExampleSheet(),
  );

  Navigator.push(context, modalRoute);
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableSheet(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: CupertinoColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton.filled(
                  onPressed: () => _showModalSheet(context),
                  child: const Text('Stack'),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

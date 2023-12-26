import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _SheetPhysicsExample());
}

class _SheetPhysicsExample extends StatelessWidget {
  const _SheetPhysicsExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _ExampleHome(),
    );
  }
}

enum _PhysicsKind {
  clamping('Clamping'),
  stretching('Stretching'),
  clampingSnapping('Clamping + Snapping'),
  stretchingSnapping('Stretching + Snapping');

  final String name;

  const _PhysicsKind(this.name);
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  _PhysicsKind selectedPhysics = _PhysicsKind.stretchingSnapping;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildOptions(),
          _MySheet(physicsKind: selectedPhysics),
        ],
      ),
    );
  }

  Widget buildOptions() {
    return SafeArea(
      child: Column(
        children: [
          for (final physics in _PhysicsKind.values)
            RadioListTile(
              title: Text(physics.name),
              value: physics,
              groupValue: selectedPhysics,
              onChanged: (value) => setState(() {
                selectedPhysics = value!;
              }),
            ),
        ],
      ),
    );
  }
}

// Height of the sheet in logical pixels.
const _sheetHeight = 500.0;

// Fraction of the sheet height that the sheet should snap to.
// Must be between 0 and 1.
const _halfwayFraction = 0.6;

class _MySheet extends StatelessWidget {
  const _MySheet({
    required this.physicsKind,
  });

  final _PhysicsKind physicsKind;

  SheetPhysics createPhysics(_PhysicsKind kind) {
    // With this configuration, the sheet will snap to:
    // - the extent at which ony (_halfwayFraction * 100)% of the content is visible, or
    // - the extent at which the entire content is visible.
    // Note that the "extent" is the visible height of the sheet.
    const snappingPhysics = SnappingSheetPhysics(
      snappingBehavior: SnapToNearest(
        snapTo: [
          Extent.proportional(_halfwayFraction),
          Extent.proportional(1),
        ],
      ),
    );

    return switch (kind) {
      _PhysicsKind.clamping => const ClampingSheetPhysics(),
      _PhysicsKind.stretching => const StretchingSheetPhysics(),
      _PhysicsKind.clampingSnapping =>
        // Use 'parent' to combine multiple physics behaviors.
        const ClampingSheetPhysics(parent: snappingPhysics),
      _PhysicsKind.stretchingSnapping =>
        const StretchingSheetPhysics(parent: snappingPhysics),
    };
  }

  @override
  Widget build(BuildContext context) {
    return DraggableSheet(
      physics: createPhysics(physicsKind),
      minExtent: const Extent.proportional(_halfwayFraction),
      child: buildContent(context),
    );
  }

  Widget buildContent(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _sheetHeight,
      child: Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Flexible(
              fit: FlexFit.tight,
              flex: (_halfwayFraction * 10).toInt(),
              child: Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                alignment: Alignment.center,
                child: Text(
                  '${(_halfwayFraction * 100).toInt()}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              flex: (10 - _halfwayFraction * 10).toInt(),
              child: Container(
                color: Theme.of(context).colorScheme.tertiary,
                alignment: Alignment.center,
                child: Text(
                  '${(100 - _halfwayFraction * 100).toInt()}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

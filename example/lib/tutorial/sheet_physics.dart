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
  bouncing('Bouncing'),
  clampingSnapping('Clamping + Snapping'),
  bouncingSnapping('Bouncing + Snapping');

  final String name;

  const _PhysicsKind(this.name);
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  _PhysicsKind selectedPhysics = _PhysicsKind.bouncingSnapping;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildOptions(),
          SheetViewport(
            child: _MySheet(
              physicsKind: selectedPhysics,
            ),
          ),
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
    // - the position at which ony (_halfwayFraction * 100)% of the content is visible, or
    // - the position at which the entire content is visible.
    // Note that the "position" is the visible height of the sheet.
    const snappingPhysics = SnappingSheetPhysics(
      behavior: SnapToNearest(
        anchors: [
          SheetAnchor.proportional(_halfwayFraction),
          SheetAnchor.proportional(1),
        ],
      ),
      // Tips: The above configuration can be replaced with a 'SnapToNearestEdge',
      // which will snap to either the 'minPosition' or 'maxPosition' of the sheet:
      // snappingBehavior: const SnapToNearestEdge(),
    );

    return switch (kind) {
      _PhysicsKind.clamping => const ClampingSheetPhysics(),
      _PhysicsKind.bouncing => const BouncingSheetPhysics(),
      _PhysicsKind.clampingSnapping =>
        // Use 'parent' to combine multiple physics behaviors.
        const ClampingSheetPhysics(parent: snappingPhysics),
      _PhysicsKind.bouncingSnapping =>
        const BouncingSheetPhysics(parent: snappingPhysics),
    };
  }

  @override
  Widget build(BuildContext context) {
    return DraggableSheet(
      // The 'minPosition' and 'maxPosition' properties determine
      // how far the sheet can be dragged.  Note that "position"
      // refers to the visible height of the sheet. For example,
      // the configuration below ensures that the sheet is fully visible
      // at first and can then be dragged down to (_halfwayFraction * 100)%
      // of the sheet height at minimum.
      minPosition: const SheetAnchor.proportional(_halfwayFraction),
      maxPosition: const SheetAnchor.proportional(1),
      // Default
      initialPosition: const SheetAnchor.proportional(1),
      // Default
      // 'physics' determines how the sheet will behave when the user reaches
      // the maximum or minimum position, or when the user stops dragging.
      physics: createPhysics(physicsKind),
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

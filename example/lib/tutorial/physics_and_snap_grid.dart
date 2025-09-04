import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _PhysicsAndSnapGridExample());
}

class _PhysicsAndSnapGridExample extends StatelessWidget {
  const _PhysicsAndSnapGridExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _ExampleHome(),
    );
  }
}

enum _PhysicsKind {
  clamping('ClampingSheetPhysics'),
  bouncing('BouncingSheetPhysics');

  final String name;

  const _PhysicsKind(this.name);
}

enum _SnapGridKind {
  stepless('SteplessSnapGrid'),
  single('SingleSnapGrid'),
  multi('MultiSnapGrid');

  final String name;

  const _SnapGridKind(this.name);
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  _PhysicsKind selectedPhysics = _PhysicsKind.bouncing;
  _SnapGridKind selectedSnapGrid = _SnapGridKind.multi;

  @override
  Widget build(BuildContext context) {
    void showSheet(_SnapGridKind snapGridKind) {
      Navigator.push(
        context,
        ModalSheetRoute(
          builder: (context) => _MySheet(
            physicsKind: selectedPhysics,
            snapGridKind: snapGridKind,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Physics and Snap Grid'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Physics',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final physics in _PhysicsKind.values)
            RadioListTile(
              title: Text(physics.name),
              value: physics,
              // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
              // ignore: deprecated_member_use
              groupValue: selectedPhysics,
              // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
              // ignore: deprecated_member_use
              onChanged: (value) => setState(() {
                selectedPhysics = value!;
              }),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Snap Grid',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final snapGrid in _SnapGridKind.values)
            RadioListTile(
              title: Text(snapGrid.name),
              value: snapGrid,
              // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
              // ignore: deprecated_member_use
              groupValue: selectedSnapGrid,
              // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
              // ignore: deprecated_member_use
              onChanged: (value) => setState(() {
                selectedSnapGrid = value!;
              }),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSheet(selectedSnapGrid),
        label: const Text('Show Sheet'),
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
    required this.snapGridKind,
  });

  final _PhysicsKind physicsKind;
  final _SnapGridKind snapGridKind;

  SheetPhysics createPhysics(_PhysicsKind kind) {
    return switch (kind) {
      _PhysicsKind.clamping => const ClampingSheetPhysics(),
      _PhysicsKind.bouncing => const BouncingSheetPhysics(),
    };
  }

  SheetSnapGrid createSnapGrid() {
    return switch (snapGridKind) {
      _SnapGridKind.stepless =>
        const SteplessSnapGrid(minOffset: SheetOffset(_halfwayFraction)),
      _SnapGridKind.single => const SingleSnapGrid(snap: SheetOffset(1)),
      _SnapGridKind.multi => const MultiSnapGrid(
          snaps: [SheetOffset(_halfwayFraction), SheetOffset(1)],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Sheet(
      initialOffset: const SheetOffset(1),
      physics: createPhysics(physicsKind),
      snapGrid: createSnapGrid(),
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

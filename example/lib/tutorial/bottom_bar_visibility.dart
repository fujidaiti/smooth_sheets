import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _BottomBarVisibilityExample());
}

class _BottomBarVisibilityExample extends StatelessWidget {
  const _BottomBarVisibilityExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _ExampleHome(),
    );
  }
}

enum _BottomBarVisibilityType {
  fixed(
    name: 'FixedBottomBarVisibility',
    description: 'The bottom bar is fixed at the bottommost of the sheet.',
  ),
  sticky(
    name: 'StickyBottomBarVisibility',
    description:
        'The bottom bar is always visible regardless of the sheet position.',
  ),
  conditionalSticky(
    name: 'ConditionalStickyBottomBarVisibility',
    description:
        'The bottom bar is visible only when a certain condition is met.',
  );

  final String name;
  final String description;

  const _BottomBarVisibilityType({
    required this.name,
    required this.description,
  });
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  _BottomBarVisibilityType selectedVisibilityType =
      _BottomBarVisibilityType.sticky;

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final type in _BottomBarVisibilityType.values)
        RadioListTile(
          title: Text(type.name),
          subtitle: Text(type.description),
          value: type,
          groupValue: selectedVisibilityType,
          contentPadding: const EdgeInsets.only(left: 24, right: 16),
          controlAffinity: ListTileControlAffinity.trailing,
          onChanged: (value) => setState(() {
            selectedVisibilityType = value!;
          }),
        ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                title: Text('BottomBarVisibility'),
                subtitle: Text(
                  'Controls the visibility of the bottom bar based on the sheet position. '
                  "Intended to be used as the 'SheetContentScaffold.bottomBar'.",
                ),
              ),
              ...options,
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Show sheet'),
        onPressed: () => showExampleSheet(context),
      ),
    );
  }

  void showExampleSheet(BuildContext context) {
    Navigator.push(
      context,
      ModalSheetRoute(
        builder: (context) => SheetViewport(
          child: SheetViewport(
            child: _ExampleSheet(
              visibilityType: selectedVisibilityType,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet({
    required this.visibilityType,
  });

  final _BottomBarVisibilityType visibilityType;

  @override
  Widget build(BuildContext context) {
    final bottomBar = BottomAppBar(
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );

    const minSize = SheetAnchor.proportional(0.3);
    const halfSize = SheetAnchor.proportional(0.5);
    const fullSize = SheetAnchor.proportional(1);

    const multiStopPhysics = BouncingSheetPhysics(
      parent: SnappingSheetPhysics(
        behavior: SnapToNearest(
          anchors: [minSize, halfSize, fullSize],
        ),
      ),
    );

    return SafeArea(
      bottom: false,
      child: DraggableSheet(
        minPosition: minSize,
        initialPosition: halfSize,
        physics: multiStopPhysics,
        child: SheetContentScaffold(
          appBar: AppBar(),
          body: const SizedBox.expand(),
          bottomBar: switch (visibilityType) {
            _BottomBarVisibilityType.fixed =>
              FixedBottomBarVisibility(child: bottomBar),
            _BottomBarVisibilityType.sticky =>
              StickyBottomBarVisibility(child: bottomBar),
            _BottomBarVisibilityType.conditionalSticky =>
              ConditionalStickyBottomBarVisibility(
                // This callback is called whenever the sheet metrics changes,
                // and returning true keeps the bottom bar visible.
                getIsVisible: (metrics) {
                  // The bottom bar is visible when at least 50% of the sheet is visible.
                  return metrics.pixels >=
                      const SheetAnchor.proportional(0.5)
                          .resolve(metrics.contentSize);
                },
                child: bottomBar,
              ),
          },
          // Add the following 3 lines to keep the bottom bar visible when the keyboard is open.
          // resizeBehavior: const ResizeScaffoldBehavior.avoidBottomInset(
          //   maintainBottomBar: true,
          // ),
        ),
      ),
    );
  }
}

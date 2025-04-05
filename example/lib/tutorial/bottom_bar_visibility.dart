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
  natural(
    name: '.natural',
    description: 'The bar is placed at the bottommost of the sheet.',
  ),
  always(
    name: '.always',
    description: 'The bar sticks to the bottom of the screen.',
  ),
  conditional(
    name: '.conditional',
    description: 'The bar is visible only when a certain condition is met.',
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
  @override
  Widget build(BuildContext context) {
    final options = [
      for (final type in _BottomBarVisibilityType.values)
        ListTile(
          title: Text(type.name),
          subtitle: Text(type.description),
          contentPadding: const EdgeInsets.only(left: 24, right: 16),
          onTap: () => showExampleSheet(context, type),
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
                  'Intended to be used with SheetContentScaffold.bottomBar.',
                ),
              ),
              ...options,
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void showExampleSheet(
    BuildContext context,
    _BottomBarVisibilityType visibilityType,
  ) {
    Navigator.push(
      context,
      ModalSheetRoute(
        viewportPadding: EdgeInsets.only(
          // Add the top padding to avoid the status bar.
          top: MediaQuery.viewPaddingOf(context).top,
        ),
        builder: (context) => _ExampleSheet(
          visibilityType: visibilityType,
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
    final bottomBarVisibility = switch (visibilityType) {
      _BottomBarVisibilityType.natural => const BottomBarVisibility.natural(),
      _BottomBarVisibilityType.always => const BottomBarVisibility.always(),
      _BottomBarVisibilityType.conditional => BottomBarVisibility.conditional(
          // This callback is called whenever the sheet metrics changes,
          // and returning true keeps the bottom bar visible.
          isVisible: (metrics) {
            // The bottom bar is visible when at least 50% of the sheet is visible.
            return metrics.offset >= const SheetOffset(0.5).resolve(metrics);
          },
        ),
    };

    const minSize = SheetOffset(0.2);
    const halfSize = SheetOffset(0.5);
    const fullSize = SheetOffset(1);

    return Sheet(
      initialOffset: halfSize,
      snapGrid: const SheetSnapGrid(snaps: [minSize, halfSize, fullSize]),
      child: SheetContentScaffold(
        bottomBarVisibility: bottomBarVisibility,
        extendBodyBehindBottomBar: true,
        topBar: AppBar(),
        body: const SizedBox.expand(),
        bottomBar: const _ExampleBottomBar(),
      ),
    );
  }
}

class _ExampleBottomBar extends StatelessWidget {
  const _ExampleBottomBar();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainer,
      // Use SafeArea to absorb the screen notch.
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: SizedBox.fromSize(
          size: const Size.fromHeight(kToolbarHeight),
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
        ),
      ),
    );
  }
}

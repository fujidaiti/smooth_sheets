import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _PositionDrivenAnimationExample());
}

class _PositionDrivenAnimationExample extends StatelessWidget {
  const _PositionDrivenAnimationExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: _ExampleScaffold());
  }
}

class _ExampleScaffold extends StatelessWidget {
  const _ExampleScaffold();

  @override
  Widget build(BuildContext context) {
    // Provides a SheetController to the descendant widgets
    // to perform some sheet position driven animations.
    // The sheet will look up and use this controller unless
    // another one is manually specified in the constructor.
    // The descendant widgets can also get this controller by
    // calling 'DefaultSheetController.of(context)'.
    return const DefaultSheetController(
      child: Scaffold(
        // Enable this flag since the navigation bar
        // will be hidden when the sheet is dragged down.
        extendBody: true,
        body: Stack(
          children: [
            _RotatedFlutterLogo(),
            SheetViewport(
              child: _ExampleSheet(),
            ),
          ],
        ),
        bottomNavigationBar: _BottomAppBar(),
      ),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final minPosition = SheetAnchor.pixels(56 + bottomPadding);

    final physics = BouncingSheetPhysics(
      parent: SnappingSheetPhysics(
        behavior: SnapToNearest(
          anchors: [minPosition, const SheetAnchor.proportional(1)],
        ),
      ),
    );

    return DraggableSheet(
      minPosition: minPosition,
      physics: physics,
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 400,
          ),
        ),
      ),
    );
  }
}

class _BottomAppBar extends StatelessWidget {
  const _BottomAppBar();

  @override
  Widget build(BuildContext context) {
    // Lookup the nearest controller.
    final controller = DefaultSheetController.of(context);

    // It is easy to create sheet position driven animations
    // by using 'PositionDrivenAnimation', a special kind of
    // 'Animation<double>' whose value changes from 0 to 1 as
    // the sheet position changes from 'startPosition' to 'endPosition'.
    final animation = SheetPositionDrivenAnimation(
      controller: controller,
      // The initial value of the animation is required
      // since the sheet position is not available at the first build.
      initialValue: 1,
      // If null, the minimum position will be used. (Default)
      startPosition: null,
      // If null, the maximum position will be used. (Default)
      endPosition: null,
    );

    final bottomAppBar = BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );

    // Hide the bottom app bar when the sheet is dragged down.
    return SlideTransition(
      position: animation.drive(
        Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ),
      ),
      child: bottomAppBar,
    );
  }
}

class _RotatedFlutterLogo extends StatelessWidget {
  const _RotatedFlutterLogo();

  @override
  Widget build(BuildContext context) {
    final logo = RotationTransition(
      turns: SheetPositionDrivenAnimation(
        controller: DefaultSheetController.of(context),
        initialValue: 1,
      ),
      child: const FlutterLogo(size: 100),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Align(
          alignment: Alignment.topCenter,
          child: logo,
        ),
      ),
    );
  }
}

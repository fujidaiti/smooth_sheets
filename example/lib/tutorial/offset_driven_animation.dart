import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _OffsetDrivenAnimationExample());
}

class _OffsetDrivenAnimationExample extends StatelessWidget {
  const _OffsetDrivenAnimationExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: _ExampleScaffold());
  }
}

class _ExampleScaffold extends StatefulWidget {
  const _ExampleScaffold();

  @override
  State<_ExampleScaffold> createState() => _ExampleScaffoldState();
}

class _ExampleScaffoldState extends State<_ExampleScaffold> {
  late final SheetController controller;

  @override
  void initState() {
    super.initState();
    controller = SheetController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This line lets the SheetViewport take the full height of the screen.
      // Otherwise, its height will be reduced by the height of the bottom bar.
      extendBody: true,
      body: Stack(
        children: [
          _RotatedFlutterLogo(controller: controller),
          SheetViewport(
            child: _ExampleSheet(controller: controller),
          ),
        ],
      ),
      bottomNavigationBar: _BottomAppBar(controller: controller),
    );
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet({
    required this.controller,
  });

  final SheetController controller;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final minOffset = SheetOffset.absolute(56 + bottomPadding);

    return Sheet(
      controller: controller,
      snapGrid: SheetSnapGrid(
        snaps: [minOffset, const SheetOffset(1)],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: 400,
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }
}

class _BottomAppBar extends StatelessWidget {
  const _BottomAppBar({
    required this.controller,
  });

  final SheetController controller;

  @override
  Widget build(BuildContext context) {
    // It is easy to create sheet offset driven animations
    // by using SheetOffsetDrivenAnimation, a special kind of
    // Animation<double> whose value changes from 0 to 1 as
    // the sheet offset changes from startOffset to endOffset.
    final animation = SheetOffsetDrivenAnimation(
      controller: controller,
      // The initial value of the animation is required
      // since the sheet does not have an offset at the first build.
      initialValue: 1,
      // If null, the minimum offset defined by Sheet.snapGrid will be used. (Default)
      startOffset: null,
      // If null, the maximum offset defined by Sheet.snapGrid will be used. (Default)
      endOffset: null,
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
  const _RotatedFlutterLogo({
    required this.controller,
  });

  final SheetController controller;

  @override
  Widget build(BuildContext context) {
    final logo = RotationTransition(
      // Rotate the logo as the sheet offset changes.
      turns: SheetOffsetDrivenAnimation(
        controller: controller,
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

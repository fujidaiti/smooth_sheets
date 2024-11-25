import 'package:flutter/cupertino.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _CupertinoModalSheetExample());
}

class _CupertinoModalSheetExample extends StatelessWidget {
  const _CupertinoModalSheetExample();

  @override
  Widget build(BuildContext context) {
    // Cupertino widgets are used in this example,
    // but of course you can use material widgets as well.
    return const CupertinoApp(
      home: _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatelessWidget {
  const _ExampleHome();

  @override
  Widget build(BuildContext context) {
    // It is recommended to wrap the top most non-modal page within a navigator
    // with `CupertinoStackedTransition` to create more accurate ios 15 style
    // transition animation; that is, while the first modal sheet goes to fullscreen,
    // a non-modal page behind it will gradually reduce its size and the corner radius.
    return CupertinoStackedTransition(
      // The start and end values of the corner radius animation can be specified
      // as the `cornerRadius` property. If `null` is specified (the default value),
      // no corner radius animation is performed.
      cornerRadius: Tween(begin: 0.0, end: 16.0),
      child: CupertinoPageScaffold(
        child: Center(
          child: CupertinoButton.filled(
            onPressed: () => _showModalSheet(context, isFullScreen: false),
            child: const Text('Show Modal Sheet'),
          ),
        ),
      ),
    );
  }
}

void _showModalSheet(BuildContext context, {required bool isFullScreen}) {
  // Use `CupertinoModalSheetRoute` to show an ios 15 style modal sheet.
  // For declarative navigation (Navigator 2.0), use `CupertinoModalSheetPage` instead.
  final modalRoute = CupertinoModalSheetRoute(
    // Enable the swipe-to-dismiss behavior.
    swipeDismissible: true,
    // Use `SwipeDismissSensitivity` to tweak the sensitivity of the swipe-to-dismiss behavior.
    swipeDismissSensitivity: const SwipeDismissSensitivity(
      minFlingVelocityRatio: 2.0,
      minDragDistance: 300.0,
    ),
    builder: (context) => SheetViewport(
      child: switch (isFullScreen) {
        true => const _FullScreenSheet(),
        false => const _HalfScreenSheet(),
      },
    ),
  );

  Navigator.push(context, modalRoute);
}

class _HalfScreenSheet extends StatelessWidget {
  const _HalfScreenSheet();

  @override
  Widget build(BuildContext context) {
    // `CupertinoStackedTransition` won't start the transition animation until
    // the visible height of a modal sheet (the position) exceeds 50% of the screen height.
    return const DraggableSheet(
      initialPosition: SheetAnchor.proportional(0.5),
      minPosition: SheetAnchor.proportional(0.5),
      physics: BouncingSheetPhysics(
        parent: SnappingSheetPhysics(),
      ),
      child: _SheetContent(),
    );
  }
}

class _FullScreenSheet extends StatelessWidget {
  const _FullScreenSheet();

  @override
  Widget build(BuildContext context) {
    // Wrap the sheet with `SheetDismissible` to
    // enable the pull-to-dismiss action.
    return const DraggableSheet(
      child: _SheetContent(),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent();

  @override
  Widget build(BuildContext context) {
    // Nothing special here, just a simple modal sheet content.
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: CupertinoColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
      ),
      child: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton.filled(
                onPressed: () {
                  // `DefaultSheetController.of` is a handy way to obtain a `SheetController`
                  // that is exposed by the parent `CupertinoModalSheetRoute`.
                  DefaultSheetController.maybeOf(context)
                      ?.animateTo(const SheetAnchor.proportional(1));
                  _showModalSheet(context, isFullScreen: true);
                },
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
    );
  }
}

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
      theme: CupertinoThemeData(brightness: Brightness.dark),
      home: _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatelessWidget {
  const _ExampleHome();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: CupertinoButton.filled(
          onPressed: () => _showModalSheet(context, isFullScreen: false),
          child: const Text('Show Modal Sheet'),
        ),
      ),
    );
  }
}

void _showModalSheet(BuildContext context, {required bool isFullScreen}) {
  // Use `CupertinoModalSheetRoute` to show an ios style modal sheet.
  // For declarative navigation (Navigator 2.0), use `CupertinoModalSheetPage` instead.
  final modalRoute = CupertinoModalSheetRoute(
    // Enable the swipe-to-dismiss behavior.
    swipeDismissible: true,
    // Use `SwipeDismissSensitivity` to tweak the sensitivity of the swipe-to-dismiss behavior.
    swipeDismissSensitivity: const SwipeDismissSensitivity(
      minFlingVelocityRatio: 2.0,
      dismissalOffset: SheetOffset.proportionalToViewport(0.5),
    ),
    // The overlay color applied to the sheet when another sheet is being pushed.
    // Especially useful when stacking multiple modal sheets in dark mode,
    // so that the user can distinguish between the stacked sheets.
    overlayColor: const Color(0x33ffffff),
    builder: (context) => switch (isFullScreen) {
      true => const _FullScreenSheet(),
      false => const _HalfScreenSheet(),
    },
  );

  Navigator.push(context, modalRoute);
}

const _sheetDecoration = BoxSheetDecoration(
  size: SheetSize.stretch,
  decoration: ShapeDecoration(
    color: CupertinoColors.darkBackgroundGray,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
  ),
);

class _HalfScreenSheet extends StatefulWidget {
  const _HalfScreenSheet();

  @override
  State<_HalfScreenSheet> createState() => _HalfScreenSheetState();
}

class _HalfScreenSheetState extends State<_HalfScreenSheet> {
  late final SheetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SheetController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Sheet(
      controller: _controller,
      decoration: _sheetDecoration,
      initialOffset: const SheetOffset(0.5),
      snapGrid: const SheetSnapGrid(
        snaps: [SheetOffset(0.5), SheetOffset(1)],
      ),
      child: _SheetContent(
        controller: _controller,
      ),
    );
  }
}

class _FullScreenSheet extends StatelessWidget {
  const _FullScreenSheet();

  @override
  Widget build(BuildContext context) {
    return const Sheet(
      decoration: _sheetDecoration,
      child: _SheetContent(),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({this.controller});

  final SheetController? controller;

  @override
  Widget build(BuildContext context) {
    // Nothing special here, just a simple modal sheet content.
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton.filled(
              onPressed: () {
                controller?.animateTo(const SheetOffset(1));
                _showModalSheet(context, isFullScreen: true);
              },
              child: const Text('Stack modal sheet'),
            ),
            const SizedBox(height: 16),
            CupertinoButton.tinted(
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Hello'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open dialog'),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

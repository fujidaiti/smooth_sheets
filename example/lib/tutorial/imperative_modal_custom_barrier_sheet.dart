import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _ImperativeModalSheetCustomBarrierExample());
}

class _ImperativeModalSheetCustomBarrierExample extends StatelessWidget {
  const _ImperativeModalSheetCustomBarrierExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  late final SheetController sheetController;

  @override
  void initState() {
    super.initState();
    sheetController = SheetController();
  }

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FlutterLogo(size: 200),
          Center(
            child: ElevatedButton(
              onPressed: () => _showModalSheet(context),
              child: const Text('Show Modal Sheet with Custom Barrier'),
            ),
          ),
        ],
      ),
    );
  }

  void _showModalSheet(BuildContext context) {
    const sheetHeight = 600.0;

    final modalRoute = ModalSheetRoute(
      swipeDismissible: true,
      barrierBuilder: (route, onDismissCallback) {
        return GestureDetector(
          onTap: onDismissCallback,
          // AnimatedBuilder rebuilds when the sheet position changes
          child: AnimatedBuilder(
            animation: sheetController,
            builder: (context, child) {
              final offset = sheetController.value;

              // SheetController.value returns pixels, not a 0-1 range
              // Divide by sheet height to normalize
              final pixelOffset = offset ?? 0.0;
              final progress = (pixelOffset / sheetHeight).clamp(0.0, 1.0);

              final blurAmount = progress * 15.0;

              return BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurAmount,
                  sigmaY: blurAmount,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3 * progress),
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        );
      },
      swipeDismissSensitivity: const SwipeDismissSensitivity(
        minFlingVelocityRatio: 2.0,
        dismissalOffset: SheetOffset.proportionalToViewport(0.4),
      ),
      builder: (context) =>
          _ExampleSheet(controller: sheetController, height: sheetHeight),
    );

    Navigator.push(context, modalRoute);
  }
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet({required this.controller, required this.height});

  final SheetController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      controller: controller,
      snapGrid: const SheetSnapGrid(
        snaps: [SheetOffset(0.4), SheetOffset(1)],
      ),
      decoration: MaterialSheetDecoration(
        size: SheetSize.fit,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
      ),
      child: Container(
        height: height,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

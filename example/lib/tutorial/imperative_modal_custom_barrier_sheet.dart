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

class _ExampleHome extends StatelessWidget {
  const _ExampleHome();

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
}

void _showModalSheet(BuildContext context) {
  final sheetController = SheetController();
  const sheetHeight = 600.0;

  final modalRoute = ModalSheetRoute(
    swipeDismissible: true,
    barrierDismissible: true,
    barrierBuilder: (route, onDismissCallback) {
      // AnimatedBuilder rebuilds when the sheet position changes
      return AnimatedBuilder(
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
      );
    },
    swipeDismissSensitivity: const SwipeDismissSensitivity(
      minFlingVelocityRatio: 2.0,
      dismissalOffset: SheetOffset.proportionalToViewport(0.4),
    ),
    builder: (context) => _ExampleSheet(controller: sheetController),
  );

  Navigator.push(context, modalRoute);
}

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet({required this.controller});

  final SheetController controller;

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
        height: 600,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

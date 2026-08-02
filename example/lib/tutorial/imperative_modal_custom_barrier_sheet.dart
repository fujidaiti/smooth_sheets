import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const MaterialApp(home: _Home()));
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const FlutterLogo(size: 200),
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
    final modalRoute = ModalSheetRoute(
      swipeDismissible: true,
      barrierBuilder: (route, onDismissCallback) {
        return GestureDetector(
          onTap: onDismissCallback,
          child: ValueListenableBuilder(
            valueListenable: (route as ModalSheetRouteMixin).sheetVisibility,
            builder: (context, visibility, child) {
              final blur = visibility * 15.0;
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0x84 * visibility).round()),
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
      builder: (context) => const _Sheet(),
    );

    Navigator.push(context, modalRoute);
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Sheet(
      snapGrid: const SheetSnapGrid(snaps: [SheetOffset(0.4), SheetOffset(1)]),
      child: Container(
        height: 600,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

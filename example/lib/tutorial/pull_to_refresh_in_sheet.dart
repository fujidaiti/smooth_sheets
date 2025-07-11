import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _PullToRefreshInSheetExample());
}

class _PullToRefreshInSheetExample extends StatelessWidget {
  const _PullToRefreshInSheetExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    ModalSheetRoute(builder: (_) => const _MySheet()),
                  );
                },
                child: const Text('Show Sheet'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet();

  @override
  Widget build(BuildContext context) {
    return Sheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.fit,
        color: Colors.white,
      ),
      snapGrid: const SheetSnapGrid(
        snaps: [SheetOffset(0.5), SheetOffset(1)],
      ),
      physics: const ClampingSheetPhysics(),
      scrollConfiguration: const SheetScrollConfiguration(
        // 1. Enable this flag
        delegateUnhandledOverscrollToChild: true,
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SizedBox.fromSize(
          size: const Size.fromHeight(700),
          // 2. Wrap the scrollable with a RefreshIndicator
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 2));
              return;
            },
            child: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

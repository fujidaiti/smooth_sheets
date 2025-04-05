import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  runApp(const _ScrollablePageViewSheetExample());
}

/// An example of [Sheet] + [PageView].
class _ScrollablePageViewSheetExample extends StatelessWidget {
  const _ScrollablePageViewSheetExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    ModalSheetRoute(
                      builder: (_) => const _MySheet(),
                    ),
                  );
                },
                child: const Text('Show Sheet'),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MySheet extends StatelessWidget {
  const _MySheet();

  @override
  Widget build(BuildContext context) {
    return Sheet(
      scrollConfiguration: const SheetScrollConfiguration(),
      decoration: const MaterialSheetDecoration(
        size: SheetSize.stretch,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SizedBox(
          height: 600,
          child: PageView(
            children: const [
              _PageViewItem(),
              _PageViewItem(),
              _PageViewItem(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageViewItem extends StatefulWidget {
  const _PageViewItem();

  @override
  State<_PageViewItem> createState() => _PageViewItemState();
}

class _PageViewItemState extends State<_PageViewItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      itemCount: 100,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {},
          title: Text('Item $index'),
        );
      },
    );
  }
}

import 'package:cookbook/showcase/safari/menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Image.asset(
                  'assets/apple_website.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Column(
          children: [
            Divider(height: 1, color: CupertinoColors.systemGrey5),
            _AddressBar(),
            _ToolBar(),
          ],
        ),
      ),
    );
  }
}

class _AddressBar extends StatelessWidget {
  const _AddressBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: CupertinoColors.systemGrey5,
            offset: Offset(0, 1),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            CupertinoIcons.textformat,
            color: CupertinoColors.black,
          ),
          Expanded(
            child: Text(
              'apple.com',
              textAlign: TextAlign.center,
            ),
          ),
          Icon(
            CupertinoIcons.refresh,
            color: CupertinoColors.black,
          ),
        ],
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  const _ToolBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Icon(CupertinoIcons.left_chevron),
          ),
          const CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: null,
            child: Icon(CupertinoIcons.right_chevron),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => showMenuSheet(context),
            child: const Icon(CupertinoIcons.share),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Icon(CupertinoIcons.book),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Icon(CupertinoIcons.square_on_square),
          ),
        ],
      ),
    );
  }
}

import 'package:cookbook/showcase/safari/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void showEditActionsSheet(BuildContext context) {
  Navigator.push(
    context,
    CupertinoModalSheetRoute(
      swipeDismissible: true,
      builder: (context) {
        return const EditActionsSheet();
      },
    ),
  );
}

class EditActionsSheet extends StatelessWidget {
  const EditActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Sheet(
      scrollConfiguration: const SheetScrollConfiguration(),
      decoration: SheetDecorationBuilder(
        size: SheetSize.stretch,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: CupertinoColors.systemGroupedBackground,
              child: child,
            ),
          );
        },
      ),
      child: SheetContentScaffold(
        backgroundColor: Colors.transparent,
        topBar: CupertinoAppBar(
          title: const Text('Edit Actions'),
          trailing: CupertinoButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
        body: const _ActionList(),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 16),
        _ActionListSection(
          header: Text('Favorites'),
          children: [
            _ActionListItem(title: 'Copy', isFavorite: true),
            _ActionListItem(title: 'Save in Keep', isFavorite: true),
          ],
        ),
        SizedBox(height: 16),
        _ActionListSection(
          header: Text('Safari'),
          children: [
            _ActionListItem(title: 'Add to Reading List'),
            _ActionListItem(title: 'Add Bookmark'),
            _ActionListItem(title: 'Add to Favorites'),
            _ActionListItem(title: 'Add to Quick Note'),
            _ActionListItem(title: 'Find on Page'),
            _ActionListItem(title: 'Add to Home Screen'),
          ],
        ),
        SizedBox(height: 16),
        _ActionListSection(
          header: Text('Other actions'),
          children: [
            _ActionListItem(title: 'Markup'),
            _ActionListItem(title: 'Print'),
            _ActionListItem(title: 'Analyze with Bing Chat'),
            _ActionListItem(title: 'Open in Chrome'),
            _ActionListItem(title: 'Open using Mastodon'),
            _ActionListItem(title: 'Save to Pinterest'),
            _ActionListItem(title: 'Save to Dropbox'),
          ],
        ),
      ],
    );
  }
}

class _ActionListSection extends StatelessWidget {
  const _ActionListSection({
    this.header,
    required this.children,
  });

  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      header: header,
      children: children,
    );
  }
}

class _ActionListItem extends StatelessWidget {
  const _ActionListItem({
    required this.title,
    this.isFavorite = false,
  });

  final String title;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: Text(title),
      leading: isFavorite
          ? const Icon(
              CupertinoIcons.minus_circle_fill,
              color: CupertinoColors.systemRed,
            )
          : const Icon(
              CupertinoIcons.plus_circle_fill,
              color: CupertinoColors.systemGreen,
            ),
      trailing: isFavorite
          ? const Icon(
              CupertinoIcons.line_horizontal_3,
              color: CupertinoColors.systemGrey4,
            )
          : null,
    );
  }
}

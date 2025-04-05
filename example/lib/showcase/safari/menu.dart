import 'package:cookbook/showcase/safari/actions.dart';
import 'package:cookbook/showcase/safari/bookmark.dart';
import 'package:cookbook/showcase/safari/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void showMenuSheet(BuildContext context) {
  Navigator.push(
    context,
    CupertinoModalSheetRoute(
      swipeDismissible: true,
      builder: (context) => const MenuSheet(),
    ),
  );
}

class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const halfWayOffset = SheetOffset(0.5);
    return DefaultSheetController(
      child: Sheet(
        scrollConfiguration: const SheetScrollConfiguration(),
        initialOffset: halfWayOffset,
        snapGrid: SheetSnapGrid(
          snaps: [halfWayOffset, SheetOffset(1)],
        ),
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
        child: Column(
          children: [
            _TopBar(
              pageTitle: 'Apple',
              displayUrl: 'apple.com',
              faviconUrl: 'https://www.apple.com/favicon.ico',
            ),
            Divider(height: 1, color: CupertinoColors.systemGrey5),
            Expanded(child: _MenuList()),
          ],
        ),
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        const _MenuListSection(
          children: [
            _MenuListItem(
              title: 'Copy',
              icon: CupertinoIcons.doc_on_doc,
            ),
            _MenuListItem(
              title: 'Save in Keep',
              icon: CupertinoIcons.bookmark,
            ),
          ],
        ),
        const _MenuListSection(
          children: [
            _MenuListItem(
              title: 'Add to Reading List',
              icon: CupertinoIcons.eyeglasses,
            ),
            _MenuListItem(
              title: 'Add Bookmark',
              icon: CupertinoIcons.book,
            ),
            _MenuListItem(
              title: 'Add to Favorites',
              icon: CupertinoIcons.star,
            ),
            _MenuListItem(
              title: 'Find on Page',
              icon: CupertinoIcons.doc_text_search,
            ),
            _MenuListItem(
              title: 'Add to Home Screen',
              icon: CupertinoIcons.add_circled,
            ),
          ],
        ),
        const _MenuListSection(
          children: [
            _MenuListItem(
              title: 'Markup',
              icon: CupertinoIcons.pencil_outline,
            ),
            _MenuListItem(
              title: 'Print',
              icon: CupertinoIcons.printer,
            ),
          ],
        ),
        CupertinoListTile.notched(
          title: CupertinoButton(
            onPressed: () => showEditActionsSheet(context),
            child: const Text('Edit Actions...'),
          ),
        ),
      ],
    );
  }
}

class _MenuListSection extends StatelessWidget {
  const _MenuListSection({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: children,
    );
  }
}

class _MenuListItem extends StatelessWidget {
  const _MenuListItem({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: Text(title),
      trailing: Icon(icon, color: CupertinoColors.black),
      onTap: () {
        DefaultSheetController.of(context).animateTo(const SheetOffset(1));
        showEditBookmarkSheet(context);
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.pageTitle,
    required this.displayUrl,
    required this.faviconUrl,
  });

  final String pageTitle;
  final String displayUrl;
  final String faviconUrl;

  @override
  Widget build(BuildContext context) {
    final pageTitle = Text(
      this.pageTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium,
    );
    final displayUrl = Text(
      this.displayUrl,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: CupertinoColors.secondaryLabel),
    );

    return ColoredBox(
      color: CupertinoColors.systemGroupedBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SiteIcon(url: faviconUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [pageTitle, displayUrl],
              ),
            ),
            const SizedBox(width: 16),
            const _CloseButton(),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: const ShapeDecoration(
          shape: CircleBorder(),
          color: CupertinoColors.systemGrey5,
        ),
        child: const Center(
          child: Icon(
            CupertinoIcons.xmark,
            size: 18,
            color: CupertinoColors.black,
          ),
        ),
      ),
    );
  }
}

import 'package:cookbook/showcase/safari/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void showEditBookmarkSheet(BuildContext context) {
  Navigator.push(
    context,
    CupertinoModalSheetRoute(
      builder: (context) => const EditBookmarkSheet(
        pageUrl: 'https://www.apple.com',
        faviconUrl: 'https://www.apple.com/favicon.ico',
      ),
    ),
  );
}

class EditBookmarkSheet extends StatelessWidget {
  const EditBookmarkSheet({
    super.key,
    required this.pageUrl,
    required this.faviconUrl,
  });

  final String pageUrl;
  final String faviconUrl;

  @override
  Widget build(BuildContext context) {
    return SheetKeyboardDismissible(
      dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(),
      child: Sheet(
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
            title: const Text('Add Bookmark'),
            leading: CupertinoButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            trailing: CupertinoButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Save'),
            ),
          ),
          body: SizedBox.expand(
            child: CupertinoListSection.insetGrouped(
              children: [
                _BookmarkEditor(
                  pageUrl: pageUrl,
                  faviconUrl: faviconUrl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarkEditor extends StatelessWidget {
  const _BookmarkEditor({
    required this.pageUrl,
    required this.faviconUrl,
  });

  final String pageUrl;
  final String faviconUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SiteIcon(url: faviconUrl),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CupertinoTextField.borderless(
                padding: EdgeInsets.zero,
                autofocus: true,
              ),
              const Divider(color: CupertinoColors.systemGrey5),
              Text(
                pageUrl,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: CupertinoColors.secondaryLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

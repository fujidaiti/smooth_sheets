import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CupertinoAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final Widget title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey5)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (leading case final leading?)
            Positioned(
              left: 1,
              child: leading,
            ),
          DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!,
            child: title,
          ),
          if (trailing case final trailing?)
            Positioned(
              right: 1,
              child: trailing,
            ),
        ],
      ),
    );
  }
}

class SiteIcon extends StatelessWidget {
  const SiteIcon({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: Image.network(url),
    );
  }
}

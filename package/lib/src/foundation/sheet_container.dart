import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'sheet_controller.dart';
import 'sheet_extent.dart';
import 'sheet_viewport.dart';

@optionalTypeArgs
class SheetContainer<C extends SheetExtentConfig, E extends SheetExtent<C>>
    extends StatelessWidget {
  const SheetContainer({
    super.key,
    this.scopeKey,
    required this.controller,
    required this.config,
    required this.factory,
    required this.child,
  });

  final Key? scopeKey;
  final SheetController controller;
  final C config;
  final SheetExtentFactory<C, E> factory;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetExtentScope(
      key: scopeKey,
      config: config,
      controller: controller,
      factory: factory,
      isPrimary: true,
      child: Builder(
        builder: (context) {
          return SheetViewport(
            insets: MediaQuery.viewInsetsOf(context),
            extent: SheetExtentScope.of(context),
            child: SheetContentViewport(child: child),
          );
        },
      ),
    );
  }
}

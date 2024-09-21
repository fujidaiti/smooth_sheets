import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_extent.dart';

@internal
class DraggableSheetExtent extends SheetExtent {
  DraggableSheetExtent({
    required super.context,
    required super.minExtent,
    required super.maxExtent,
    required this.initialExtent,
    required super.physics,
    super.gestureTamperer,
    super.debugLabel,
  });

  /// {@template DraggableSheetExtent.initialExtent}
  /// The initial extent of the sheet.
  /// {@endtemplate}
  final Extent initialExtent;

  @override
  void applyNewContentSize(Size contentSize) {
    super.applyNewContentSize(contentSize);
    if (maybePixels == null) {
      setPixels(initialExtent.resolve(contentSize));
    }
  }
}

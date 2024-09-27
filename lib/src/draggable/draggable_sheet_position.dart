import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_position.dart';

@internal
class DraggableSheetPosition extends SheetPosition {
  DraggableSheetPosition({
    required super.context,
    required super.minPosition,
    required super.maxPosition,
    required this.initialPosition,
    required super.physics,
    super.gestureTamperer,
    super.debugLabel,
  });

  /// {@template DraggableSheetPosition.initialPosition}
  /// The initial position of the sheet.
  /// {@endtemplate}
  final SheetAnchor initialPosition;

  @override
  void applyNewContentSize(Size contentSize) {
    super.applyNewContentSize(contentSize);
    if (maybePixels == null) {
      setPixels(initialPosition.resolve(contentSize));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import '../foundation/sheet_extent.dart';

@internal
class DraggableSheetExtentFactory extends SheetExtentFactory<
    DraggableSheetExtentConfig, DraggableSheetExtent> {
  const DraggableSheetExtentFactory();

  @override
  DraggableSheetExtent createSheetExtent({
    required SheetContext context,
    required DraggableSheetExtentConfig config,
  }) {
    return DraggableSheetExtent(context: context, config: config);
  }
}

@internal
class DraggableSheetExtentConfig extends SheetExtentConfig {
  const DraggableSheetExtentConfig({
    required this.initialExtent,
    required super.minExtent,
    required super.maxExtent,
    required super.physics,
    super.debugLabel,
  });

  final Extent initialExtent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DraggableSheetExtentConfig &&
        other.initialExtent == initialExtent &&
        super == other;
  }

  @override
  int get hashCode => Object.hash(initialExtent, super.hashCode);
}

@internal
class DraggableSheetExtent extends SheetExtent<DraggableSheetExtentConfig> {
  DraggableSheetExtent({
    required super.context,
    required super.config,
  });

  @override
  void applyNewContentSize(Size contentSize) {
    super.applyNewContentSize(contentSize);
    if (metrics.maybePixels == null) {
      setPixels(config.initialExtent.resolve(metrics.contentSize));
    }
  }
}

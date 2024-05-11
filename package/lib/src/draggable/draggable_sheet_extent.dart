import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import '../foundation/activities.dart';
import '../foundation/sheet_extent.dart';

@internal
class DraggableSheetExtentFactory extends SheetExtentFactory {
  const DraggableSheetExtentFactory();

  @override
  SheetExtent createSheetExtent({
    required SheetContext context,
    required SheetExtentConfig config,
  }) {
    return DraggableSheetExtent(
      context: context,
      config: config,
    );
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
class DraggableSheetExtent extends SheetExtent {
  DraggableSheetExtent({
    required super.context,
    required super.config,
  });

  @override
  void goIdle() {
    beginActivity(_IdleDraggableSheetActivity());
  }
}

class _IdleDraggableSheetActivity extends IdleSheetActivity {
  _IdleDraggableSheetActivity();

  @override
  void didChangeContentSize(Size? oldDimensions) {
    super.didChangeContentSize(oldDimensions);
    final config = owner.config;
    final metrics = owner.metrics;
    if (metrics.maybePixels == null && config is DraggableSheetExtentConfig) {
      owner.setPixels(config.initialExtent.resolve(metrics.contentSize));
    }
  }
}

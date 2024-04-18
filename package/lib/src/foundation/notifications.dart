import 'package:flutter/widgets.dart';

import 'physics.dart';
import 'sheet_extent.dart';

/// A [Notification] that is dispatched when the sheet extent changes.
///
/// Sheet widgets notify their ancestors about changes to their extent.
/// There are 6 types of notifications:
/// - [SheetOverflowNotification], which is dispatched when the user tries
///   to drag the sheet beyond its draggable bounds but the sheet has not
///   changed its extent because its [SheetPhysics] does not allow it to be.
/// - [SheetUpdateNotification], which is dispatched when the sheet extent
///   is updated by other than user interaction such as animation.
/// - [SheetDragUpdateNotification], which is dispatched when the sheet
///   is dragged.
/// - [SheetDragStartNotification], which is dispatched when the user starts
///   dragging the sheet.
/// - [SheetDragEndNotification], which is dispatched when the user stops
///   dragging the sheet.
/// - [SheetDragCancelNotification], which is dispatched when the user cancels
///   dragging the sheet.
///
/// See also:
/// - [NotificationListener], which can be used to listen for notifications
///   in a subtree.
sealed class SheetNotification extends Notification {
  const SheetNotification({required this.metrics});

  /// A snapshot of the sheet metrics at the time this notification was sent.
  final SheetMetrics metrics;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description
      ..add('pixels: ${metrics.pixels}')
      ..add('minExtent: ${metrics.minPixels}')
      ..add('maxExtent: ${metrics.maxPixels}')
      ..add('viewportDimensions: ${metrics.viewportDimensions}')
      ..add('contentDimensions: ${metrics.contentDimensions}');
  }
}

/// A [SheetNotification] that is dispatched when the sheet extent
/// is updated by other than user interaction such as animation.
class SheetUpdateNotification extends SheetNotification {
  const SheetUpdateNotification({required super.metrics});
}

/// A [SheetNotification] that is dispatched when the sheet is dragged.
class SheetDragUpdateNotification extends SheetNotification {
  const SheetDragUpdateNotification({
    required super.metrics,
    required this.delta,
  });

  /// The change in the sheet extent since the previous notification.
  final double delta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('delta: $delta');
  }
}

/// A [SheetNotification] that is dispatched when the user starts
/// dragging the sheet.
class SheetDragStartNotification extends SheetNotification {
  /// Create a notification that is dispatched when the user
  /// starts dragging the sheet.
  const SheetDragStartNotification({
    required super.metrics,
    required this.dragDetails,
  });

  /// The details of the drag start.
  final DragStartDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('dragDetails: $dragDetails');
  }
}

/// A [SheetNotification] that is dispatched when the user stops
/// dragging the sheet.
class SheetDragEndNotification extends SheetNotification {
  /// Create a notification that is dispatched when the user
  /// stops dragging the sheet.
  const SheetDragEndNotification({
    required super.metrics,
    required this.dragDetails,
  });

  /// The details of the drag end.
  final DragEndDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('dragDetails: $dragDetails');
  }
}

/// A [SheetNotification] that is dispatched when the user cancels
/// dragging the sheet.
class SheetDragCancelNotification extends SheetNotification {
  /// Create a notification that is dispatched when the user
  /// cancels dragging the sheet.
  const SheetDragCancelNotification({required super.metrics});
}

/// A [SheetNotification] that is dispatched when the user tries
/// to drag the sheet beyond its draggable bounds but the sheet has not
/// changed its extent because its [SheetPhysics] does not allow it to be.
class SheetOverflowNotification extends SheetNotification {
  const SheetOverflowNotification({
    required super.metrics,
    required this.overflow,
  });

  /// The amount of overflow beyond the draggable bounds.
  final double overflow;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('overflow: $overflow');
  }
}

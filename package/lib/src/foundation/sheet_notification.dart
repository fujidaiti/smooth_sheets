import 'package:flutter/widgets.dart';

import 'sheet_extent.dart';
import 'sheet_physics.dart';
import 'sheet_status.dart';

/// A [Notification] that is dispatched when the sheet extent changes.
///
/// Sheet widgets notify their ancestors about changes to their extent.
/// There are 5 types of notifications:
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
///
/// See also:
/// - [NotificationListener], which can be used to listen for notifications
///   in a subtree.
sealed class SheetNotification extends Notification {
  const SheetNotification({
    required this.metrics,
    required this.status,
  });

  /// A snapshot of the sheet metrics at the time this notification was sent.
  final SheetMetrics metrics;

  /// The status of the sheet at the time this notification was sent.
  final SheetStatus status;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description
      ..add('pixels: ${metrics.pixels}')
      ..add('minExtent: ${metrics.minPixels}')
      ..add('maxExtent: ${metrics.maxPixels}')
      ..add('viewportSize: ${metrics.viewportSize}')
      ..add('viewportInsets: ${metrics.viewportInsets}')
      ..add('contentSize: ${metrics.contentSize}')
      ..add('status: $status');
  }
}

/// A [SheetNotification] that is dispatched when the sheet extent
/// is updated by other than user interaction such as animation.
class SheetUpdateNotification extends SheetNotification {
  const SheetUpdateNotification({
    required super.metrics,
    required super.status,
  });
}

/// A [SheetNotification] that is dispatched when the sheet is dragged.
class SheetDragUpdateNotification extends SheetNotification {
  const SheetDragUpdateNotification({
    required super.metrics,
    required this.delta,
    required this.dragDetails,
  }) : super(status: SheetStatus.dragging);

  /// The change in the sheet extent since the previous notification.
  final double delta;

  /// The details of a drag that caused this notification.
  final DragUpdateDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description
      ..add('delta: $delta')
      ..add('dragDetails: $dragDetails');
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
  }) : super(status: SheetStatus.dragging);

  /// The details of a drag that caused this notification.
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
  }) : super(status: SheetStatus.dragging);

  /// The details of a drag that caused this notification.
  ///
  /// This may be `null` if the drag is canceled.
  final DragEndDetails? dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('dragDetails: $dragDetails');
  }
}

/// A [SheetNotification] that is dispatched when the user tries
/// to drag the sheet beyond its draggable bounds but the sheet has not
/// changed its extent because its [SheetPhysics] does not allow it to be.
class SheetOverflowNotification extends SheetNotification {
  const SheetOverflowNotification({
    required super.metrics,
    required super.status,
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

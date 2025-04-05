import 'package:flutter/widgets.dart';

import 'drag.dart';
import 'model.dart';
import 'physics.dart';

/// A [Notification] that is dispatched when the sheet position changes.
///
/// Sheet widgets notify their ancestors about changes to their position.
/// There are 6 types of notifications:
/// - [SheetOverflowNotification], which is dispatched when the user tries
///   to drag the sheet beyond its draggable bounds but the sheet has not
///   changed its position because its [SheetPhysics] does not allow it to be.
/// - [SheetUpdateNotification], which is dispatched when the sheet position
///   is updated by other than user interaction such as animation.
/// - [SheetDragUpdateNotification], which is dispatched when the sheet
///   is dragged.
/// - [SheetDragStartNotification], which is dispatched when the user starts
///   dragging the sheet.
/// - [SheetDragEndNotification], which is dispatched when the user stops
///   dragging the sheet.
/// - [SheetDragCancelNotification], which is dispatched when the user
///  or the system cancels a drag gesture in the sheet.
///
/// See also:
/// - [NotificationListener], which can be used to listen for notifications
///   in a subtree.
sealed class SheetNotification extends Notification {
  const SheetNotification({
    required this.metrics,
  });

  /// A snapshot of the sheet metrics at the time this notification was sent.
  final SheetMetrics metrics;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description
      ..add('offset: ${metrics.offset}')
      ..add('minOffset: ${metrics.minOffset}')
      ..add('maxOffset: ${metrics.maxOffset}')
      ..add('size: ${metrics.size}')
      ..add('contentSize: ${metrics.contentSize}')
      ..add('viewportSize: ${metrics.viewportSize}')
      ..add('viewportPadding: ${metrics.viewportPadding}')
      ..add('viewportDynamicOverlap: ${metrics.viewportDynamicOverlap}')
      ..add('viewportStaticOverlap: ${metrics.viewportStaticOverlap}')
      ..add('contentBaseline: ${metrics.contentBaseline}');
  }
}

/// A [SheetNotification] that is dispatched when the sheet position
/// is updated by other than user interaction such as animation.
class SheetUpdateNotification extends SheetNotification {
  const SheetUpdateNotification({required super.metrics});
}

/// A [SheetNotification] that is dispatched when the sheet is dragged.
class SheetDragUpdateNotification extends SheetNotification {
  const SheetDragUpdateNotification({
    required super.metrics,
    required this.dragDetails,
  });

  /// The details of a drag that caused this notification.
  final SheetDragUpdateDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('dragDetails: $dragDetails');
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

  /// The details of a drag that caused this notification.
  final SheetDragStartDetails dragDetails;

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

  /// The details of a drag that caused this notification.
  final SheetDragEndDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('dragDetails: $dragDetails');
  }
}

/// A [SheetNotification] that is dispatched when the user
/// or the system cancels a drag gesture in the sheet.
class SheetDragCancelNotification extends SheetNotification {
  /// Create a notification that is dispatched when a drag gesture
  /// in the sheet is canceled.
  const SheetDragCancelNotification({
    required super.metrics,
  });
}

/// A [SheetNotification] that is dispatched when the user tries
/// to drag the sheet beyond its draggable bounds but the sheet has not
/// changed its position because its [SheetPhysics] does not allow it to be.
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

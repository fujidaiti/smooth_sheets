import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'model.dart';
import 'model_owner.dart';

/// Defines how a sheet should respond to drag gestures.
abstract class SheetDragConfiguration {
  /// Creates a [SheetDragConfiguration].
  ///
  /// The [hitTestBehavior] defaults to [HitTestBehavior.opaque].
  const factory SheetDragConfiguration({
    HitTestBehavior hitTestBehavior,
  }) = _StaticSheetDragConfiguration;

  /// A [SheetDragConfiguration] that disables dragging.
  static const SheetDragConfiguration disabled =
      _SheetDragConfigurationDisabled.instance;

  /// Defines how a sheet with this configuration should behave
  /// during hit-testing.
  ///
  /// Returning `null` means dragging is disabled.
  HitTestBehavior? get hitTestBehavior;
}

@immutable
class _StaticSheetDragConfiguration implements SheetDragConfiguration {
  const _StaticSheetDragConfiguration({
    this.hitTestBehavior = HitTestBehavior.opaque,
  });

  @override
  final HitTestBehavior hitTestBehavior;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _StaticSheetDragConfiguration &&
            runtimeType == other.runtimeType &&
            hitTestBehavior == other.hitTestBehavior;
  }

  @override
  int get hashCode => Object.hash(runtimeType, hitTestBehavior);
}

@immutable
class _SheetDragConfigurationDisabled implements SheetDragConfiguration {
  const _SheetDragConfigurationDisabled._();

  static const instance = _SheetDragConfigurationDisabled._();

  @override
  HitTestBehavior? get hitTestBehavior => null;

  @override
  bool operator ==(Object other) {
    assert(
      identical(this, instance),
      'There should only be one instance of disabled configuration',
    );
    return identical(this, other);
  }

  @override
  int get hashCode => identityHashCode(this);
}

@internal
class SheetDraggable extends StatefulWidget {
  const SheetDraggable({
    super.key,
    required this.configuration,
    required this.child,
  });

  final SheetDragConfiguration configuration;
  final Widget child;

  @override
  State<SheetDraggable> createState() => _SheetDraggableState();
}

class _SheetDraggableState extends State<SheetDraggable> {
  late final VerticalDragGestureRecognizer _gestureRecognizer;
  SheetModel? _model;
  Drag? _currentDrag;

  @override
  void initState() {
    super.initState();
    _gestureRecognizer =
        VerticalDragGestureRecognizer(
            debugOwner: kDebugMode ? runtimeType : null,
            supportedDevices: const {PointerDeviceKind.touch},
          )
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd
          ..onCancel = _handleDragCancel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _model = SheetModelOwner.of(context);
  }

  @override
  void dispose() {
    _model = null;
    _disposeDrag();
    _gestureRecognizer.dispose();
    super.dispose();
  }

  void _disposeDrag() {
    _currentDrag = null;
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_currentDrag == null);
    if (widget.configuration != SheetDragConfiguration.disabled) {
      _currentDrag = _model?.drag(details, _disposeDrag);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _currentDrag?.update(details);
  }

  void _handleDragEnd(DragEndDetails details) {
    _currentDrag?.end(details);
    _disposeDrag();
  }

  void _handleDragCancel() {
    _currentDrag?.cancel();
    _disposeDrag();
  }

  @override
  Widget build(BuildContext context) {
    return _DragGestureListener(
      dragConfiguration: widget.configuration,
      gestureRecognizer: _gestureRecognizer,
      child: widget.child,
    );
  }
}

class _DragGestureListener extends SingleChildRenderObjectWidget {
  const _DragGestureListener({
    required this.dragConfiguration,
    required this.gestureRecognizer,
    required super.child,
  });

  final SheetDragConfiguration dragConfiguration;
  final GestureRecognizer gestureRecognizer;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDragGestureListener(
      dragConfiguration: dragConfiguration,
      gestureRecognizer: gestureRecognizer,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDragGestureListener renderObject,
  ) {
    renderObject
      ..dragConfiguration = dragConfiguration
      ..gestureRecognizer = gestureRecognizer;
  }
}

class _RenderDragGestureListener extends RenderProxyBoxWithHitTestBehavior {
  _RenderDragGestureListener({
    required this.dragConfiguration,
    required this.gestureRecognizer,
  }) : super(
         // This value won't be used on runtime.
         behavior: HitTestBehavior.deferToChild,
       );

  SheetDragConfiguration dragConfiguration;
  GestureRecognizer gestureRecognizer;

  @override
  HitTestBehavior get behavior {
    final value = dragConfiguration.hitTestBehavior;
    assert(value != null, 'Should not be used when dragging is disabled');
    return value!;
  }

  @override
  set behavior(HitTestBehavior value) {
    assert(false, 'Should not be used');
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (dragConfiguration.hitTestBehavior == null) {
      // When drag is disabled, still hit-test children so that
      // child widgets (e.g. buttons) remain interactive.
      return size.contains(position) &&
          hitTestChildren(result, position: position);
    }
    return super.hitTest(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return dragConfiguration.hitTestBehavior != null &&
        super.hitTestSelf(position);
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (event is PointerDownEvent) {
      gestureRecognizer.addPointer(event);
    } else if (event is PointerPanZoomStartEvent) {
      gestureRecognizer.addPointerPanZoom(event);
    }
  }
}

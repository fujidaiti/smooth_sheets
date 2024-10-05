import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

/// Special version of [Overlay] that sizes itself to fit its [child].
///
/// This is used to prevent overlay components, such as the popup menu
/// opened by a [DropdownButton], from being overflown by the sheet's bounds
/// (see https://github.com/fujidaiti/smooth_sheets/issues/167).
///
/// Here are the key points of [Overlay]'s internal layout mechanism
/// to understand the counterintuitive implementation of this widget:
///
/// 1. The [Overlay] sizes itself to fit the first non-positioned [OverlayEntry]
///  with `canSizeOverlay: true` in its entries, **only** if the given
///  constraints are infinite (see _RenderTheater.performLayout in widgets/overlay.dart).
/// 2. The [Overlay] passes the given constraints to the first entry as-is,
///  if the entry is not positioned (meaning that the entry is not wrapped in
///  a [Positioned] widget).
///
/// With these points in mind, the following is the layout mechanism of this
/// widget to make the [Overlay] size itself to fit its child:
///
/// 1. The [_RenderShrinkWrapOverlay] wraps the given constraints with
///  [_OverlayConstraints] and passes it to the underlying [Overlay].
/// 2. Before the [Overlay] performs layout, the constraints (type of
///  [_OverlayConstraints]) are infinite, so the [Overlay] lays out
///  the first (and only) entry with the inherited constraints
///  ([_OverlayConstraints.entryConstraints]).
/// 3. After the first entry is laid out, it updates the [Overlay]'s constraints
/// to be tight to the entry's size by setting [_OverlayConstraints.entrySize]
///  (this is done by [_RenderOverlayEntryLayout.performLayout]).
///  Updating the constraints is necessary as some [Overlay] related components
///  such as [DropdownMenu] assume that the [Overlay] has a finite constraints.
/// 4. The [Overlay] then sizes itself to fit the entry's size.
@internal
class ShrinkWrapOverlay extends SingleChildRenderObjectWidget {
  factory ShrinkWrapOverlay({
    required Widget child,
  }) {
    return ShrinkWrapOverlay._(
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            opaque: true,
            maintainState: true,
            canSizeOverlay: true,
            builder: (_) {
              return _OverlayEntryLayout(child: child);
            },
          ),
        ],
      ),
    );
  }

  const ShrinkWrapOverlay._({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderShrinkWrapOverlay();
  }
}

class _RenderShrinkWrapOverlay extends RenderProxyBox {
  @override
  void performLayout() {
    assert(child != null);
    // This constraints object is passed to and held by
    // the child render object associated with the underlying Overlay.
    // Later, the child render object will pass this constraints to
    // the first OverlayEntry in its layout method without modification.
    final overlayConstraints =
        _OverlayConstraints(entryConstraints: constraints);
    child!.layout(overlayConstraints, parentUsesSize: true);
    size = child!.size;
  }
}

class _OverlayEntryLayout extends SingleChildRenderObjectWidget {
  const _OverlayEntryLayout({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverlayEntryLayout();
  }
}

class _RenderOverlayEntryLayout extends RenderProxyBox {
  @override
  void performLayout() {
    assert(constraints is _OverlayConstraints);
    assert(child != null);
    final overlayConstraints = constraints as _OverlayConstraints;
    child!.layout(overlayConstraints.entryConstraints, parentUsesSize: true);
    overlayConstraints.entrySize = child!.size;
    size = child!.size;
  }
}

/// Constraints of the inner [Overlay] widget in a [ShrinkWrapOverlay].
///
/// This is an infinite box constraints until the [entrySize] is set.
/// Once the [entrySize] is set, the constraints become a finite box constraints
/// that tightly fits the [entrySize]. See [ShrinkWrapOverlay] for more details.
///
/// The [entryConstraints] is passed to the [Overlay]'s first entry.
class _OverlayConstraints extends BoxConstraints {
  const _OverlayConstraints({
    required this.entryConstraints,
  }) : super(
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
        );

  /// Constraints that will be passed to
  /// the first [OverlayEntry] in the [Overlay].
  ///
  /// See [_RenderOverlayEntryLayout.performLayout].
  final BoxConstraints entryConstraints;

  // Use Expando instead of simply storing the value as a member variable,
  // because BoxConstraints is marked as @immutable, so we can't define mutable
  // members in this class.
  static final _entrySizeRegistry = Expando<Size>();

  /// The finalized size of the [Overlay]'s first entry.
  Size? get entrySize => _entrySizeRegistry[this];

  set entrySize(Size? value) => _entrySizeRegistry[this] = value;

  @override
  double get minWidth => entrySize?.width ?? super.minWidth;

  @override
  double get maxWidth => entrySize?.width ?? super.maxWidth;

  @override
  double get minHeight => entrySize?.height ?? super.minHeight;

  @override
  double get maxHeight => entrySize?.height ?? super.maxHeight;
}

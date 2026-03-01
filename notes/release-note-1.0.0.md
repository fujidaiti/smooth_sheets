# v1.0.0 Release Notes

The first stable release of `smooth_sheets`! (Breaking changes are denoted with a 💥.)

## Global Drag Configuration for PagedSheet

`PagedSheet` now accepts a `dragConfiguration` parameter that sets the default drag behavior for all routes in the sheet. Individual routes can still override this via their own `dragConfiguration`. See the [documentation][1] for details.

[1]: https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/PagedSheet/dragConfiguration.html

#### `Sheet.dragConfiguration` is now non-nullable 💥

The `dragConfiguration` properties on `Sheet`, `PagedSheetRoute`, and `PagedSheetPage` are now non-nullable. If you were passing `null` to disable dragging, use `SheetDragConfiguration.disabled` instead.

**BEFORE:**

```dart
Sheet(
  dragConfiguration: null, // Disabled dragging
  child: MyContent(),
)
```

**AFTER:**

```dart
Sheet(
  dragConfiguration: SheetDragConfiguration.disabled,
  child: MyContent(),
)
```

#### Default `HitTestBehavior` changed from `translucent` to `opaque` 💥

The default `hitTestBehavior` in `SheetDragConfiguration` has changed from `HitTestBehavior.translucent` to `HitTestBehavior.opaque`, so that the sheet can be dragged even from transparent areas such as padding.

## Loose Width Constraints for Sheet Content

Sheet content is no longer forced to match the viewport width. The width constraint is now loose (`minWidth: 0`), allowing content to be narrower than the viewport. This enables pop-up menu-style sheets and other use cases where the sheet should not fill the full width. When the content is narrower than the viewport, the sheet is automatically centered horizontally.

#### Sheet content no longer gets tight width constraints 💥

Previously, the sheet forced its content to be exactly as wide as the viewport. Now content is free to size itself within `0` to the viewport width. Content that does not specify an explicit width and has no child (e.g., `SizedBox(height: 500)`) will shrink to zero width instead of filling the viewport.

If your content relies on filling the full width, explicitly set `width: double.infinity` or use a widget that naturally expands such as `SizedBox.expand`, `Column` with `CrossAxisAlignment.stretch`, or `SizedBox.fromSize(size: Size.fromHeight(...))`.

**BEFORE:**

```dart
Sheet(
  child: SizedBox(height: 500), // Implicitly filled viewport width
)
```

**AFTER:**

```dart
Sheet(
  child: SizedBox(
    width: double.infinity, // Explicitly fill available width
    height: 500,
  ),
)
```

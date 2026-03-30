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

## BouncingSheetPhysics no longer accepts custom spring 💥

The `spring` parameter has been removed from `BouncingSheetPhysics`'s constructor as part of a fix for #435. If you were using a custom spring, you can extend `BouncingSheetPhysics` and override the `spring` getter to return your custom spring.

**BEFORE:**

```dart
BouncingSheetPhysics(spring: customSpring);
```

**AFTER:**

```dart
class MyPhysics extends BouncingSheetPhysics {
  MyPhysics({super.bounceExtent, super.resistance});

  @override
  SpringDescription get spring => customSpring;
}
```

## Other changes

- Fix inconsistent BouncingSheetPhysics resistance in over-drag vs. ballistic animation (#435)

## Other breaking changes 💥

- `kDefaultSheetSpring` has been removed from the public API.

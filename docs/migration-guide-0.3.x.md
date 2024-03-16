# Migration guide to 0.3.x from 0.2.x

## enablePullToDismiss removed from modal sheets

The `enablePullToDismiss` property, that enables the pull-to-dismiss action for the modal sheets, was removed from the constructors of `ModalSheetRoute`, `ModalSheetPage`, `CupertinoModalSheetRoute,` and `CupertinoModalSheetPage`. Instead, wrap the sheet with a `SheetDismissible` to create the same behavior. See the [tutorial code](https://github.com/fujidaiti/smooth_sheets/blob/90c8f10b89db5b18c1fd382692cfba3a09be67f1/cookbook/lib/tutorial/imperative_modal_sheet.dart#L52) for more detailed usage.

**BEFORE:**

```dart
ModalSheetRoute(
  enablePullToDismiss: true,
  (context) => MySheet(...),
);
```

**AFTER:**

```dart
ModalSheetRoute(
  (context) => SheetDismissible(
    onDismiss: () {...}, // Dismissing event can be handled here.
    child: MySheet(...),
  ),
);
```

## SnapToNearest can no longer be `const`

`SnapToNearest` can no longer be a `const` in exchange for performance improvement. Due to this, `SnapToNearestEdge` is now used as the default value for `SnappingSheetPhysics.snappingBehavior` instead. If you want the sheet to snap only to the `minPixels` and the `maxPixels`, it is preferable to use `SnapToNearestEdge` rather than `SnapToNearest` as it is more simplified and performant.

**BEFORE:**

```dart
physics: const StretchingSheetPhysics(
  parent: SnappingSheetPhysics(
    snappingBehavior: SnapToNearest(
      snapTo: [
        Extent.proportional(0.2),
        Extent.proportional(0.5),
        Extent.proportional(1),
      ],
    ),
  ),
),
```

**AFTER:**

```dart
physics: StretchingSheetPhysics( // Can no longer be a const
  parent: SnappingSheetPhysics(
    snappingBehavior: SnapToNearest(
      snapTo: [
        const Extent.proportional(0.2),
        const Extent.proportional(0.5),
        const Extent.proportional(1),
      ],
    ),
  ),
),
```

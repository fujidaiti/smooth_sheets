# v0.17.0 Release Notes

This version introduces a new flexible padding API for sheets, replacing the previous overlap-based approach with a more intuitive and powerful design.

## Replaced `shrinkChildToAvoidDynamicOverlap` and `shrinkChildToAvoidStaticOverlap` with `padding` 💥

Previously, `Sheet` and `PagedSheet` offered two boolean flags — `shrinkChildToAvoidDynamicOverlap` and `shrinkChildToAvoidStaticOverlap` — to control whether the sheet content should shrink to avoid system UI elements like the software keyboard or screen notches. While functional, this approach was limited: it only supported shrinking (not offsetting), offered no fine-grained control over which edges to adjust, and required understanding the distinction between "dynamic" and "static" overlaps.

These flags have been replaced by a single `EdgeInsets padding` property on `Sheet` and `PagedSheet`. Instead of toggling automatic behaviors, you now specify the exact padding to apply around the sheet content. This gives full control over how the content responds to the keyboard, safe areas, or any other insets.

**Usage:**

Push the content above the keyboard:

```dart
Sheet(
  padding: EdgeInsets.only(
    bottom: MediaQuery.viewInsetsOf(context).bottom,
  ),
  child: Container(height: 400),
);
```

Respect the bottom safe area when the keyboard is closed, and avoid the keyboard when open:

```dart
Sheet(
  padding: EdgeInsets.only(
    bottom: math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    ),
  ),
  child: Container(height: 400),
);
```

### Why `padding` instead of a `Padding` widget?

Although wrapping the child with a `Padding` widget may appear equivalent, they differ in a key way: the `Padding` widget's size is included in the child's size calculation, but `Sheet.padding` is not. This distinction matters when using `SheetOffset`s that depend on the child's size, such as snap positions.

For example, with a sheet whose snap grid includes `SheetOffset(0.5)` and a child height of 400, the snap position resolves to 200 pixels. If a `Padding` widget is used to avoid the keyboard and the keyboard is 200 pixels tall, the child's height becomes 600, and the snap position shifts to 300 — not the expected 200 pixels above the keyboard. With `Sheet.padding`, the snap position remains at 200 regardless of the keyboard height.

See [this example](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/sheet_padding.dart) for a visual comparison.

### `Sheet.padding` vs. `SheetViewport.padding`

Both `Sheet.padding` and `SheetViewport.padding` can be used to avoid the keyboard, but they produce different visual results:

- `Sheet.padding` pushes the **content** inside the sheet above the keyboard, without moving the sheet itself.
- `SheetViewport.padding` pushes the **entire sheet** above the keyboard, keeping the sheet layout unchanged.

```dart
// Push the entire sheet up above the keyboard.
SheetViewport(
  padding: EdgeInsets.only(
    bottom: MediaQuery.viewInsetsOf(context).bottom,
  ),
  child: Sheet(...),
);
```

### Breaking Changes

The following properties have been removed from `Sheet` and `PagedSheet`:

- `shrinkChildToAvoidDynamicOverlap`
- `shrinkChildToAvoidStaticOverlap`

**BEFORE**

```dart
Sheet(
  shrinkChildToAvoidDynamicOverlap: true,
  shrinkChildToAvoidStaticOverlap: true,
  child: MyContent(),
);
```

**AFTER**

```dart
Sheet(
  padding: EdgeInsets.only(
    bottom: math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    ),
  ),
  child: MyContent(),
);
```

## Replaced `viewportDynamicOverlap` and `viewportStaticOverlap` with `contentMargin` 💥

The internal metrics properties `viewportDynamicOverlap` and `viewportStaticOverlap` on `SheetMetrics`, `SheetLayoutSpec`, and related types have been replaced by a single `contentMargin` property. This simplifies the data model by collapsing two separate overlap concepts into one unified margin.

### Breaking Changes

The following properties have been removed:

- `SheetMetrics.viewportDynamicOverlap`
- `SheetMetrics.viewportStaticOverlap`
- `SheetLayoutSpec.viewportDynamicOverlap`
- `SheetLayoutSpec.viewportStaticOverlap`
- `SheetLayoutSpec.shrinkContentToAvoidDynamicOverlap`
- `SheetLayoutSpec.shrinkContentToAvoidStaticOverlap`

Use `contentMargin` instead.

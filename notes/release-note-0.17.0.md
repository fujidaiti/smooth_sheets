# v0.17.0 Release Notes

This version introduces a `padding` property on `Sheet` and `PagedSheet`, which gives you full control over how the sheet content responds to the keyboard, safe areas, or any other insets.

## Context

Previously, `Sheet` and `PagedSheet` offered two boolean flags — `shrinkChildToAvoidDynamicOverlap` and `shrinkChildToAvoidStaticOverlap` — to control whether a sheet automatically resizes its child to avoid the on-screen keyboard or screen notches. While they worked well in many cases, there're still cases where those simple 2 flags can't cover; for example, a floating sheet that has margin around it and the bottom margin changes depending on whether the keyboard is open.

## What's new?

A `padding` property has been added to `Sheet` and `PagedSheet` widets to replace the two flags. This change has also eliminated the automatic content resizing behavior, so you now take responsibility for padding the sheet content to avoid the keyboard and the screen notches.

Although it sounds like a downgrade, it enables you to build more complex layouts that couldn't be achieved with the legacy flags. Here's an example of such layouts where the sheet avoids the screen notches at the first view, and shifts itself above the keyboard when it opens while preseving a fixed size of space between the keyboard and the sheet. Weirdly, this wan't possible because `shrinkChildToAvoidDynamicOverlap` interfered `SheetViewport.padding`, completely ignoring the padding when the keyboard is shown.

// TODO Add an example usage of the padding property.

// TODO: Add images of the example case

### Sheet.padding vs. SheetViewport.padding vs. Padding widget

You might wonder what it actually differs from  `SheetViewport.padding` and wrapping the sheet content (`Sheet.child`) with a `Padding` from the Flutter SDK. While [this interactive example](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/sheet_padding.dart) is useful for understanding the differences with a visual comparison, but for TL;DL:

- use `Sheet.padding` to inset the content,
- use `SheetViewport.padding` to add margin around the sheet itself, and
- wrapping the context with a `Padding` doesn't fit in most cases.

## Breaking Changes

`shrinkChildToAvoidDynamicOverlap` and `shrinkChildToAvoidStaticOverlap` flags on `Sheet` and `PagedSheet` **were removed**. Please follow the instructions below to migrate from the two flags to the padding property. The basic ruls are to replace:

- `shrinkChildToAvoidDynamicOverlap: true` with a padding of `MediaQuery.viewInsetsOf(context).bottom`
-  `shrinkChildToAvoidStaticOverlap: true` with a padding of `MediaQuery.viewPaddingOf(context).bottom`

### For sheets with `shrinkChildToAvoidDynamicOverlap: true`

You may enabled `shrinkChildToAvoidDynamicOverlap` to automatically shifts the sheet content upward to avoid the keyboard. It was true by default, so sheets not explicitly disabling that flag should also migrate to the padding property as follows:

**BEFORE**

```dart
Sheet(
  shrinkChildToAvoidDynamicOverlap: true,
  child: ...,
);
```

**AFTER**

```dart
Sheet(
  padding: EdgeInsets.only(
  	bottom: MediaQuery.viewInsetsOf(context).bottom,
  ),
  child: ...,
);
```

### For sheets with `shrinkChildToAvoidStaticOverlap: true`

Follow this migration guide if you enabled `shrinkChildToAvoidStaticOverlap` to automatically pads the content to avoid the screen notches at the bottom. It was false by default, so sheets not explicitly enabling that flag are not affected by this change.

**BEFORE**

```dart
Sheet(
  shrinkChildToAvoidStaticOverlap: true,
  child: ...,
);
```

**AFTER**

```dart
Sheet(
  padding: EdgeInsets.only(
  	bottom: MediaQuery.viewPaddingOf(context).bottom,
  ),
  child: ...,
);
```

### For sheets with both `shrinkChildToAvoidDynamicOverlap: true` and `shrinkChildToAvoidStaticOverlap: true`

**BEFORE**

```dart
Sheet(
  shrinkChildToAvoidDynamicOverlap: true,
  shrinkChildToAvoidStaticOverlap: true,
  child: ...,
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
  child: ...,
);
```



## Other Breaking Changes

The following properties have also been removed:

- `SheetMetrics.viewportDynamicOverlap`
  - Use `MediaQuery.viewInsetsOf(context).bottom` from descendant widgets of a sheet instead.

- `SheetMetrics.viewportStaticOverlap`
  - Use `MediaQuery.viewPaddingOf(context).bottom` from descendant widgets of a sheet instead.

- `SheetLayoutSpec.viewportDynamicOverlap`
  - Use `MediaQuery.viewInsetsOf(context).bottom` from descendant widgets of a sheet instead.

- `SheetLayoutSpec.viewportStaticOverlap`
  - Use `MediaQuery.viewPaddingOf(context).bottom` from descendant widgets of a sheet instead.

- `SheetLayoutSpec.shrinkContentToAvoidDynamicOverlap`
- `SheetLayoutSpec.shrinkContentToAvoidStaticOverlap`

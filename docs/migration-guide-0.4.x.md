# Migration guide to 0.4.x from 0.3.x

## requiredMinExtentForStickyBottomBar removed from SheetContentScaffold

As of introducing of `BottomBarVisibility` widgets, the `requiredMinExtentForStickyBottomBar` property was removed from the `SheetContentScaffold`. Use one of subclasses of the `BottomBarVisibility` such as `StickyBottomBarVisibility` and `ConditionalStickyBottomBarVisibility`. See [the API documentation](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BottomBarVisibility-class.html) for more details.

**BEFORE:**

```dart
SheetContentScaffold(
  requiredMinExtentForStickyBottomBar: const Extent.proportional(0.5),
  body: SizedBox.expand(),
  bottomBar: BottomBar(),
);
```

**AFTER:**

```dart
SheetContentScaffold(
  body: SizedBox.expand(),
  // This widget keeps the child BottomBar always visible
  // regardless of the sheet position as long as the `getIsVisible`
  // callback returns true.
  bottomBar: ConditionalStickyBottomBarVisibility(
    getIsVisible: (metrics) {
      final halfSize = Extent.proportional(0.5).resolve(metrics.contentDimensions);
      return metrics.pixels > halfSize;
    },
    child: BottomBar(),
  ),
);
```


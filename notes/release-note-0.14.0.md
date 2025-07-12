# v0.14.0 Release Note

## 🎉 New Features

### Cupertino Modal Sheet Overlay Effect - #25

Added `overlayColor` parameter to `CupertinoModalSheetPage` and `CupertinoModalSheetRoute` to apply a toning overlay effect when stacking modal sheets. This matches native iOS behavior where background sheets receive a subtle overlay when another sheet is presented, creating a more authentic iOS experience. The feature improves visual hierarchy and is particularly useful in dark mode where background sheets can be difficult to distinguish.

**Usage:**

```dart
CupertinoModalSheetPage(
  overlayColor: const Color(0x33ffffff), // A translucent white color
  child: MySheetContent(),
)
```

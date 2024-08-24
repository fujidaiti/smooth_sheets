# Migration guide to 0.8.x from 0.7.x

Here is the summary of the breaking changes included in the version 0.8.0.

## Changes in StretchingSheetPhysics

### 'Stretching' was renamed to 'Bouncing'

`StretchingSheetPhysics` was renamed to `BouncingSheetPhysics` to better reflect its behavior, as it does not change the actual size of the sheet, but rather allows the sheet position to go beyond the content bounds. Accordingly, the other related classes and properties were also renamed.

### New way to control the bouncing behavior of a sheet

[BouncingSheetBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BouncingSheetBehavior-class.html) was added as the new way to control the bouncing behavior of a sheet. It replaces `StretchingSheetPhysics.stretchingRange` property, which has been removed.

**BEFORE:**

```dart
const physics = StretchingSheetPhysics(
  stretchingRange: Extent.proportional(0.1),
);
```

**AFTER:**

```dart
const physics = BouncingSheetPhysics(
  behavior: FixedBouncingBehavior(Extent.proportional(0.1)),
);
```

See also:

- [FixedBouncingBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/FixedBouncingBehavior-class.html), which allows the sheet position to exceeds the content bounds by a fixed amount.
- [DirectionAwareBouncingBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/DirectionAwareBouncingBehavior-class.html), which is similar to `FixedBouncingBehavior`, but different bounceable ranges can be set for each direction.
- [tutorial/bouncing_behaviors.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/bouncing_behaviors.dart), an interactive example of `BouncingBehavior` classes.

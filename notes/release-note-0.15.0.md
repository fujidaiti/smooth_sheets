# v0.15.0 Release Notes

> [!IMPORTANT]
>
> - Flutter SDK 3.29+ is now required.
> - `SwipeDismissSensitivity.minDragDistance` has been removed.

## 🎉 Added dismissalOffset: A more intuitive and powerful way to define the threshold for swipe-to-dismiss actions on modals

*Reported in [#415](https://github.com/fujidaiti/smooth_sheets/pull/415), fixed in [#415](https://github.com/fujidaiti/smooth_sheets/pull/415) thanks to @bjartebore*

Previously, we used `SwipeDismissSensitivity.minDragDistance` to define how many pixels the user had to drag down the modal sheet to close it. However, since it only accepted a threshold distance in logical pixels, it was difficult to create a consistent UX across various device sizes and sheet sizes.

`SwipeDismissSensitivity.dismissalOffset` has been introduced as a replacement for `minDragDistance` and tackle this problem. It allows us to define the modal's dismissal threshold in terms of `SheetOffset`, below which the sheet will be dismissed when the drag ends. This change provides much greater control over when sheets should be dismissed, allowing thresholds to depend on percentages, absolute pixels, or even custom logic that adapts to content size or viewport dimensions.

**Usage:**
```dart
// Dismiss if only 40% or less of the sheet is visible when the drag ends
const SwipeDismissSensitivity(dismissalOffset: SheetOffset(0.4));

// Dismiss if only 200 pixels or less of the sheet is visible when the drag ends
const SwipeDismissSensitivity(dismissalOffset: SheetOffset.absolute(200));

// Dismiss if the sheet is in the bottom half of the screen when the drag ends
const SwipeDismissSensitivity(dismissalOffset: SheetOffset.proportionalToViewport(0.5));

// Custom threshold for more complex use cases
const SwipeDismissSensitivity(dismissalOffset: CustomThreshold());

class CustomThreshold implements SheetOffset {
  const CustomThreshold();
  
  @override
  double resolve(ViewportLayout metrics) {
    return max(metrics.contentSize.height * 0.5, 80);
  }
}
```

### Migrating from minDragDistance

Unfortunately, there's no straightforward way to migrate from `minDragDistance` to `dismissalOffset` as they represent different thresholds. While `minDragDistance` describes how many pixels the user has to drag the sheet to dismiss the modal, `dismissalOffset` defines the distance from the bottom edge of the route's viewport to the top edge of the sheet, below which the sheet will dismiss when the drag ends.

This is a special case, but if you know the sheet's height in advance, it's possible to migrate to the new API while keeping the current behavior. For example, if the sheet's height is 500 and the `minDragDistance` is 100, you can set `dismissalOffset` to `SheetOffset.absolute(500 - 100)`.

## Other changes

- fix: NavigatorEventObserver assertion error when pop during push transition ([#416](https://github.com/fujidaiti/smooth_sheets/pull/416)) - [4004500](https://github.com/fujidaiti/smooth_sheets/commit/40045009b2da1081106a0970fea1330e47a8906d)


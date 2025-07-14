# v0.14.0 Release Note

## 🎉 New Features

### Cupertino Modal Sheet Overlay Effect

*Reported in [#25](https://github.com/fujidaiti/smooth_sheets/issues/25), fixed in [#403](https://github.com/fujidaiti/smooth_sheets/pull/403)*

We've added support for toning overlay effects on Cupertino-style modal sheets when stacking them, matching native iOS behavior. The new `overlayColor` parameter in `CupertinoModalSheetPage` and `CupertinoModalSheetRoute` allows applying a subtle overlay to background sheets when another sheet is presented, creating a more authentic iOS experience and improving visual hierarchy, especially in dark mode.

**Usage:**

```dart
CupertinoModalSheetPage(
  overlayColor: const Color(0x33ffffff), // A translucent white color
  child: MySheetContent(),
)
```

| `overlayColor: null` | `overlayColor: Color(0x33ffffff)` |
|------|------|
| <video src="https://github.com/user-attachments/assets/7a69537c-36e9-40c9-ba81-97c016e4a64d"/> | <video src="https://github.com/user-attachments/assets/e39a8b44-6b51-4c66-8187-ed155e211840"/> |

### Pull-to-Refresh Support in Sheets

*Reported in [#264](https://github.com/fujidaiti/smooth_sheets/issues/264), fixed in [#402](https://github.com/fujidaiti/smooth_sheets/pull/402)*

We've added support for pull-to-refresh functionality and overscroll effects within sheets through the new `delegateUnhandledOverscrollToChild` flag in `SheetScrollConfiguration`. When enabled, this flag allows overscroll deltas that aren't handled by the sheet's physics to be passed to child scrollable widgets, enabling `RefreshIndicator` and `BouncingScrollPhysics` effects to work seamlessly within sheet content.

This feature maintains backward compatibility and requires explicit opt-in, ensuring no impact on existing code.

<video src="https://github.com/user-attachments/assets/2aaa6bbd-4c38-45c9-96b1-7e126fba2214" width="300" controls></video>

## 🐛 Bug Fixes

### Fixed Sheet Position During Window Resize

*Reported in [#399](https://github.com/fujidaiti/smooth_sheets/issues/399), fixed in [#400](https://github.com/fujidaiti/smooth_sheets/pull/400)*

Fixed an issue where sheets would not maintain their proper position when the app window was resized, particularly when dragging the bottom border to expand the window downward. Previously, sheets would appear to "float" rather than staying correctly positioned relative to the window boundaries.

This issue was especially noticeable on desktop platforms and also occurred on Android when running in Picture-in-Picture mode with keyboard interactions. The fix ensures that sheets now properly track window size changes and maintain their relative position, providing a more consistent user experience across different window configurations.

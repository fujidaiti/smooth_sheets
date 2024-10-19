# Changelog

## 0.10.2 Oct 19, 2024

- Replace Platform (dart:io) with TargetPlatform to support web platform (#269)

## 0.10.1 Oct 9, 2024

- Fix: Modal sheet jerks when swipe to dismiss (#258)

## 0.10.0 Sep 28, 2024

**This version contains breaking changes.** See the [migration guide](https://github.com/fujidaiti/smooth_sheets/blob/main/migrations/migration-guide-0.10.x.md) for more details.

- Fix: Touch is ignored issue not fixed for top edge (#212)
- Fix: Closing keyboard slows down snapping animation (#193)
- Fix: Dynamically changing sheet height doesn't respect snapping constraints (#226)
- Fix: Snapping effect doesn't work when closing keyboard on non-fullscreen sheet (#192)
- Fix: Unwanted bouncing when opening or closing the on-screen keyboard on ScrollableSheet (#245)

## 0.9.4 Aug 31, 2024

- Add `SwipeDismissSensitivity`, a way to customize sensitivity of swipe-to-dismiss action on modal sheet (#222)

## 0.9.3 Aug 19, 2024

- Fix: Press-and-hold gesture in PageView doesn't stop momentum scrolling (#219)

## 0.9.2 Aug 14, 2024

- Fix: Keyboard visibility changes disrupt route transition animation in NavigationSheet (#215)

## 0.9.1 Jul 30, 2024

- Fix: Sometimes touch is ignored when scrollable sheet reaches edge (#209)

## 0.9.0 Jul 24, 2024

This version contains some breaking changes. See the [migration guide](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/migration-guide-0.9.x.md) for more details.

- Dispatch a notification when drag is cancelled (#204)
- Prefer composition style for SheetKeyboardDismissible (#197)
- Fix: NavigationSheet throws assertion error when starting to scroll in list view during page transition (#199)
- Refactor notification dispatch mechanism (#202)
- Fix: Momentum scrolling continues despite press and hold in list view (#196)
- Refactor: Lift sheet context up (#201)

## 0.8.2 Jul 11, 2024

- Fix: Opening keyboard interrupts sheet animation (#189)

## 0.8.1 Jun 23, 2024

- Fix: Cupertino style modal transition not working with NavigationSheet (#182)

## 0.8.0 Jun 22, 2024

This version contains some breaking changes. See the [migration guide](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/migration-guide-0.8.x.md) for more details.

- Make stretching behavior of StretchingSheetPhysics more customizable (#171)
- Rename "stretching" to "bouncing" (#173, #177)
- Fix: bouncing physics doesn't respect bounds where sheet can bounce (#178)

## 0.7.3 Jun 9, 2024

- Fix: DropdownButton doesn't work in NavigationSheet (#139)

## 0.7.2 Jun 9, 2024

- Fix: Attaching SheetController to NavigationSheet causes "Null check operator used on a null value" (#151)
- Fix: SheetController attached to NavigationSheet always emits minPixels = 0.0 (#163)

## 0.7.1 Jun 1, 2024

- Fix: Unwanted bouncing effect when opening keyboard on NavigationSheet (#153)

## 0.7.0 May 30, 2024

This version contains some breaking changes. See the [migration guide](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/migration-guide-0.7.x.md) for more details.

- Fix: Unable to build with Flutter versions `< 3.22.0` (#141)
- Increase min SDK versions (#147)
- Remove basePhysics from SheetThemeData (#148)

## 0.6.0 May 26, 2024

This version contains some breaking changes. See the [migration guide](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/migration-guide-0.6.x.md) for more details.

- SheetDismissible not working with NavigationSheet (#137)
- Add a way to handle dismissing modal sheet events in one place (#130)
- SheetDismissible never trigger pull-to-dismiss action if ListView's scroll offset is halfway (#84)
- SheetDismissible not working with infinite looping scroll widget (#80)
- Can't overdrag modal sheet during pull-to-dismiss action (#53)
- Sometimes Pull-to-dismiss action is not triggered on modal sheet (#52)

## 0.5.3 May 6, 2024

- Fix an assertion error when specific page transition scenarios in declarative 'NavigationSheet' (#94)

## 0.5.2 May 5, 2024

- Fix a crash during the first build of `NavigationSheet` with a path that contains multiple routes such as `/a/b/c` (#109)

## 0.5.1 May 4, 2024

- Re-export `NavigationSheetRoute` that is unintentionally omitted in v0.5.0 (#110)

## 0.5.0 May 4, 2024

This version contains some breaking changes. See the [migration guide](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/migration-guide-0.5.x.md) for more details.

- Attach default controller to sheet if not explicitly specified (#102)
- Reimplement core architecture (#106)

## 0.4.2 Apr 21, 2024

- Add new SheetNotifications for drag events (#92)
- Add SheetTheme (#93)
- Add a way to specify default physics and default ancestor physics (#96)

## 0.4.1 Mar 20, 2024

- Fix mistakes in the documentation of `BottomBarVisibility` and `ConditionalStickyBottomBarVisibility` which may mislead readers.

## 0.4.0 Mar 20, 2024

- Add `BottomBarVisibility` widgets (#15, #19)

## 0.3.4 Mar 9, 2024

- Fix crash when clicking on the modal barrier while dragging the sheet (#54)

## 0.3.3 Feb 29, 2024

- Add `InterpolationSimulation` (#55)

## 0.3.2 Feb 27, 2024

- Documentation updates

## 0.3.1 Feb 26, 2024

- Documentation updates

## 0.3.0 Feb 24, 2024

- Add iOS 15 style modal sheet transition (#21)
- Improve the sheet motion while opening/closing the keyboard (#27)
- Add `settings` and `fullscreenDialog` params to the constructors of modal sheet routes and pages (#28)
- Physics improvements (#32)
- Add conditional modal sheet popping feature (#39)
- Remove `enablePullToDismiss` (#44)

## 0.2.0 Jan 29, 2024

- Add a showcase that uses TextFields in a sheet (#2)
- Dispatch a Notification when the sheet extent changes (#4)
- Add a way to dismiss the on-screen keyboard when the sheet is dragged (#8)

## 0.1.0

- Initial release

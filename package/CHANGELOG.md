# Changelog

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

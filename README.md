# smooth_sheets

[![GitHub Repo stars](https://img.shields.io/github/stars/fujidaiti/smooth_sheets)](https://github.com/fujidaiti/smooth_sheets) [![GitHub last commit (branch)](https://img.shields.io/github/last-commit/fujidaiti/smooth_sheets/main?logo=git)](https://github.com/fujidaiti/smooth_sheets/commits/main/) [![Pub Version](https://img.shields.io/pub/v/smooth_sheets)](https://pub.dev/packages/smooth_sheets) ![Pub Likes](https://img.shields.io/pub/likes/smooth_sheets) ![Pub Points](https://img.shields.io/pub/points/smooth_sheets) 

**smooth_sheets** offers modal and persistent sheet widgets for Flutter apps. The key features are:

- **Smooth motion**: The sheets respond to user interaction with smooth, graceful motion.
- **Highly flexible**: Not restricted to a specific design. Both modal and persistent styles are supported, as well as scrollable and non-scrollable widgets.
- **Supports nested navigation**: A sheet is able to have multiple pages and to navigate between the pages with motion animation for transitions.
- **Works with imperative & declarative Navigator API**: No special navigation mechanism is required. The traditional ways such as `Navigator.push` is supported and it works with Navigator 2.0 packages like go_route as well.
- **iOS flavor**: The modal sheets in the style of iOS 15 are supported.

<br/>

## Migration guide

- [0.10.x to 0.11.x](https://github.com/fujidaiti/smooth_sheets/blob/main/migrations/migration-guide-0.11.x.md) 🆕
- [0.9.x to 0.10.x](https://github.com/fujidaiti/smooth_sheets/blob/main/migrations/migration-guide-0.10.x.md)

See [here](https://github.com/fujidaiti/smooth_sheets/tree/main/migrations) for older versions.

<br/>

## Showcases

<table>
  <tr>
    <td width="30%"><img src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/636d5ca8-2883-4447-ad75-47fcb210718c"/></td>
    <td>
      <h3>AI Playlist Generator</h3>
      <p>An AI assistant that helps create a music playlist based on the user's preferences. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/showcase/ai_playlist_generator.dart">the cookbook</a> for more details.</p>
      <p>Key components:</p>
      <ul>
        <li>PagedSheet</li>
        <li>ModalSheetPage</li>
        <li>PagedSheetPage</li>
        <li>SheetDismissible</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="30%"><img src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/cfbc79d1-4290-4dec-88bd-a355a27726ea"/></td>
    <td>
      <h3>Safari app</h3>
      <p>A practical example of ios-style modal sheets. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/showcase/safari">the cookbook</a> for more details.</p>
      <p>Key components:</p>
      <ul>
        <li>CupertinoStackedTransition</li>
        <li>CupertinoModalSheetRoute</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="30%"><img src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/1fb3f047-c993-42be-9a7e-b3efc89be635"/></td>
    <td>
      <h3>Airbnb mobile app clone</h3>
      <p>A partial clone of the Airbnb mobile app. The user can drag the house list down to reveal the map behind it. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/showcase/airbnb_mobile_app.dart">the cookbook</a> for more details.</p>
      <p>Key components:</p>
      <ul>
        <li>Sheet</li>
        <li>SheetViewport</li>
        <li>SheetPhysics</li>
        <li>SheetSnapGrid</li>
        <li>SheetController</li>
        <li>SheetOffsetDrivenAnimation</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="30%"><img src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/b1e0f8d0-7037-48c5-ab4e-80a2c43df43b"/></td>
    <td>
      <h3>Todo List</h3>
      <p>A simple Todo app that shows how a sheet handles the on-screen keyboard. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/showcase/todo_list">the cookbook</a> for more details.</p>
      <p>Used components:</p>
      <ul>
        <li>Sheet</li>
        <li>SheetContentScaffold</li>
        <li>SheetKeyboardDismissBehavior</li>
        <li>SheetDismissible</li>
        <li>BottomBarVisibility</li>
      </ul>
    </td>
  </tr>
</table>

<br/>

## Why use this?

There are few packages on pub.dev that supports nested navigation with motion animation for page transitions. One of the great choices for this usecase is [wolt_modal_sheet](https://github.com/woltapp/wolt_modal_sheet), which this package is inspired by. Although smooth_sheet has similar features with wolt_modal_sheet, it does not intended to be a replacement of that package. Here is some differences between those 2 packages:

|                        |                                                             wolt_modal_sheet                                                              |                             smooth_sheets                              |
|:----------------------:|:-----------------------------------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------:|
|         Design         | Based on Wolt's [design guideline](https://careers.wolt.com/en/blog/tech/an-overview-of-the-multi-page-scrollable-bottom-sheet-ui-design) |        Not restricted to a specific design, fully customizable         |
|  Navigation mechanism  |                        [Manage the page index in ValueNotifier](https://github.com/woltapp/wolt_modal_sheet#usage)                        | Works with built-in Navigator API (both of imperative and declarative) |
|   Scrollable content   |                                [Supported](https://github.com/woltapp/wolt_modal_sheet#scrollable-content)                                |                               Supported                                |
|   Persistent sheets    |                                                               Not supported                                                               |                               Supported                                |
| Screen size adaptation |              [The sheet appears as a dialog on large screens](https://github.com/woltapp/wolt_modal_sheet#responsive-design)              |                             Not supported                              |

<br/>

## Usage

Several resources are available for learning the functionalities of this package.

- Tutorials: See [example/lib/tutorial/](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/tutorial) to learn the basic usage of the core components.
- Showcases: More practical examples are available in [example/lib/showcase/](https://github.com/fujidaiti/smooth_sheets/tree/main/example/lib/showcase).
- Documentation: WORK IN PROGRESS!

<br/>

## Ingredients

This section provides descriptions for each core component and links to related resources for further learning.

<br/>

### SheetOffset

`SheetOffset` represents the visible height (or offset) of the sheet relative to the `SheetViewport`. It's used in various situations, such as specifying the initial visible area of a sheet or defining snap points in a `SheetSnapGrid`. It replaces the older `SheetAnchor` concept.

<br/>

### Sheet

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/51c483a0-5d1d-49d1-bff1-0051d1d3d937"/> <!-- Non-scrollable -->
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/28cf4760-de78-425b-a64e-c2ac6fb6817c"/> <!-- Scrollable -->
</div>

The primary widget for building sheets. It can be dragged and sized based on its content or stretched to fill available space, configured via `SheetDecoration`.
- **Non-scrollable content:** By default, `Sheet` works with non-scrollable content. The sheet's height typically matches the content unless constrained.
- **Scrollable content:** To integrate with scrollable widgets (like `ListView`, `GridView`), provide a `SheetScrollConfiguration` to the `scrollConfiguration` property. The sheet will then drag when the content is over-scrolled or under-scrolled.

The sheet's physics (how it behaves when over/under dragged) are controlled by `SheetPhysics`, and snapping behavior is defined by `SheetSnapGrid`. Styling (like background, shape, borders) is handled by `SheetDecoration`.

For non-modal sheets, `Sheet` must be placed inside a `SheetViewport`.

See also:
- [basic_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/basic_sheet.dart) for basic usage.
- [scrollable_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/scrollable_sheet.dart) for usage with scrollable content.
- [decorations.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/decorations.dart) for styling examples.

<br/>

### PagedSheet

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/3367d3bc-a895-42be-8154-2f6fc83b30b5"/>
</div>

`PagedSheet` manages a stack of pages within a single sheet, enabling navigation between them with transitions. It works seamlessly with Flutter's Navigator API (both imperative and declarative, e.g., go_router). Each page is defined using `PagedSheetPage`, which can have its own specific configuration like `initialOffset`, `snapGrid`, or `scrollConfiguration`. Transitions between pages default to the application's theme but can be customized per-page.

See also:
- [declarative_paged_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/declarative_paged_sheet.dart), tutorial using go_router.
- [imperative_paged_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/imperative_paged_sheet.dart), tutorial using imperative Navigator API.

<br/>

### ModalSheets

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/f2212362-e193-4dab-8f8b-f24942051775"/>
</div>

A sheet can be displayed as a modal sheet using ModalSheetRoute for imperative navigation, or ModalSheetPage for declarative navigation. To enable the *swipe-to-dismiss* action, which allows the user to dismiss the sheet by a swiping-down gesture, set `swipeDismissible` to true.

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/242a8d32-a355-4d4a-8248-4572a03c64eb"/>
</div>

Furthermore, [the modal sheets in the style of iOS 15](https://medium.com/surf-dev/bottomsheet-in-ios-15-uisheetpresentationcontroller-and-its-capabilities-5e913661c9f) are also supported. For imperative navigation, use CupertinoModalSheetRoute, and for declarative navigation, use CupertinoModalSheetPage, respectively.

See also:

- [SwipeDismissSensitivity](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SwipeDismissSensitivity-class.html), which can be used to tweak the sensitivity of the swipe-to-dismiss action.
- [declarative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/declarative_modal_sheet.dart), a tutorial of integration with declarative navigation using [go_router](https://pub.dev/packages/go_router) package.
- [imperative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/imperative_modal_sheet.dart), a tutorial of integration with imperative Navigator API.
- [cupertino_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/cupertino_modal_sheet.dart),  a tutorial of iOS style modal sheets.
- [ios_style_declarative_modal_paged_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/ios_style_declarative_modal_paged_sheet.dart), an example of iOS-style modal PagedSheet with go_router.
- [showcase/todo_list](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/showcase/todo_list), which uses SheetDismissible to show a confirmation dialog when the user tries to discard the todo editing sheet without saving the content.

<br/>

### SheetPhysics

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/e08e3f58-cc98-4858-8b76-6e84a7e9e416"/>
</div>


A physics determines how the sheet will behave when over-dragged or under-dragged, or when the user stops dragging. This is independent of snapping behavior, which is configured via [SheetSnapGrid](#sheetsnapgrid). There are 2 predefined physics:

- ClampingSheetPhysics: Prevents the sheet from reaching beyond the draggable bounds.
- BouncingSheetPhysics: Allows the sheet to go beyond the draggable bounds, but then bounce the sheet back to the edge of those bounds.

These physics can be combined to create more complex behavior.

See also:

- [physics_and_snap_grid.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/physics_and_snap_grid.dart) for basic usage.
- [BouncingBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BouncingBehavior-class.html), which can be used to tweak the bouncing behavior of BouncingSheetPhysics.

<br/>

### SheetSnapGrid

This determines how the sheet snaps to certain offsets when the user stops dragging or when an animation completes. It is configured separately from `SheetPhysics`. Offsets are defined using `SheetOffset`.

There are several predefined snap grid types:

- `SingleSnapGrid`: Snaps to a single offset.
- `MultiSnapGrid`: Snaps to the nearest offset from a predefined list.
- `SteplessSnapGrid`: Allows snapping anywhere above a minimum offset, effectively creating a continuous drag area above that minimum.

See also:

- [physics_and_snap_grid.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/physics_and_snap_grid.dart) for basic usage.

<br/>

### SheetController

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/40f3fba5-9fec-40e8-a5cf-8f0312b57288"/>
</div>


Like [ScrollController](https://api.flutter.dev/flutter/widgets/ScrollController-class.html) for scrollable widget, the SheetController can be used to animate or observe the offset (position) of a sheet.

See also:

- [sheet_controller.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/sheet_controller.dart) for basic usage.

<br/>

### SheetContentScaffold

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/52a0de82-b85c-4b2f-b10a-eb882b849900"/>
</div>


A special kind of [Scaffold](https://api.flutter.dev/flutter/material/Scaffold-class.html) designed for use within a sheet's content. It provides slots for a `topBar` (like `AppBar`) and a `bottomBar` (like `BottomNavigationBar`). It sizes itself to fit the `body` content. Use `extendBodyBehindTopBar` and `extendBodyBehindBottomBar` to allow the body to extend behind these bars. The visibility of the `bottomBar` can be controlled based on the sheet's offset using the `bottomBarVisibility` property with `BottomBarVisibility` options (e.g., `BottomBarVisibility.always()`, `BottomBarVisibility.conditional(...)`).

See also:

- [SheetContentScaffold](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetContentScaffold-class.html), the API documentation.
- [BottomBarVisibility](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BottomBarVisibility-class.html), which controls the visibility of the bottom bar based on sheet metrics (including offset).
- [tutorial/sheet_content_scaffold.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/sheet_content_scaffold.dart), which shows the basic usage of SheetContentScaffold.
- [tutorial/bottom_bar_visibility.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/bottom_bar_visibility.dart), which shows the basic usage of the `bottomBarVisibility` property.

<br/>

### SheetOffsetDrivenAnimation

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/8b9ed0ef-675e-4468-8a3f-cd3f1ed3dfb0"/>
</div>

Formerly `SheetPositionDrivenAnimation`, this allows creating animations driven by the sheet's offset. It's a special kind of [Animation](https://api.flutter.dev/flutter/animation/Animation-class.html) whose value changes (typically from 0 to 1) as the sheet's offset moves between specified `startOffset` and `endOffset` values (defined using `SheetOffset`). This is useful for synchronizing UI changes (like fades, slides, or color changes) with the sheet's movement.

See also:
- [sheet_offset_driven_animation.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/sheet_offset_driven_animation.dart) for basic usage.
- [airbnb_mobile_app.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/showcase/airbnb_mobile_app.dart), which shows how `SheetOffsetDrivenAnimation` can be used to hide/show UI elements based on the sheet's drag position.

<br/>

### SheetNotification

A sheet dispatches a [SheetNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetNotification-class.html) when its offset changes. This can be used to observe the offset and other metrics (like min/max offset, viewport size) of a descendant sheet from an ancestor widget using a `NotificationListener`.

```dart
NotificationListener<SheetNotification>(
  onNotification: (notification) {
    // Access sheet metrics via notification.metrics (e.g., offset, minOffset, maxOffset)
    debugPrint('Current offset: ${notification.metrics.offset}');
    return false; // Return true to stop the notification from bubbling up
  },
  child: SheetViewport( // Required for non-modal sheets
    child: Sheet(
      // ... sheet configuration
    ),
  ),
),
```

See also:

- [SheetDragUpdateNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetDragUpdateNotification-class.html), which is dispatched when the sheet is dragged by the user.
- [SheetUpdateNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetUpdateNotification-class.html), which is dispatched when the sheet offset is updated by other means (e.g., animation, controller).
- [SheetOverflowNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetOverflowNotification-class.html), which is dispatched when the user tries to drag the sheet beyond its draggable bounds but the sheet has not changed its offset because its [SheetPhysics](#sheetphysics) does not allow it to be.
- [NotificationListener](https://api.flutter.dev/flutter/widgets/NotificationListener-class.html), which can be used to listen for the notifications in a subtree.

<br/>

### SheetKeyboardDismissBehavior

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/728d31d1-d2cd-4097-90cb-943d2d0d4d3d"/>
</div>
<br/>

[SheetKeyboardDismissBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetKeyboardDismissBehavior-class.html) determines when the sheet should dismiss the on-screen keyboard when dragged. This feature is similar to [ScrollViewKeyboardDismissBehavior](https://api.flutter.dev/flutter/widgets/ScrollViewKeyboardDismissBehavior.html) for scrollable widgets. This behavior is configured via the `Sheet.keyboardDismissBehavior` property.

Although it is easy to create custom behaviors by implementing the `SheetKeyboardDismissBehavior` interface, there are predefined behaviors available as static constants for convenience:

- `SheetKeyboardDismissBehavior.onDrag` (formerly `DragSheetKeyboardDismissBehavior`)
- `SheetKeyboardDismissBehavior.onDragDown` (formerly `DragDownSheetKeyboardDismissBehavior`)
- `SheetKeyboardDismissBehavior.onDragUp` (formerly `DragUpSheetKeyboardDismissBehavior`)
- `SheetKeyboardDismissBehavior.never`

See also:

- [tutorial/keyboard_dismiss_behavior.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/keyboard_dismiss_behavior.dart) for basic usage.

<br/>

### SheetViewport

This widget defines the area within which a `Sheet` exists and moves. It's required as an ancestor for non-modal sheets (`Sheet`, `PagedSheet`). You can use its `padding` property to create space around the sheet, preventing it from overlapping with status bars or other UI elements. Modal sheets (like those created with `ModalSheetRoute`) create their own viewport internally, but offer a `viewportPadding` property for similar control.

See also:
- [basic_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/basic_sheet.dart) for basic usage.

<br/>

## Questions

If you have any questions, feel free to ask them on [the discussions page](https://github.com/fujidaiti/smooth_sheets/discussions).

<br/>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement". Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<br/>

## Links

- [Roadmap](https://github.com/fujidaiti/smooth_sheets/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22)
- [API Documentation](https://pub.dev/documentation/smooth_sheets/latest/)
- [pub.dev](https://pub.dev/packages/smooth_sheets)
- [norelease.dev](https://pub.dev/publishers/norelease.dev/packages)

<br/>

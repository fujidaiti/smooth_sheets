# smooth_sheets

[![GitHub Repo stars](https://img.shields.io/github/stars/fujidaiti/smooth_sheets)](https://github.com/fujidaiti/smooth_sheets) [![GitHub last commit (branch)](https://img.shields.io/github/last-commit/fujidaiti/smooth_sheets/main?logo=git)](https://github.com/fujidaiti/smooth_sheets/commits/main/) [![Pub Version](https://img.shields.io/pub/v/smooth_sheets)](https://pub.dev/packages/smooth_sheets) ![Pub Likes](https://img.shields.io/pub/likes/smooth_sheets) ![Pub Points](https://img.shields.io/pub/points/smooth_sheets) ![Pub Popularity](https://img.shields.io/pub/popularity/smooth_sheets)


**smooth_sheets** offers modal and persistent sheet widgets for Flutter apps. The key features are:

- **Smooth motion**: The sheets respond to user interaction with smooth, graceful motion.
- **Highly flexible**: Not restricted to a specific design. Both modal and persistent styles are supp/orted, as well as scrollable and non-scrollable widgets.
- **Supports nested navigation**: A sheet is able to have multiple pages and to navigate between the pages with motion animation for transitions.
- **Works with imperative & declarative Navigator API**: No special navigation mechanism is required. The traditional ways such as `Navigator.push` is supported and it works with Navigator 2.0 packages like go_route as well.
- **iOS flavor**: The modal sheets in the style of iOS 15 are supported.

<br/>

**CAUTION🚨**

This library is currently in the experimental stage. The API may undergo changes without prior notice. For documentation of the latest published version, please visit the [package site](https://pub.dev/packages/smooth_sheets) on pub.dev.

<br/>

## Migration guide

- [0.6.x to 0.7.x](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/migration-guide-0.6.x.md) 🆕
- [0.5.x to 0.6.x](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/migration-guide-0.6.x.md)

See [here](https://github.com/fujidaiti/smooth_sheets/blob/main/docs/) for older versions.

<br/>

## Showcases

<table>
  <tr>
    <td width="30%"><img src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/636d5ca8-2883-4447-ad75-47fcb210718c"/></td>
    <td>
      <h3>AI Playlist Generator</h3>
      <p>An AI assistant that helps create a music playlist based on the user's preferences. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/ai_playlist_generator.dart">the cookbook</a> for more details.</p>
      <p>Key components:</p>
      <ul>
        <li>NavigationSheet</li>
        <li>ModalSheetPage</li>
        <li>DraggableNavigationSheetPage</li>
        <li>ScrollableNavigationSheetPage</li>
        <li>SheetDismissible</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="30%"><img src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/cfbc79d1-4290-4dec-88bd-a355a27726ea"/></td>
    <td>
      <h3>Safari app</h3>
      <p>A practical example of ios-style modal sheets. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/safari">the cookbook</a> for more details.</p>
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
      <p>A partial clone of the Airbnb mobile app. The user can drag the house list down to reveal the map behind it. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/airbnb_mobile_app.dart">the cookbook</a> for more details.</p>
      <p>Key components:</p>
      <ul>
        <li>ScrollableSheet</li>
        <li>SheetPhysics</li>
        <li>SheetController</li>
        <li>ExtentDrivenAnimation</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="30%"><img src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/b1e0f8d0-7037-48c5-ab4e-80a2c43df43b"/></td>
    <td>
      <h3>Todo List</h3>
      <p>A simple Todo app that shows how a sheet handles the on-screen keyboard. See <a href="https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/todo_list">the cookbook</a> for more details.</p>
      <p>Used components:</p>
      <ul>
        <li>ScrollableSheet</li>
        <li>SheetContentScaffold</li>
        <li>SheetKeyboardDismissBehavior</li>
        <li>SheetDismissible</li>
        <li>StickyBottomBarVisibility</li>
      </ul>
    </td>
  </tr>
</table>




<br/>

## Why use this?

There are few packages on pub.dev that supports nested navigation with motion animation for page transitions. One of the great choices for this usecase is [wolt_modal_sheet](https://github.com/woltapp/wolt_modal_sheet), which this package is inspired by. Although smooth_sheet has similar features with wolt_modal_sheet, it does not intended to be a replacement of that package. Here is some differences between those 2 packages:

|                        |                       wolt_modal_sheet                       |                        smooth_sheets                         |
| :--------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|         Design         | Based on Wolt's [design guideline](https://careers.wolt.com/en/blog/tech/an-overview-of-the-multi-page-scrollable-bottom-sheet-ui-design) |   Not restricted to a specific design, fully customizable    |
|  Navigation mechanism  | [Manage the page index in ValueNotifier](https://github.com/woltapp/wolt_modal_sheet#usage) | Works with built-in Navigator API (both of imperative and declarative) |
|   Scrollable content   | [Supported](https://github.com/woltapp/wolt_modal_sheet#scrollable-content) |                          Supported                           |
|   Persistent sheets    |                        Not supported                         |                          Supported                           |
| Screen size adaptation | [The sheet appears as a dialog on large screens](https://github.com/woltapp/wolt_modal_sheet#responsive-design) |                        Not supported                         |

<br/>

## Usage

Several resources are available for learning the functionalities of this package.

- Tutorials: See [cookbook/lib/tutorial/](https://github.com/fujidaiti/smooth_sheets/tree/main/cookbook/lib/tutorial) to learn the basic usage of the core components.
- Showcases: More practical examples are available in [cookbook/lib/showcase/](https://github.com/fujidaiti/smooth_sheets/tree/main/cookbook/lib/showcase).
- Documentation: WORK IN PROGRESS! Please see the source code for a while.

<br/>

## Ingredients

This section provides descriptions for each core component and links to related resources for further learning.

<br/>

### Extent

Extent represents the visible height of the sheet. It is used in a variety of situations, for example, to specify how much area of a sheet is initially visible at first build, or to limit the range of sheet dragging.

<br/>

### DraggableSheet

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/51c483a0-5d1d-49d1-bff1-0051d1d3d937"/>
</div>


A sheet that can be dragged. The height will be equal to the content. The behavior of the sheet when over-dragged or under-dragged is determined by [SheetPhysics](#sheetphysics). Note that this widget does not work with scrollable widgets. Instead, use [ScrollableSheet](#scrollablesheet) for this usecase.



See also:

- [draggable_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/draggable_sheet.dart) for basic usage.

<br/>

### ScrollableSheet

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/28cf4760-de78-425b-a64e-c2ac6fb6817c"/>
</div>


A sheet that is similar to [DraggableSheet](#draggablesheet), but specifically designed to be integrated with scrollable widgets. It will begin to be dragged when the content is over-scrolled or under-scrolled.



See also:

- [scrollable_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/scrollable_sheet.dart) for basic usage.

<br/>

### NavigationSheet

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/3367d3bc-a895-42be-8154-2f6fc83b30b5"/>
</div>


A sheet that is able to have multiple pages and performs graceful motion animation when page transitions. It supports both of imperative Navigator API such as `Navigator.push`, and declarative API (Navigator 2.0). 



See also:

- [declarative_navigation_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/declarative_navigation_sheet.dart), tutorial of integration with Navigator 2.0 using [go_router](https://pub.dev/packages/go_router) package.
- [imperative_navigation_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/imperative_navigation_sheet.dart), a tutorial of integration with imperative Navigator API.

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

- [declarative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/declarative_modal_sheet.dart), a tutorial of integration with declarative navigation using [go_router](https://pub.dev/packages/go_router) package.
- [imperative_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/imperative_modal_sheet.dart), a tutorial of integration with imperative Navigator API.
- [cupertino_modal_sheet.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/cupertino_modal_sheet.dart), a tutorial of iOS style modal sheets.
- [showcase/todo_list](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/todo_list), which uses SheetDismissible to show a confirmation dialog when the user tries to discard the todo editing sheet without saving the content.

<br/>

### SheetPhysics

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/e08e3f58-cc98-4858-8b76-6e84a7e9e416"/>
</div>


A physics determines how the sheet will behave when over-dragged or under-dragged, or when the user stops dragging. There are 3 predefined physics:

- ClampingSheetPhysics: Prevents the sheet from reaching beyond the draggable bounds
- StretchingSheetPhysics: Allows the sheet to go beyond the draggable bounds, but then bounce the sheet back to the edge of those bounds
- SnappingSheetPhysics: Automatically snaps the sheet to a certain extent when the user stops dragging

These physics can be combined to create more complex behavior (e.g. stretching behavior + snapping behavior).



See also:

- [sheet_physics.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_physics.dart) for basic usage.

<br/>

### SheetController

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/40f3fba5-9fec-40e8-a5cf-8f0312b57288"/>
</div>


Like [ScrollController](https://api.flutter.dev/flutter/widgets/ScrollController-class.html) for scrollable widget, the SheetController can be used to animate or observe the extent of a sheet.



See also:

- [sheet_controller.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_controller.dart) for basic usage.

<br/>

### SheetContentScaffold

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/52a0de82-b85c-4b2f-b10a-eb882b849900"/>
</div>


A special kind of [Scaffold](https://api.flutter.dev/flutter/material/Scaffold-class.html) designed for use in a sheet. It has slots for an app bar and a bottom bar, similar to Scaffold. However, it differs in that its height reduces to fit the content widget.



See also:

- [SheetContentScaffold](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetContentScaffold-class.html), the API documentation.
- [BottomBarVisibility](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BottomBarVisibility-class.html), which can be used to control the visibility of the bottom bar based on the sheet position.
- [tutorial/sheet_content_scaffold.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_content_scaffold.dart), which shows the basic usage of SheetContentScaffold.
- [tutorial/bottom_bar_visibility.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/bottom_bar_visibility.dart), which shows the basic usage of BottomBarVisibility widgets.

<br/>

### SheetDraggable

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/aacc7b27-3d6f-4314-8672-d6f99fafabed"/>
</div>

SheetDraggable enables its child widget to act as a drag handle for the sheet. Typically, you will want to use this widget when placing non-scrollable widget(s) in a [ScrollableSheet](#scrollablesheet), since it only works with scrollable widgets, so you can't drag the sheet by touching a non-scrollable area. Try removing SheetDraggable and you will see that the drag handle doesn't work as it should.
Note that SheetDraggable is not needed when using DraggableSheet since it implicitly wraps the child widget with SheetDraggable.



See also:

- [sheet_draggable.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/sheet_draggable.dart) for basic usage.

<br/>

### ExtentDrivenAnimation

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/8b9ed0ef-675e-4468-8a3f-cd3f1ed3dfb0"/>
</div>

It is easy to create sheet extent driven animations by using ExtentDrivenAnimation, a special kind of [Animation](https://api.flutter.dev/flutter/animation/Animation-class.html) whose value changes from 0 to 1 as the sheet extent changes from 'startExtent' to 'endExtent'.



See also:

- [extent_driven_animation](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/extent_driven_animation.dart) for basic usage.
- [airbnb_mobile_app.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/showcase/airbnb_mobile_app.dart), which show how ExtentDrivenAnimation can be used to hide the bottom navigation bar and a FAB when the sheet is dragged down, and to show them when the sheet is dragged up again.

<br/>

### SheetNotification

A sheet dispatches a [SheetNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetNotification-class.html) when its extent changes. This can be used to observe the extent of a descendant sheet from an ancestor widget.

```dart
NotificationListener<SheetNotification>(
  onNotification: (notification) {
    debugPrint('${notification.metrics}');
    return false;
  },
  child: DraggableSheet(...),
),
```



See also:

- [SheetDragUpdateNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetDragUpdateNotification-class.html), which is dispatched when the sheet is dragged by the user.
- [SheetUpdateNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetUpdateNotification-class.html), which is dispatched when the sheet extent is updated by other than user interaction such as animation.
- [SheetOverflowNotification](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetOverflowNotification-class.html), which is dispatched when the user tries to drag the sheet beyond its draggable bounds but the sheet has not changed its extent because its [SheetPhysics](#sheetphysics) does not allow it to be.
- [NotificationListener](https://api.flutter.dev/flutter/widgets/NotificationListener-class.html), which can be used to listen for the notifications in a subtree.

<br/>

### SheetKeyboardDismissBehavior

<div align="center">
  <img width="160" src="https://github.com/fujidaiti/smooth_sheets/assets/68946713/728d31d1-d2cd-4097-90cb-943d2d0d4d3d"/>
</div>
<br/>

[SheetKeyboardDismissBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/SheetKeyboardDismissBehavior-class.html) determines when the sheet should dismiss the on-screen keyboard. This feature is similar to [ScrollViewKeyboardDismissBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/ScrollViewKeyboardDismissBehavior.html) for scrollable widgets. 

Although it is easy to create custom behaviors by implementing SheetKeyboardDismissBehavior interface, there are 3 types of predefined behaviors for convenience.

- [DragSheetKeyboardDismissBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/DragSheetKeyboardDismissBehavior-class.html), which always dismisses the on-screen keyboard when the sheet is dragged.
- [DragDownSheetKeyboardDismissBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/DragDownSheetKeyboardDismissBehavior-class.html), which always dismisses the on-screen keyboard only when the sheet is dragged down.
- [DragUpSheetKeyboardDismissBehavior](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/DragUpSheetKeyboardDismissBehavior-class.html), which always dismisses the on-screen keyboard only when the sheet is dragged up.



See also:

- [tutorial/keyboard_dismiss_behavior.dart](https://github.com/fujidaiti/smooth_sheets/blob/main/cookbook/lib/tutorial/keyboard_dismiss_behavior.dart) for basic usage.

<br/>

## Questions

If you have any questions, feel free to ask them on [the discussions page](https://github.com/fujidaiti/smooth_sheets/discussions).

<br/>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

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


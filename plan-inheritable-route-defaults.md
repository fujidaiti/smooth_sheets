# Make Per-Route Parameters Inheritable in PagedSheet

## Context

Currently, only `dragConfiguration` can be inherited from `PagedSheet` to its child routes. All other per-route parameters (`scrollConfiguration`, `initialOffset`, `snapGrid`, `transitionDuration`, `transitionsBuilder`) must be specified on each route individually, even when a common default would suffice. This leads to repetitive configuration when all routes share the same behavior.

## Goal

- Make `scrollConfiguration`, `dragConfiguration`, `initialOffset`, `snapGrid`, `transitionDuration`, and `transitionsBuilder` inheritable via a `PagedSheetRouteTheme` InheritedWidget.
- Add `SheetScrollConfiguration.disabled` sentinel so routes can explicitly opt out of scroll-sheet integration (freeing `null` to mean "inherit").
- `PagedSheetRouteTheme` is a standalone widget placed above `PagedSheet` — not a constructor parameter.
- **Keep** `PagedSheet.dragConfiguration` for the sheet itself (shared elements). It is completely independent from `PagedSheetRouteTheme.dragConfiguration` — they serve different purposes and do not cascade.
- `maintainState` and `builder`/`child` remain per-route only.
- Existing behavior must be preserved: when no `PagedSheetRouteTheme` ancestor exists and no overrides on routes, everything works as before.

## Approach

Introduce `PagedSheetRouteTheme` as a public `InheritedWidget` with `PagedSheetRouteTheme.of(context)` for lookup. It holds default values for route parameters. Routes make their inheritable parameters nullable — `null` means "inherit from theme."

Two independent drag configurations:
- `PagedSheet.dragConfiguration` — controls the sheet widget itself (shared elements via `builder`). Unchanged from today.
- `PagedSheetRouteTheme.dragConfiguration` — default for routes. Routes with `dragConfiguration: null` inherit from this, **not** from `PagedSheet.dragConfiguration`.

Usage:

```dart
PagedSheetRouteTheme(
  data: PagedSheetRouteThemeData.from(
    dragConfiguration: myRouteConfig,
    snapGrid: mySnapGrid,
  ),
  child: PagedSheet(
    dragConfiguration: mySheetConfig, // independent, for shared elements
    navigator: Navigator(...),
  ),
)
```

## Inheritable Parameter Assessment

| Parameter | Currently | Can Inherit? | Notes |
|---|---|---|---|
| `dragConfiguration` | Already nullable, already inheritable | Yes | Moves to `PagedSheetRouteTheme`; `PagedSheet.dragConfiguration` stays for the sheet itself |
| `scrollConfiguration` | Nullable, falls back to `const SheetScrollConfiguration()` | Yes | Add `.disabled` sentinel; `null` = inherit (see below) |
| `snapGrid` | Non-nullable, default `SheetSnapGrid.single(snap: SheetOffset(1))` | Yes | Make nullable on routes; resolve via theme |
| `initialOffset` | Non-nullable, default `SheetOffset(1)` | Yes | Make nullable on routes; resolve via theme |
| `transitionDuration` | Non-nullable, default `Duration(milliseconds: 300)` | Yes | `navigator` is set before `transitionDuration` is first read in `TransitionRoute.install()`, so InheritedWidget lookup is safe |
| `transitionsBuilder` | Already nullable | Yes | Defaults to `null` (platform default). Can't override inherited non-null builder back to `null`, but that's an unusual case we don't support. |
| `maintainState` | Non-nullable, default `true` | **No** | Per-route lifecycle concern, not a shared behavior |
| `builder`/`child` | Required | **No** | Unique per route |

### Nullability: distinguishing "no opinion" from "explicitly null"

For parameters that were **already nullable** on routes, `null` has existing semantics. We adopt the same pattern as `dragConfiguration` — provide a `.disabled` sentinel for explicit opt-out, freeing `null` to mean "inherit":

- **`dragConfiguration`**: Already uses this pattern. `null` = inherit from theme, `.disabled` = opt out.
- **`scrollConfiguration`**: Currently `null` means "no scroll-sheet integration" ([sheet.dart:162](lib/src/sheet.dart#L162)). We add `SheetScrollConfiguration.disabled` as an explicit opt-out sentinel. Then `null` on a route means "inherit from theme." `DraggableScrollableSheetContent` is updated to check for `.disabled` instead of `null` — this keeps the disabled concept consistent across the codebase.
- **`transitionsBuilder`**: Currently `null` means "use platform default." We include it in the theme (defaulting to `null`). A route with `transitionsBuilder: null` inherits from theme. If the theme has a non-null builder, a route cannot override it back to "platform default" via `null` — this is an unusual case we intentionally don't support.

**Summary**:

| Parameter | In theme? | Reason |
|---|---|---|
| `dragConfiguration` | **Yes** | `null` = inherit from theme; `.disabled` for explicit opt-out |
| `scrollConfiguration` | **Yes** | Add `.disabled` sentinel; `null` = inherit |
| `snapGrid` | **Yes** | Was non-nullable; making nullable with `null` = inherit is clean |
| `initialOffset` | **Yes** | Was non-nullable; same as above |
| `transitionDuration` | **Yes** | Was non-nullable; same as above |
| `transitionsBuilder` | **Yes** | Defaults to `null`; `null` = inherit (can't override non-null back to null) |

### Default Values and Fallback Resolution

#### `PagedSheetRouteTheme` defaults

| Parameter | Default value |
|---|---|
| `dragConfiguration` | `const SheetDragConfiguration()` (enabled, opaque hit testing) |
| `scrollConfiguration` | `SheetScrollConfiguration.disabled` (no scroll-sheet integration) |
| `initialOffset` | `const SheetOffset(1)` (fully expanded) |
| `snapGrid` | `const SheetSnapGrid.single(snap: SheetOffset(1))` |
| `transitionDuration` | `const Duration(milliseconds: 300)` |
| `transitionsBuilder` | `null` (platform default transition) |

#### `PagedSheet.dragConfiguration` default

| Parameter | Default value |
|---|---|
| `dragConfiguration` | `const SheetDragConfiguration()` (enabled, opaque hit testing) |

#### Route-level fallback chain

When a route parameter is `null`, it resolves through this chain:

| Route parameter | Fallback chain |
|---|---|
| `dragConfiguration` | route → `PagedSheetRouteTheme.dragConfiguration` → `const SheetDragConfiguration()` |
| `scrollConfiguration` | route → `PagedSheetRouteTheme.scrollConfiguration` → `SheetScrollConfiguration.disabled` |
| `initialOffset` | route → `PagedSheetRouteTheme.initialOffset` → `const SheetOffset(1)` |
| `snapGrid` | route → `PagedSheetRouteTheme.snapGrid` → `const SheetSnapGrid.single(snap: SheetOffset(1))` |
| `transitionDuration` | route → `PagedSheetRouteTheme.transitionDuration` → `const Duration(milliseconds: 300)` |
| `transitionsBuilder` | route → `PagedSheetRouteTheme.transitionsBuilder` → `null` (platform default) |

The final fallback values are identical to `PagedSheetRouteTheme`'s own defaults. Since `PagedSheetRouteTheme` is an `InheritedWidget` (requires `child`), we can't construct it as a plain fallback. Instead, extract the data into a companion class `PagedSheetRouteThemeData` and use `const PagedSheetRouteThemeData()` as the fallback:

```dart
class PagedSheetRouteThemeData {
  const PagedSheetRouteThemeData({
    this.scrollConfiguration = SheetScrollConfiguration.disabled,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset(1),
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset(1)),
    this.transitionsBuilder,
  });
  // ...fields...
}

class PagedSheetRouteTheme extends InheritedWidget {
  const PagedSheetRouteTheme({
    super.key,
    this.data = const PagedSheetRouteThemeData(),
    required super.child,
  });
  final PagedSheetRouteThemeData data;
  // ...of/maybeOf...
}
```

Resolution: `PagedSheetRouteTheme.of(context).dragConfiguration` — since `of()` returns `const PagedSheetRouteThemeData()` when no ancestor exists, this avoids duplicating default values in the resolution logic.

**`PagedSheet.dragConfiguration` is never in the route fallback chain.** It exclusively controls the sheet-level drag behavior (shared elements). When no route is active, `_RouteAwareSheetDraggableState` uses `PagedSheet.dragConfiguration`.

### `PagedSheet.dragConfiguration` vs `PagedSheetRouteTheme.dragConfiguration`

These are **completely independent**:

- `PagedSheet.dragConfiguration` — controls drag behavior for the sheet widget itself, including shared elements built by `PagedSheet.builder`. This is passed to `_RouteAwareSheetDraggable` as `defaultConfiguration`. **Stays on `PagedSheet`.**
- `PagedSheetRouteTheme.dragConfiguration` — default for routes that don't specify their own. Routes resolve `dragConfiguration` from theme, never from `PagedSheet.dragConfiguration`.
- `_RouteAwareSheetDraggableState` (line 443) currently falls back to `widget.defaultConfiguration` (from `PagedSheet`). This changes to: route's own config → theme's config → built-in default (`SheetDragConfiguration()`). The `widget.defaultConfiguration` from `PagedSheet` is only used when no route is active.

## Implementation Steps

### 1. Add `SheetScrollConfiguration.disabled` sentinel

Add a `disabled` static const to `SheetScrollConfiguration` (in [scrollable.dart](lib/src/scrollable.dart)), following the same pattern as `SheetDragConfiguration.disabled`. This allows routes to explicitly opt out of scroll-sheet integration while freeing `null` for "inherit."

Implementation: make `SheetScrollConfiguration` an abstract class with a factory constructor and a `static const disabled` (same pattern as `SheetDragConfiguration` in [draggable.dart](lib/src/draggable.dart)). Update `DraggableScrollableSheetContent` in [sheet.dart](lib/src/sheet.dart):
- Make `scrollConfiguration` non-nullable (type `SheetScrollConfiguration`)
- Check for `.disabled` instead of `null`: `widget.scrollConfiguration != SheetScrollConfiguration.disabled`
- Update `Sheet.build()` (line 115) to pass `scrollConfiguration ?? SheetScrollConfiguration.disabled` to `DraggableScrollableSheetContent`
- Update `_DraggableScrollableSheetModelConfig` similarly (line 108-109)

### 2. Create `PagedSheetRouteThemeData` and `PagedSheetRouteTheme`

`PagedSheetRouteThemeData` holds the route default values. `PagedSheetRouteTheme` is the `InheritedWidget` wrapper.

```dart
class PagedSheetRouteThemeData {
  const PagedSheetRouteThemeData.from({
    this.scrollConfiguration = SheetScrollConfiguration.disabled,
    this.dragConfiguration = const SheetDragConfiguration(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.initialOffset = const SheetOffset(1),
    this.snapGrid = const SheetSnapGrid.single(snap: SheetOffset(1)),
    this.transitionsBuilder,
  });

  static const _default = PagedSheetRouteThemeData.from();

  final SheetScrollConfiguration scrollConfiguration;
  final SheetDragConfiguration dragConfiguration;
  final Duration transitionDuration;
  final SheetOffset initialOffset;
  final SheetSnapGrid snapGrid;
  final RouteTransitionsBuilder? transitionsBuilder;
}

class PagedSheetRouteTheme extends InheritedWidget {
  const PagedSheetRouteTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final PagedSheetRouteThemeData data;

  static PagedSheetRouteThemeData of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<PagedSheetRouteTheme>()
            ?.data ??
        PagedSheetRouteThemeData._default;
  }

  @override
  bool updateShouldNotify(PagedSheetRouteTheme oldWidget) {
    return data != oldWidget.data;
  }
}
```

Usage: `PagedSheetRouteTheme.of(context).dragConfiguration` — always returns a resolved value, never null. No need for `maybeOf` since `PagedSheetRouteThemeData._default` is the built-in fallback.

### 3. Update `PagedSheet`

- **Keep** `dragConfiguration` parameter — it controls the sheet itself (shared elements).
- Update doc comment for `dragConfiguration` (currently lines 337-352): clarify it now only controls the sheet-level drag behavior (shared elements), not route defaults. Route-level drag defaults are set via `PagedSheetRouteTheme`. Remove the part about routes falling back to this value.
- In `build()`, look up `PagedSheetRouteTheme.of(context)` to get the theme.
- Pass the theme to `_PagedSheetModelConfig` so the model can resolve nullable entry values.
- Update `_RouteAwareSheetDraggableState` to resolve route drag config from theme instead of falling back to `widget.defaultConfiguration`:
  - When a route is active: `entry.dragConfiguration ?? theme.dragConfiguration`
  - When no route is active: `widget.defaultConfiguration` (from `PagedSheet.dragConfiguration`)

### 4. Update `_PagedSheetEntry` mixin

Make `snapGrid`, `initialOffset` nullable (they were non-nullable). `scrollConfiguration` and `dragConfiguration` stay nullable.

### 5. Update `_BasePagedSheetRoute`

- Look up theme via `PagedSheetRouteTheme.maybeOf(navigator!.context)` (returns `const PagedSheetRouteThemeData()` when no ancestor exists).
- Override `transitionDuration` to resolve from route override or theme.
- Update `buildPage` to resolve `scrollConfiguration` before passing to `DraggableScrollableSheetContent`:
  - Resolve: `scrollConfiguration ?? theme.scrollConfiguration`
  - Pass the resolved config directly (`.disabled` is handled by `DraggableScrollableSheetContent`)
- Update `buildTransitions` to resolve `transitionsBuilder` from route or theme: `transitionsBuilder ?? theme.transitionsBuilder`.

### 6. Update `PagedSheetRoute`

- Make `initialOffset`, `snapGrid`, `transitionDuration` nullable in constructor (remove default values).
- `scrollConfiguration` stays nullable (but `null` now means "inherit" instead of "no scroll").
- Store them as nullable private fields.
- Expose nullable getters for the mixin.
- Update doc comments on each parameter to document the new `null` = inherit semantics and reference `PagedSheetRouteTheme`.

### 7. Update `PagedSheetPage` and `_PageBasedPagedSheetRoute`

Same changes as `PagedSheetRoute`, including doc comments.

### 8. Update `_PagedSheetModel`

- Pass theme data (or a reference to it) through `_PagedSheetModelConfig`.
- Update `scrollConfiguration` getter to resolve via theme.
- Update `config` setter and `didChangeInternalStateOfEntry` to resolve nullable `snapGrid` via theme.

### 9. Update activities

- `_TransitionActivity._onAnimationTick`: resolve nullable `initialOffset` and `snapGrid` via theme in `owner.config`.
- `_PostTransitionWithoutAnimationActivity._effectiveInitialOffset`: same resolution.

### 10. Update release note

Update [notes/release-note-1.0.0.md](notes/release-note-1.0.0.md) with:
- Description of the new `PagedSheetRouteTheme` InheritedWidget
- Separation of `PagedSheet.dragConfiguration` (sheet-level) and `PagedSheetRouteTheme.dragConfiguration` (route default)
- The new `SheetScrollConfiguration.disabled` sentinel
- Breaking change: route `dragConfiguration: null` now inherits from `PagedSheetRouteTheme`, not from `PagedSheet.dragConfiguration`
- Breaking change: `scrollConfiguration: null` on routes now means "inherit" instead of "no scroll support" — use `.disabled` to opt out
- Migration guide for each breaking change

### 11. Refactor example app

Refactor [example/lib/showcase/ai_playlist_generator.dart](example/lib/showcase/ai_playlist_generator.dart) to use `PagedSheetRouteTheme`.

**Current problem**: All 6 routes repeat `transitionsBuilder: _createTransitionBuilder(context)`. With the theme, this is set once.

**Changes to `_SheetShell.build()`** (line 212): Wrap `PagedSheet` with `PagedSheetRouteTheme`:

```dart
PagedSheetRouteTheme(
  data: PagedSheetRouteThemeData.from(
    transitionsBuilder: _createTransitionBuilder(context),
  ),
  child: PagedSheet(
    decoration: ...,
    builder: ...,
    navigator: navigator,
  ),
)
```

**Simplified routes**:
- `_introRoute`, `_genreRoute`, `_moodRoute`, `_generateRoute` — remove `transitionsBuilder` (inherited from theme). These become just `PagedSheetPage(child: ...)`.
- `_seedTrackRoute` — remove `transitionsBuilder`, keep only `scrollConfiguration: SheetScrollConfiguration()` (route-specific override).
- `_confirmRoute` — remove `transitionsBuilder`, keep `scrollConfiguration`, `initialOffset`, `snapGrid` (route-specific overrides).

### 12. Update tests

- Update existing tests for the new API.
- Add tests verifying inheritance (route without override inherits from `PagedSheetRouteTheme`).
- Add tests verifying per-route override takes precedence.

## Critical Files

- [lib/src/scrollable.dart](lib/src/scrollable.dart) — add `SheetScrollConfiguration.disabled`
- [lib/src/paged_sheet.dart](lib/src/paged_sheet.dart) — `PagedSheetRouteTheme`, route updates, model updates
- [lib/src/sheet.dart](lib/src/sheet.dart) — update `DraggableScrollableSheetContent` for disabled sentinel
- [test/paged_sheet_test.dart](test/paged_sheet_test.dart) — test updates + new test group
- [test/integration/paged_sheet_with_auto_route_test.dart](test/integration/paged_sheet_with_auto_route_test.dart) — integration test updates
- [example/lib/showcase/ai_playlist_generator.dart](example/lib/showcase/ai_playlist_generator.dart) — refactor to use `PagedSheetRouteTheme`

## Breaking Changes

- Route `dragConfiguration: null` now inherits from `PagedSheetRouteTheme`, not from `PagedSheet.dragConfiguration`. These are independent.
- `PagedSheetRoute` / `PagedSheetPage`: `scrollConfiguration`, `initialOffset`, `snapGrid`, `transitionDuration` become nullable (null = inherit from `PagedSheetRouteTheme`)
- `scrollConfiguration: null` on a route changes meaning from "no scroll support" to "inherit." Use `SheetScrollConfiguration.disabled` for explicit opt-out.
- Internal `_PagedSheetEntry.snapGrid` / `initialOffset` become nullable

## Test Suites

Create a **new test group** `"PagedSheetRouteTheme Inheritance Test"` in [test/paged_sheet_test.dart](test/paged_sheet_test.dart). The existing `Drag Configuration Test` group (line 1563) should be **merged into this new group** since drag configuration inheritance is now part of the route theme system. Migrate all existing drag config tests to use the new `PagedSheetRouteTheme` wrapper.

### New Test Group: "PagedSheetRouteTheme Inheritance Test"

#### Boilerplate

A new `boilerplate()` function that optionally wraps `PagedSheet` with `PagedSheetRouteTheme`:

```dart
boilerplate({
  required ValueGetter<Route<dynamic>> initialRoute,
  PagedSheetRouteThemeData? themeData, // wraps PagedSheet when provided
  SheetDragConfiguration sheetDragConfiguration = const SheetDragConfiguration(), // for PagedSheet itself
})
```

A new `createRoute()` helper that accepts nullable overrides for inheritable params:

```dart
PagedSheetRoute<dynamic> createRoute({
  Key? contentKey,
  SheetOffset? initialOffset,
  SheetSnapGrid? snapGrid,
  SheetScrollConfiguration? scrollConfiguration,
  SheetDragConfiguration? dragConfiguration,
  Duration? transitionDuration,
  RouteTransitionsBuilder? transitionsBuilder,
  double height = 300,
  bool isScrollable = false,
})
```

#### Test Cases: `scrollConfiguration` inheritance

1. **"Route inherits scrollConfiguration from theme when not specified"**
   - Wrap PagedSheet with `PagedSheetRouteTheme(scrollConfiguration: SheetScrollConfiguration())`
   - Route has `scrollConfiguration: null` and scrollable content
   - Verify scroll-sheet integration is active (scrolling the content affects the sheet position)

2. **"Route explicitly disables scroll with SheetScrollConfiguration.disabled"**
   - Theme has `scrollConfiguration: SheetScrollConfiguration()`
   - Route has `scrollConfiguration: SheetScrollConfiguration.disabled`
   - Verify scrolling content doesn't affect sheet position

3. **"Route overrides scrollConfiguration from theme"**
   - Set one config on theme, a different one on route
   - Verify route's config takes precedence

#### Test Cases: `snapGrid` inheritance

4. **"Route inherits snapGrid from theme when not specified"**
   - Theme: `snapGrid` with snaps at `[SheetOffset.absolute(100), SheetOffset(1)]`
   - Route has `snapGrid: null`
   - Fling the sheet downward → it should snap to the lower snap point (top=500), proving inheritance

5. **"Route overrides snapGrid from theme"**
   - Theme snap grid: snaps at `[SheetOffset.absolute(100), SheetOffset(1)]`
   - Route snap grid: `SheetSnapGrid.single(snap: SheetOffset(1))`
   - Fling downward → sheet should spring back to top=300 (route override with single snap at 1.0)

#### Test Cases: `initialOffset` inheritance

6. **"Route inherits initialOffset from theme when not specified"**
   - Theme: `initialOffset = SheetOffset(0.5)`
   - Route has `initialOffset: null`, content height 300
   - After pump, sheet top should be at `600 - 300*0.5 = 450` (half-expanded)

7. **"Route overrides initialOffset from theme"**
   - Theme: `initialOffset = SheetOffset(0.5)`
   - Route: `initialOffset = SheetOffset(1)`
   - Sheet should be fully expanded (top=300), not half

#### Test Cases: `transitionDuration` inheritance

8. **"Route inherits transitionDuration from theme when not specified"**
   - Theme: `transitionDuration = Duration(milliseconds: 500)`
   - Push a route with `transitionDuration: null`
   - Pump 250ms → transition should still be in progress
   - Pump 500ms total → transition should be complete

9. **"Route overrides transitionDuration from theme"**
   - Theme: 500ms
   - Route: 100ms
   - Pump 150ms → transition should be complete (route override wins)

#### Test Cases: `transitionsBuilder` inheritance

10. **"Route inherits transitionsBuilder from theme when not specified"**
    - Theme: custom `transitionsBuilder` that wraps child in `Opacity` with a key
    - Route has `transitionsBuilder: null`
    - Verify the custom transition widget is present during animation by find.byKey
11. **"Route overrides transitionsBuilder from theme"**
    - Theme: builder wrapping in `Opacity`  with a key
    - Route: builder wrapping in `RotationTransition` with akey
    - Verify `RotationTransition` is present, not `Opacity` , by find.byKey

#### Test Cases: `dragConfiguration` inheritance

12. **"Route inherits dragConfiguration from theme"**
    - `PagedSheetRouteTheme.dragConfiguration` = enabled
    - Route has `dragConfiguration: null`
    - Verify route IS draggable
    
13. **"PagedSheet.dragConfiguration is independent from route theme"**
    - `PagedSheet.dragConfiguration` = enabled
    - `PagedSheetRouteTheme.dragConfiguration` = disabled
    - Route has `dragConfiguration: null`
    - Verify route is NOT draggable (inherits disabled from theme)
    - Verify shared elements (via `PagedSheet.builder`) still respond to drag (controlled by `PagedSheet.dragConfiguration`)

14. **"Migrated drag config tests"**
    - Mirror existing drag config tests (lines 1616-1766) using `PagedSheetRouteTheme` wrapper

### Updates to Existing Tests

The existing `Drag Configuration Test` group (line 1563) mixes two concerns that are now separated. Split it into:

**1. Tests that move to "PagedSheetRouteTheme Inheritance Test" group** (route-level defaults):
- "Per-route config takes precedence over global config" (lines 1616-1717) — rewrite to use `PagedSheetRouteTheme`
- "Per-route config falls back to global when per-route is null" (lines 1719-1766) — rewrite as theme fallback tests
- "Each route can have different drag configurations" (line 1964) — rewrite with theme
- "Child widgets are still interactive when drag is disabled" (line 2040) — route-level test
- "Scrollable widgets are still scrollable when drag is disabled" (line 2067) — route-level test

**2. Tests that stay in a separate "PagedSheet.dragConfiguration Test" group** (sheet-level, shared elements):
- "Shared elements are affected by global config" (lines 1802-1855) — these test `PagedSheet.dragConfiguration` effect on shared elements, independent of theme
- "Shared elements are also affected by per-route config" (lines 1856-1963) — these test how the active route's config affects shared elements
- "Sheet cannot be dragged when the drag starts at shared top/bottom bar" (line 2177) — shared element behavior

**3. New tests for `PagedSheet.dragConfiguration` independence**:
- "PagedSheet.dragConfiguration does not affect route drag behavior when theme is present" — set `PagedSheet.dragConfiguration = disabled`, theme drag = enabled, verify route is draggable
- "PagedSheet.dragConfiguration controls shared elements regardless of theme" — set sheet drag = disabled, theme drag = enabled, verify shared elements are NOT draggable



**Integration tests**: Update if they reference `PagedSheet.dragConfiguration` as route fallback.

## Verification

1. `fvm dart analyze` — no lint errors
2. `fvm dart format .` — properly formatted
3. `fvm flutter test` — all tests pass

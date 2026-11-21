---
name: debugging
description: Tips for orchestrating an iOS simulator, the Dart MCP, Maestro, and widget tests to run, observe, and verify the behavior of the smooth_sheets package with few tokens. Use this skill whenever you need to know how the package actually behaves, for any purpose — fixing a bug, verifying a GitHub issue, implementing or changing a feature, investigating the current behavior to discuss a new feature, running a repro, example, tutorial, or showcase app on a simulator, driving an app with Maestro, observing gestures, animations, snapping, or keyboard behavior, or reproducing a behavior in widget tests — even if the user does not mention the simulator or this skill.
---

# Debugging tips for smooth_sheets

These tips describe how to combine the simulator, the Dart MCP, Maestro, and widget tests to observe and verify how this package behaves. What you observe it for is up to the task. The common goal is reliable evidence for few tokens: prefer filtered, one-line outputs (grepped logs, Maestro step results, text assertions) over screenshots, view hierarchies, and unfiltered logs.

The scripts mentioned below are in the `scripts/` directory next to this file.

## Choose between tests and the simulator

There is no strict rule. Choose by what you need to observe and what it costs.

- **Tests first for first insights and for non-UI behavior.** Unit and widget tests need no build, no device, and no UI driving; they are deterministic, and their output is easy to filter. Behavior such as controller and model APIs, state changes, callbacks, and computed values (for example, whether a getter throws before the first layout) can usually be confirmed in a widget test within seconds.
- **The simulator for details that tests cannot show or may misrepresent:** real gesture velocities and timing, the platform keyboard, system insets, rendered layout, animations as a user sees them, and interaction with real routers and navigators.
- **Move between them.** A condition found on the simulator (for example, a release velocity range) can become a widget test that repeats it cheaply; a surprising test result can be checked on the simulator.
- **For UI behavior, do the final verification on the simulator,** because widget tests replace gestures, the keyboard, and timing with simulations.

## Run code on a simulator

- Put temporary apps under `example/lib/` (for example, `issue_655.dart`).
- Find the simulator with `xcrun simctl list devices booted`, and pass its UDID everywhere; several simulators can share a name. If none is booted, ask the user.
- Launch with `flutter run -d <udid> -t <target>` from the `example/` directory, in the background, with its output redirected to a log file. The Dart MCP's own launch and log tools return unfiltered logs (daemon JSON, iOS system messages, `pub get` output), so they cost more tokens.
- Stop any earlier `flutter run` for the same device first (`pkill -f "run -d <udid>"`); two apps on one simulator conflict.
- The app is ready when the log contains "Flutter run key commands". Wait for that line or for the `flutter run` process to exit, whichever comes first. A wait that only looks for the ready line never ends when the build fails.
- Then connect the Dart MCP to the new app (`dtd`: `listDtdUris`, then `connect`). Every launch creates a new DTD URI.
- Apply code changes with a hot reload first; it is the cheapest, and it even replaces a red error screen once the cause is fixed. Use a hot restart when the state or behavior after a reload looks wrong, and relaunch only as a last resort or when the entry point, native code, or configuration changes.

## Drive the app with Maestro

- **Selectors come from the code.** Wrap the widgets to tap or check in `Semantics(identifier: ...)` and target them with `id:`. Widgets with a text label can also be targeted by text, but icon-only buttons need an ID (or coordinates).
- **Combine an ID with text or state** only after wrapping it as `MergeSemantics(child: Semantics(identifier: ..., child: ...))`. A bare identifier wrapper creates its own node, separate from the widget's node: taps by ID still work, but `{id, text}`, `{id, checked}`, or `{id, enabled}` fail. An identifier on a container (such as the whole sheet) has no child nodes, so it cannot limit a search to the sheet's content.
- **Flows:** every action on the app is a flow, even a single tap. Write the scenario as a flow file, chain several scenarios that each end with an assertion, and rerun the same file after each code change. Many one-step flows, each followed by a screenshot or a log read, cost far more tokens for the same information.
- **`inspect_screen`** mostly repeats what the code already says (IDs, labels, structure, sizes). Use it for layout states that exist only at runtime: where an element is after scrolling or snapping, or which element covers another.
- **Coordinates** for gestures can usually be calculated from the sizes in the code (for example, a 400 px sheet in an 874 px viewport). Read bounds from `inspect_screen` once only when the position depends on runtime layout.
- **Use the Maestro MCP** to interact with apps on the simulator: run flows (inline or from files), take screenshots, and inspect the screen. After a failed flow, take a screenshot and grep the app log for exceptions. Do not run the Maestro CLI on the same device; it breaks the MCP's connection ("Device became unreachable during deviceInfo") until the MCP server is reconnected.
- Do not use `takeScreenshot` inside flows; it writes a PNG into the current directory, often the repository root.


### Observe behavior

- **Show values as text.** Render the value in a `Text` wrapped in `Semantics(identifier: ...)`, for example `offset=350` or `inset=336`, and check it with a Maestro assertion such as `assertVisible: {id: sheet-offset, text: offset=350}` (the text is a regular expression). A check costs one line and about 0.1 s.
- **Read values where they matter.** The sheet's descendants receive the keyboard inset minus the padding the sheet applies, so an inset read inside the sheet can be 0 while the keyboard is open. Read it from a context outside the sheet.
- **Sheet offset:** listen to a `SheetController` with `ListenableBuilder` and read `controller.metrics?.offset`. Reading `controller.value` before the sheet's first layout can throw a null-check error.
- **Logs:** use a unique prefix (`debugPrint('[655] ...')`), write one summary line per event (for example, per drag end: velocity, distance, decision), and read them with `grep '\[655\]' app.log | tail -5`. To read only what an action produced, note the log's line count before it and read from there.
- **Values inside the library:** add a temporary `debugPrint` in `lib/` (for example, in `_handleDragEnd`) to see what the library actually receives. The same lines also appear in widget test output. Mark them with a `TODO` and remove them afterwards.
- **Animations:** an `AnimationStatus` listener with a `Stopwatch` shows where a transition starts and how long it takes. Log the value on every frame to see the curve itself.
- **Take a screenshot to check what the user sees,** such as overlap, clipping, or content hidden by the keyboard. Text assertions cannot show these.
- **When something fails or takes longer than expected,** look at the screen right away with a Maestro screenshot and grep the app log for `EXCEPTION CAUGHT|Failed assertion|Null check`. A red error screen or an unexpected dialog is usually obvious on the screen but easy to miss in logs.

### Maestro pitfalls

- **Covered elements:** Maestro taps the center of an element's bounds and does not detect that another widget covers it. `scrollUntilVisible` stops as soon as the bounds are on screen, even under a bottom bar; a tap on the last list item once pressed the bar's "Next" button instead, and the flow still passed. Use `centerElement: true`, and assert the expected screen (for example, a page ID) after every tap that changes the screen.
- **Barriers:** while a modal sheet is open, its barrier removes the page below from the semantics tree. A tap by ID on that page fails with "Element not found"; a tap by coordinates hits the barrier and may close the sheet.
- **Animations slow every step:** Maestro waits for the screen to settle after each command. A 2-second refresh spinner delays the next step by about 2 s; an endless spinner delays it until Maestro's timeout (a tap took 3.7 s instead of about 1 s). A state that lasts about 1 s can be gone before the next assertion runs, so lengthen short-lived states in the repro.
- **A failing assertion waits about 17 s** before it reports the failure.
- **Sheets move before their content scrolls:** a downward swipe on a scrollable sheet first moves the sheet toward a lower snap point. The overscroll reaches the list (for example, pull-to-refresh) only after the sheet cannot move further.

### Reproduce gestures

- Maestro swipes take `start`, `end`, and `duration`; the shortest effective duration is about 100 ms. Measured examples: 220 px with `duration: 1` gave about 2200 px/s; 320 px in 800 ms gave about 200 px/s.
- Flutter's drag recognizer reports zero velocity when the release speed is 50 px/s or less (`kMinFlingVelocity`), or when the last samples moved less than the touch slop. A slow Maestro swipe (for example, 3000 ms) therefore releases with zero velocity.
- The velocity the library receives can differ from a `VelocityTracker` in the repro (for example, 204 px/s vs. 174 px/s). When a behavior depends on velocity, log it inside the library.
- Maestro cannot release at an exact velocity, stop before releasing, or reverse direction within one swipe. Reproduce those gestures in widget tests instead.

### Keyboard

- The simulator may have a hardware keyboard connected, and then the software keyboard never appears. To detect this, focus a text field and assert that a keyboard-inset text (read outside the sheet) is not zero.
- Switch with `swift scripts/sim-keyboard.swift <udid> software` (or `hardware`). The script calls a private CoreSimulator API and stops with an error if that API changed after an Xcode update.
- A sheet stays above the keyboard only with `padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)`. Without it, the keyboard covers the sheet, and the sheet cannot be dragged.
- Type with `inputText`, and check the field with `assertVisible: {id: <field-id>, text: .*expected.*}`.


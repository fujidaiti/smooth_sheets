# v0.x.x Release Notes

## Stabilized Sheet Behaviors

This release includes several improvements to sheet behaviors in response to user gestures:

- fix: Unexpected bouncing animation with ClampingScrollPhysics [#363](https://github.com/fujidaiti/smooth_sheets/issues/363)

## Other Changes

### Removed thresholdVelocityToInterruptBallisticScroll

`SheetScrollConfiguration.thresholdVelocityToInterruptBallisticScroll` has been removed. This option was part of the public API and configurable, but it never actually affected the sheet's behavior.

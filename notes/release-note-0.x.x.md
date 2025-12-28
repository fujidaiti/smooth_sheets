# v0.x.x Release Notes

## Simplified BouncingSheetPhysics configuration

The way to configure the bouncing behavior of a sheet is now much more straightforward. There are only two parameters: [bounceExtent](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BouncingSheetPhysics/bounceExtent.html) and [resistance](https://pub.dev/documentation/smooth_sheets/latest/smooth_sheets/BouncingSheetPhysics/resistance.html). The `bounceExtent` is the maximum number of pixels that the sheet can be overdragged, and the `resistance` is a factor that controls how easy/hard it is to overdrag the sheet by [bounceExtent] pixels. The higher the `resistance` value, the harder it is to overdrag further.

### Examples

Use [tweak bouncing effect example](https://github.com/fujidaiti/smooth_sheets/blob/main/example/lib/tutorial/tweak_bouncing_effect.dart) to figure out the best values for your use case. Here are some examples:

| extent:20 | extent:80 | extent:140 |
|----------|----------|-----------|
| <img src="https://github.com/user-attachments/assets/2be57075-14e3-4778-8015-0f623d89d8b6" alt="extent20"> | <img src="https://github.com/user-attachments/assets/c35cf699-cf0f-4699-bb4c-9db00b30c500" alt="extent80"> | <img src="https://github.com/user-attachments/assets/7ea51f8a-3d3c-4bc7-a117-9c2fa452f0b4" alt="extent140"> |

| resistance:-10 | resistance:3 | resistance:20 |
|----------------|--------------|---------------|
| <img src="https://github.com/user-attachments/assets/f0c0ce22-7b9c-41fe-bcc1-7ed6e374884c" alt="resistance -10"> | <img src="https://github.com/user-attachments/assets/9cc40ba6-f60e-406a-9534-6a57e0dddcba" alt="resistance 3"> | <img src="https://github.com/user-attachments/assets/592f9cc5-d477-4c92-afee-13f790ce9e11" alt="resistance 20"> |

### Breaking Changes

The following legacy APIs have been removed:

- BouncingBehavior
- DirectionAwareBouncingBehavior
- FixedBouncingBehavior
- BouncingSheetPhysics.behavior
- BouncingSheetPhysics.frictionCurve

Unfortunately, there is no straightforward way to migrate from the old APIs to `resistance` and `bounceExtent` parameters while keeping exactly the same bouncing behavior.

## Stabilized Sheet Behaviors

This release also includes several improvements to sheet behaviors in response to user gestures:

- fix: Unexpected bouncing animation with ClampingScrollPhysics [#363](https://github.com/fujidaiti/smooth_sheets/issues/363)
- fix: Inconsistent BouncingSheetPhysics behavior with keyboard state [#389](https://github.com/fujidaiti/smooth_sheets/issues/389)

## Other Changes

### Removed thresholdVelocityToInterruptBallisticScroll

`SheetScrollConfiguration.thresholdVelocityToInterruptBallisticScroll` has been removed. This option was part of the public API and configurable, but it never actually affected the sheet's behavior.

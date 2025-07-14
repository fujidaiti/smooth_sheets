# Release Note Template

This template provides guidelines for writing user-focused release notes for smooth_sheets.

## Structure

```markdown
# vX.X.X Release Note

## 🎉 New Features

### [Feature Name]

*Reported in [#XXX](https://github.com/fujidaiti/smooth_sheets/issues/XXX), fixed in [#XXX](https://github.com/fujidaiti/smooth_sheets/pull/XXX)*

[User-facing description of the feature]

**Usage:**

```dart
// Code example showing how to use the feature
```

[Optional: Media content with HTML tags for size control]

## 🐛 Bug Fixes

### [Bug Fix Description]

*Reported in [#XXX](https://github.com/fujidaiti/smooth_sheets/issues/XXX), fixed in [#XXX](https://github.com/fujidaiti/smooth_sheets/pull/XXX)*

[User-facing description of what was fixed]

## 🔧 Other Changes

### [Change Description]

*Fixed in [#XXX](https://github.com/fujidaiti/smooth_sheets/pull/XXX)*

[Description of other changes like refactoring, performance improvements, etc.]

```

## Content Guidelines

### What to Include

#### New Features
- **User benefits**: Focus on what users can now do, not how it's implemented
- **Usage examples**: Provide clear code examples showing how to use the feature
- **Visual demonstrations**: Include videos or screenshots from the original PR when available
- **Compatibility notes**: Mention if the feature maintains backward compatibility

#### Bug Fixes
- **Impact description**: Explain what the bug affected from a user perspective
- **Resolution outcome**: Describe how the fix improves the user experience
- **Platform specifics**: Note if the bug affected specific platforms (iOS, Android, desktop)

#### Meta Information
- **Issue references**: Always include links to the original issue and fixing PR
- **Format**: `*Reported in [#XXX](link), fixed in [#XXX](link)*`
- **Placement**: Place immediately after the section heading

### What NOT to Include

#### Avoid Implementation Details
- ❌ "Added `_internalMethod()` to handle state changes"
- ✅ "Improved sheet position tracking during window resizing"

#### Avoid Negative Framing for Features
- ❌ "Previously, users couldn't enable pull-to-refresh"
- ✅ "We've added support for pull-to-refresh functionality"

#### Avoid Technical Jargon
- ❌ "Refactored `SheetViewport` to monitor `SheetMetrics.rect`"
- ✅ "Fixed sheet positioning issues during window resize"

## Writing Style

### Tone
- Use "we" instead of "you" for a collaborative tone
- Write in active voice
- Keep sentences concise and clear
- Focus on user benefits and outcomes

### Examples

#### Good Examples
```markdown
### Pull-to-Refresh Support in Sheets

*Reported in [#264](https://github.com/fujidaiti/smooth_sheets/issues/264), fixed in [#402](https://github.com/fujidaiti/smooth_sheets/pull/402)*

We've added support for pull-to-refresh functionality and overscroll effects within sheets through the new `delegateUnhandledOverscrollToChild` flag in `SheetScrollConfiguration`. When enabled, this flag allows overscroll deltas that aren't handled by the sheet's physics to be passed to child scrollable widgets, enabling `RefreshIndicator` and `BouncingScrollPhysics` effects to work seamlessly within sheet content.

This feature maintains backward compatibility and requires explicit opt-in, ensuring no impact on existing code.
```

#### Bad Examples

```markdown
### Internal Refactoring of Sheet Physics

*Fixed in [#XXX](https://github.com/fujidaiti/smooth_sheets/pull/XXX)*

Previously, the overscroll handling was broken because the SheetViewport was consuming all scroll deltas without delegating them to children. We refactored the _ScrollAwareSheetActivityMixin to add a new boolean flag that controls whether unhandled overscroll gets passed through to child widgets.
```

## Media Content

### Using Videos and Images

- Use HTML tags instead of Markdown for size control:

  ```html
  <video src="https://github.com/user-attachments/assets/..." width="300" controls></video>
  ```

- Include comparison tables for before/after demonstrations
- Copy media links directly from the original PR descriptions

### Table Format for Comparisons

```markdown
| Before | After |
|------|------|
| <video src="..." width="300" controls></video> | <video src="..." width="300" controls></video> |
```

## Section Organization

### Order of Sections

1. **New Features** (🎉) - Most important for users
2. **Bug Fixes** (🐛) - Critical for stability
3. **Other Changes** (🔧) - Performance, refactoring, etc.

### Within Each Section

- Order by impact/importance to users
- Group related changes together
- Use clear, descriptive headings

## Review Checklist

Before publishing:

- [ ] All PR and issue links are working and correctly formatted
- [ ] Content focuses on user benefits, not implementation details
- [ ] Code examples are tested and accurate
- [ ] Media content is properly sized and displays correctly
- [ ] Language is positive and user-friendly
- [ ] No sensitive information or internal details are exposed
- [ ] Backward compatibility notes are included where relevant

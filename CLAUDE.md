# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Development Rules

1. Package Management
   - Installation: `flutter pub add package1 package2 ...`
   - Dev dependencies: `flutter pub add --dev package1 package2 ...`
   - Resolving dependencies: `flutter pub get`
   - Upgrading packages: `flutter pub upgrade`
   - FORBIDDEN: Direct pubspec.yaml editing without `flutter pub get`

2. Code Quality
   - Follow Dart's official style guide
   - Use meaningful variable and function names
   - Public APIs must have doc comments (lines that start with `///`)
   - Follow existing patterns exactly

3. Comments
   - Keep comments minimal and necessary only
   - Do not comment on what is obvious from reading the code
   - Only add comments for non-intuitive code or when the intent cannot be understood from the code alone

4. Testing Requirements
   - Running tests: `flutter test`
   - Always use `test/src/flutter_test_x.dart` instead of `flutter_test.dart`
   - Coverage: test edge cases and user interactions
   - New features require tests
   - Bug fixes require regression tests

## Pre-commit workflow

1. Static Analysis
   - Check lint errors with `dart analyze`
   - Fix lint errors using `dart fix --apply`
   - For specific error types: `dart fix --apply --code=code_1,code_2,...`
   - Find error type IDs in `dart analyze` output (e.g., `specify_nonobvious_property_types`)
2. Format dart files using `dart format .`
3. Make sure all tests pass

## Create a Pull Request

When all tasks are completed and ready for review, let's create a pull request.

- PR titles should follow conventional commits format (e.g., `feat(pkg): Add awesome feature`)
  - For available types and scopes, refer to `.github/workflows/pr_title_lint.yaml`
- Create a detailed message of what changed. Focus on the high level description of the problem it tries to solve, and how it is solved. Don't go into the specifics of the code unless it adds clarity
- NEVER ever mention a `co-authored-by` or similar aspects. In particular, never
  mention the tool used to create the commit message or PR
- Ensure that the pull request description follows the format defined in `.github/pull_request_template.md`

Use the following command to create a PR:

```bash
# pr_body.txt is a temporary file
gh pr create \
  --title <PR title> \
  --body-file pr_body.txt \
  --assignee @me \
  --reviewer "$(gh repo view --json owner --jq '.owner.login')" \
```

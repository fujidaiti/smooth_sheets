---
name: pr-guidelines
description: House style for writing pull request titles and descriptions (which also serve as the squash-merge commit message). MUST be consulted before writing or finalizing any PR title/body, opening a PR (e.g. via git/gh pr create), or drafting a merge commit message — whether initiated by the user or by an agent working autonomously. Also applies when revising an existing PR description or reviewing one for style compliance.
---

# PR Guidelines

Write one description that serves as both the PR body and the squash-merge commit message.

## Title

Follow the Conventional Commits format `<type>(<scope>): <Subject>`. CI rejects titles that don't match (see `.github/workflows/pr_title_lint.yaml`).

- Type: one of `fix`, `feat`, `docs`, `refactor`, `style`, `test`, `revert`, `build`, `chore`.
- Scope: required, one of `ci`, `pkg`, `example`, `env`.
- Subject: sentence case, no trailing period: `fix(pkg): Sheet jumps when the keyboard closes` (not `fix(pkg): sheet jumps...`).

## Description

### Write for the reader, not the author

Consolidate the messy commit history (`install`, `fix`, `style`, `rename`, `cleanup`, WIP merges) into one coherent prose description of what actually changed. Don't narrate the path taken to get there.

- Bad: "This PR started as a Patrol spike and ended up replacing a bunch of stuff. See commits for details."
- Good: "Replace the Flutter integration_test harness and external Prism mock server with Patrol and in-process HTTP mocking."

### Focus on behavior, not implementation

Describe what changed and why, at the level of behavior and intent. Skip class names, method signatures, provider wiring, file-by-file walkthroughs — the diff already shows those. (Exception: if the change *is* the implementation, e.g. a refactor, implementation detail becomes the point.)

- Bad: "Each test reads Dio from the Riverpod container and attaches a DioAdapter."
- Good: "Tests no longer depend on a separately-launched mock process."

This applies to the title too:
- Bad: `test(pkg): Add DioAdapter and remove app_harness.dart`
- Good: `test(pkg): Rework integration tests with Patrol and in-process HTTP mocking`

### Omit what the diff, README, and structure already show

Don't restate directory layout, naming conventions, or added keys if they're obvious from opening the changed files. Redundant description buries the parts that aren't obvious.

- Bad: "Adds `today_test.dart` and `feeds_test.dart`, a `helpers.dart` with `pumpApp`/`httpMockAdapter`, and `debug_keys.dart` defining `feedRow`, `entryRow`, `storyCard`… (see README for the full key list)."
- Good: (nothing — let the files and README speak for themselves)

### Omit verification reports

Don't report what you did to verify the change or what you observed while doing so. The description becomes a permanent commit message, and statements about one local run are not useful to future readers; CI and reviewers check correctness independently.

- Bad: "Verified locally that all tests pass with both Flutter 3.41.0 and 3.47.5."
- Bad: "Ran the app on an iOS simulator and confirmed the list scrolls smoothly."
- Good: (nothing)

### Lead with the headline, prefer real outcomes

Open with a one-sentence summary. Describe the *outcome* a change enables, not the mechanism.

- Bad: "Each test reads the live Dio from the Riverpod container and attaches a DioAdapter with a FullHttpRequestMatcher, enqueuing replies per route."
- Good: "Because mocking is now stateful, tests can assert on real outcomes: the subscribe test verifies the feed actually appears in the list, not just that a confirmation snackbar showed."

### Start from symptoms, not abstract arguments

Ensure readers can tell at a glance whether this PR is a refactor, bug fix, or new feature. Starting the description from an abstract argument makes it harder and ambiguous. Always include real symtoms like error messages, if available.

Bad:

```markdown
Rename the `server/integration_test` package and directory to `server/itest` (package `itest`). Go reserves the `_test` suffix for external test packages (the `foo_test` companion of package `foo`), so a `*_test.go` file declaring `package integration_test` is ambiguous — it reads either as the internal package literally named `integration_test` or as the external test package of a package named `integration`.

Go resolves the ambiguity from whichever file establishes the package name first in alphabetical filename order. The build only worked because `helper.go`, a non-test file, sorts ahead of every `*_test.go` file and pins the real name. Any test file sorting before `helper.go` has its `_test` suffix stripped, is read as the external test package of `integration`, and collides with `helper.go`, failing the build with "found packages integration and integration_test".

Naming the package `itest` removes the ambiguity and keeps the build independent of filename order, and it frees up `integration` for use as a feature package name. The `testenv` import path and its `e2e` importer are updated to match, and the `TestMain` file is renamed to `main_test.go`.
```

Good:

````markdown
Adding a new integration test file can break the build depending on its filename, with errors something like this:

```console
found packages integration (feed_test.go) and integration_test (helper.go) in /…/server/integration_test
```

Naming the package `integration_test` is the cause: Go reserves the `_test` suffix for external test packages (the `foo_test` companion of package `foo`), so a `*_test.go` file declaring `package integration_test` is ambiguous — it reads either as the internal package literally named `integration_test` or as the external test package of a package named `integration`.

Renaming the package and directory to `itest` removes the ambiguity. It also frees up `integration` for use as a feature package name.
````

### Call out non-obvious side effects and tradeoffs

Surface anything a reviewer should consciously sign off on, especially outside the change's stated scope: a dependency downgrade, a dropped code path, a pinned pre-release, a temporary workaround. Put these in a dedicated `## Notes` section at the end, one bullet per item — keep them out of the main narrative.

```markdown
## Notes

- The mocking library constrains Dio, downgrading it from 5.10.0 to 5.9.2, which drops the transformTimeout error branch.
- patrol is pinned to a dev release for Swift Package Manager support.
```

## Formatting

- Prose paragraphs, not bullet-dumps of every file touched.
- No hard-wrapping — GitHub soft-wraps Markdown. One paragraph = one line.
- Keep it short: a few tight paragraphs beat an exhaustive changelog.
- Use code spans only for genuine code snippets, such as local variable names, function calls, query parameters, and literal values. Write packages, libraries, tools, and class names as plain text (e.g. "Riverpod", "Dio", "AsyncValue", not `Riverpod`, `Dio`, `AsyncValue`). Overusing code spans makes every name look equally technical and makes the prose harder to read. Exception: use a code span when the plain-text name could be read as an ordinary word, e.g. write `url` when it means Go's standard url package, because "the url package" or "url" alone is ambiguous in prose.

## Base branch

Always target the branch's actual base, not `main`/`master` by default. Before opening the PR, determine what the current branch was created from (e.g. `git merge-base --fork-point`, or the branch's tracked upstream) and set that as the PR's target/base branch. Example: if `feat-12` was branched off `beta`, the PR must be `feat-12 -> beta`, not `feat-12 -> main`. If the base can't be determined with confidence, ask before opening the PR rather than defaulting to `main`.

## Example

A **bad** description:

```markdown
## What

Adds keyset (cursor) pagination end-to-end for the four list endpoints — `GET /feeds`, `GET /feeds/{id}/timeline`, `GET /newspapers/today`, and `GET /reading-list` — and wires infinite-scroll paging into the corresponding client screens.

> [!NOTE]
> Base branch is `reading-list` (intentional) — this stacks on top of the reading-list work rather than `main`.

## API

- Each list endpoint gains an optional `after` query param (opaque cursor) and a `next_cursor` field in the response, absent on the last page.
- `FeedEntry.snapshot_at` is now required.
- Dart bindings regenerated to match.

## Server

- Generic base64url-encoded cursor (`{key, tiebreaker}`) with `encodeCursor`/`decodeCursor`; page size fixed at 50.
- Handlers fetch `size + 1` rows, trim, and derive `next_cursor` from the last kept row. Ordering: reading list by `(saved_at, id) DESC`, timeline by `(COALESCE(published_at, snapshot_at), id) DESC`, feeds by a title-prefix sort key + id.

## Client

- New `core/pagination/` module: `Page<T>`, `PagedState<T>`, an `appendNextPage` helper that no-ops on redundant/stale loads and survives a concurrent refresh, plus `InfiniteScrollList` and `LoadMoreFooter` widgets.
- Repositories return `Page<T>`; list providers become Notifiers exposing `loadMore()`; the feeds, timeline, today, and reading-list screens now page on scroll with a loading/retry footer.

## Tests

- Added an integration test covering scroll-to-load-next-page on the feeds list.

## Follow-ups (tracked as TODOs in code)

- Newspaper uses a placeholder `id ASC` cursor; a priority-based cursor is still to be designed (this also changed story ordering from `published_at DESC`).
- Feeds sort on a crude 5-char title prefix; wants a proper stored sort key + index.
- Remove leftover `fmt.Print(err)` debug logging and fix the `paginationCusor` typo.
```

A **good** description:

```markdown
The four list endpoints — `GET /feeds`, `GET /feeds/{id}/timeline`, `GET /newspapers/today`, and `GET /reading-list` — now return one page at a time with an opaque `next_cursor`, and the app loads further pages as the user scrolls instead of fetching an entire collection up front.

The server does keyset pagination with a fixed page size, returning `next_cursor` until the last page (where it's omitted). Cursors are opaque base64-encoded `(sort key, id-tiebreaker)` pairs, so ordering stays stable even when sort values collide. Clients pass the previous response's cursor back via `?after=`.

On the client, a small pagination toolkit under `core/pagination` carries the accumulated list, the next cursor, and the next-page loading/error state through a single AsyncValue, keeping first-page load/error separate from next-page load/error. The feeds, feed timeline, today, and reading-list screens wrap their scroll views to fetch the next page as the bottom approaches.

## Notes

- The feeds sort key is a crude `LEFT(title, 5)` prefix (with a matching `TODO`); no supporting index exists yet, so these queries aren't backed by an index.
```


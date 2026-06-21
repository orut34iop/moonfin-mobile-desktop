# Test Architecture Review

Date: 2026-06-22

## Round 1: Audit & Diagnostics

### Current architecture summary

- Top-level test suite has 10 Dart test files and roughly 75 test cases.
- `flutter test --coverage --no-pub` passes, but the non-generated business
  coverage baseline is low: about 4.24%.
- Coverage is concentrated in a few modules:
  - `lib/playback`: about 19.8%
  - `lib/data`: about 12.4%
  - `lib/preference`: about 15.4%
  - `lib/ui`: about 1.7%
  - `lib/auth`: about 1.6%
  - `lib/syncplay`: about 0.3%
- CI previously focused on platform build artifacts. It did not enforce a
  dedicated test, coverage, or diagnostics gate on pull requests.
- Streaming Cache now has dedicated diagnostics and smoke tooling, but external
  playback validation remains separate from ordinary unit tests.

### Issue backlog

| Priority | Issue | Evidence | Risk |
| --- | --- | --- | --- |
| P0 | No CI-level test quality gate | Existing workflows build artifacts, but did not run coverage gate | PRs can pass while regressions remain untested |
| P0 | Very low business coverage | Non-generated business coverage is about 4.24% | Core playback, auth, sync, and UI regressions are likely to escape |
| P0 | Manual failure modes not represented as automated checks | Streaming Cache manual testing found slow cached seeks after earlier green tests | Human validation keeps finding issues after automation passes |
| P1 | Test seams are shallow around server clients | Tests define wide fake adapters with many `UnimplementedError` members | New integration tests are expensive to write and maintain |
| P1 | Coverage numbers were not actionable | Generated/l10n files skew raw coverage, and no baseline threshold existed | Coverage cannot be used as a regression signal |
| P1 | Test layers are not explicit | Unit, integration, widget, smoke, and external playback checks are mixed in docs and tools | Engineers can run the wrong validation set for a change |
| P2 | Flakiness controls are ad hoc | Some tests use real timers, short timeouts, and `pumpAndSettle` | Failures may be timing-sensitive and hard to diagnose |
| P2 | Local package tests are not unified | `packages/rar_fork/test` exists outside the top-level suite | Package regressions can be missed |

## Round 2: Redesign & Strategy

### Target test layers

1. **Unit tests**
   - Fast, deterministic tests for pure functions, parsing, state machines, and
     policy mapping.
   - Examples: device profile decisions, Streaming Cache log summaries, audio
     labels, preference migrations.

2. **Integration tests**
   - Tests crossing meaningful seams: ViewModel + repository + in-memory DB +
     fake server adapter.
   - These should use shared adapters where possible so the interface is deep
     and locality improves.

3. **Widget tests**
   - Focused user-visible contracts, not broad screenshot coverage.
   - Examples: route parameter display, empty states, critical controls.

4. **Smoke/E2E tools**
   - External-environment checks such as Jellyfin playback and Streaming Cache.
   - These should be deterministic where possible through fixed media ids and
     seeds, but should remain separate from ordinary unit tests.

5. **Quality gate**
   - A CI-enforced baseline that runs tests with coverage, excludes generated
     sources, and fails on coverage regression below current known thresholds.

### Action items

- Add a coverage quality gate tool that parses LCOV, excludes generated sources,
  and enforces current baseline thresholds.
- Add unit tests for the quality gate itself.
- Add a GitHub Actions workflow for targeted analyze, `flutter test --coverage`,
  and coverage baseline enforcement.
- Keep Streaming Cache diagnostics and smoke checks documented as external
  validation, not substitutes for unit/integration coverage.
- Later: extract shared fake server adapters to reduce repeated `MediaServerClient`
  test setup.

## Round 3: Implementation & Regression Verification

### Implemented changes

- Added `tool/test_quality_gate.dart`.
- Added `test/qa/test_quality_gate_test.dart`.
- Added `.github/workflows/quality.yml`.
- Added this review document as the persistent QA architecture record.

### Current gate thresholds

The first gate intentionally protects the current baseline rather than claiming
the project has strong coverage:

- Overall non-generated coverage: `>= 4.0%`
- `lib/data`: `>= 10.0%`
- `lib/playback`: `>= 15.0%`
- `lib/ui`: `>= 1.0%`

These thresholds should be raised as new tests are added.

### Follow-up technical debt

- Extract reusable fake adapters for `MediaServerClient`, `ItemsApi`, and image
  APIs.
- Add focused integration tests for auth flows, SyncPlay, queue management, and
  playback UI state.
- Decide whether package-level tests under `packages/` should be included in a
  separate package matrix.
- Clean existing analyzer warnings so full `flutter analyze` can become a hard
  CI gate.

### Verification status

- `dart analyze test tool docs lib/playback/streaming_cache_diagnostics_summary.dart`
  passes.
- `flutter test --coverage --no-pub` passes.
- `dart run tool/test_quality_gate.dart coverage/lcov.info --min-overall=4.0 --min-dir=lib/data:10.0 --min-dir=lib/playback:15.0 --min-dir=lib/ui:1.0`
  passes.
- Full `flutter analyze` still fails on pre-existing analyzer debt:
  - `lib/data/services/app_update_service.dart` private type in public API.
  - `lib/ui/screens/admin/admin_shell_screen.dart` unused import.
  - Deprecated Flutter APIs in admin/detail/home/settings UI files.
  - Unused underscore variables in shuffle UI widgets.

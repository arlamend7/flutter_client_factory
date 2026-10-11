# Version 1.0.0 release audit — 2026-10-11

Both manifests are prepared as version **1.0.0** under the MIT license. These are
local validation results, not a published pub.dev score. No package was published,
Git tag created, or source pushed as part of this preparation.

## Package quality

Pana 0.23.19 was run against disposable copies using Dart 3.13.4 and, for the
adapter, Flutter 3.47.5.

| Package / audit configuration | Total | Documentation | Remaining prerequisites |
| --- | --- | --- | --- |
| Core, release manifest | **150/160** | **20/20** | GitHub must serve the matching publishable package manifest |
| Flutter adapter, release manifest with hosted core dependency | **40/160** | **10/20** | Matching remote manifest and core 1.0.0 available on pub.dev; dependency resolution blocks analysis, API documentation, and platform checks |
| Flutter adapter, diagnostic copy using local core | **130/160** | **20/20** | Remote manifest costs 10 points; the temporary path dependency produces an analysis warning costing 20 points |

The diagnostic copy verifies adapter API documentation independently of publication.
It is not the release manifest and does not prove hosted dependency resolution.
The real adapter declares `flutter_client_factory: ^1.0.0`; checkout-only overrides
enable local development and are excluded from publication. Do not change that
dependency to a path or suppress warnings to claim a higher release score.

Core public API comments cover 182/482 elements (37.8%); the adapter covers 8/8
(100%). Both meet the documentation scoring threshold. Documentation points do
not measure completeness of every use case or establish exhaustive test coverage.

Raw reports are retained locally in `build/pana-1.0.0-core.json`,
`build/pana-1.0.0-widgets.json`, and `build/pana-1.0.0-widgets-local.json`.
Build outputs are excluded from publication. **160/160 has not been verified.**

## Validation and archive checks

- Formatting passed for 185 Dart files; structural checks passed, including one
  declaration per file and no third-party core runtime imports.
- Core analysis passed and all 70 core tests passed on Dart 3.13.4.
- Flutter adapter/example analysis passed and all three Flutter tests passed.
- The simplest live HTTP example and deterministic authentication/retry example
  ran successfully. Core API documentation generated without warnings or errors.
- The preceding convenience API validation passed all 70 tests on Dart 3.4.4 and
  browser JavaScript/WebAssembly integration on both SDKs. Subsequent release
  preparation changed metadata, documentation, examples, and GitHub files.
- The clean core publication dry run passed with zero warnings and an approximately
  69 KB archive. The adapter dry run passed with zero warnings, an approximately
  3 KB archive, and a local-dependency-override hint. That hint means the dry run
  does not establish that the hosted core dependency resolves.
- The working-checkout core dry run reports uncommitted changes and tracked old
  paths from the rename; the clean-copy check above isolates archive validation.
- All GitHub YAML files parsed successfully. CI and the manual package-quality
  workflow are prepared but have not been run on GitHub in this session.

Archive sizes describe package downloads, not installed Flutter application sizes.
See [size methodology](size.md) and the [validation history](validation.md) for
platform evidence and limits.

## Completing release verification

Follow the [release order](releasing.md#release-order): push matching manifests,
rerun the core audit, then publish core only when authorized. Once core 1.0.0 is
hosted, remove local overrides in a disposable adapter checkout and rerun dependency
resolution, analysis, tests, documentation, package audit, and publication dry run.
The manual quality workflow supports that hosted adapter audit. Record its actual
score before claiming a maximum score or publishing the adapter.

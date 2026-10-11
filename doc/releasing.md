# Release and package quality

Publication is intentionally disabled. MIT licensing is selected. The public name
and repository metadata must be finalized before release. Never insert speculative
URLs to make an audit look complete.

## Checks

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test example tool
dart analyze lib test example tool
dart test
python3 tool/check_structure.py
dart doc
python3 tool/package_size.py
```

Run native integration tests with permission to open loopback sockets. TLS fixtures
are disposable; regenerate with `bash tool/generate_test_certificates.sh` before
certificates expire. CI regenerates them for each run. Browser verification uses
`tool/verify_browser.sh` with Dart, Node 22+ and Chrome available. It builds and runs
both JS and Wasm against local fixtures, including cross-origin behavior.

Use a clean copy for minimum-SDK dependency resolution (`dart pub get` using Dart
3.4.4), then analyze/test and compile both browser targets in that copy. A lockfile
created by a newer SDK is not evidence of minimum-SDK compatibility.

The optional adapter is checked separately:

```sh
cd packages/flutter_client_widgets
flutter pub get
flutter analyze
flutter test
```

## Pub audit

[Pub scoring](https://pub.dev/help/scoring) evaluates package conventions,
documentation, platform compatibility, analysis, dependencies and SDK support.
Likes and download statistics are separate and cannot be guaranteed. A high local
audit score is not a guarantee of the hosted service's future result.

Install pana as a developer tool, outside runtime dependencies, and run it against
a clean release copy after real public URLs are available. Generate documentation
and review public API coverage. Use `dart pub publish --dry-run` on the release copy
with `publish_to: none` removed. Review every included file. This command must not be
replaced with a real publish during validation.

The adapter's path dependency must become a hosted version constraint before its
release. Validate core and adapter independently. Follow the official
[publishing guide](https://dart.dev/tools/pub/publishing) for metadata and archive
rules. `.pubignore` excludes tests, tools, build outputs, local dependency state and
the nested adapter from the core archive. Preserve examples, docs and licenses.

## Required release review

- Real repository/issue URLs and confirmed package names.
- Clean analysis, tests, API documentation, browser execution, minimum SDK checks.
- Supported OS/device checks and documented untested combinations.
- Dry-run archive inspection, dependency/size review, complete changelog.
- Core published before adapter; adapter examples use the released versions.

Do not claim a verified maximum score or universal SDK compatibility from a scaffold,
a successful compiler run, or a manually estimated checklist.

For this SDK, pana's default standalone dartdoc works. `--dartdoc-version sdk`
passes options that the installed SDK's `dart doc` command does not accept; avoid
that pana option. Standalone `dart doc` remains suitable for manual API generation.

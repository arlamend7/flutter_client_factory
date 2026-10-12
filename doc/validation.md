# Validation record

For the latest 1.0.0 scores, archive checks, and release prerequisites, see the
[release audit](release_audit.md). The entries below preserve earlier checkpoints.

## Documentation and examples 1.0.2 — 2026-10-11

The default example now injects a client into `UserService` and leaves status
validation and typed/text decoding to the caller. Registration includes diagnostic
logging, a JSON Accept header, and an overall timeout. A separate application
sign-in recipe demonstrates model conversion before session storage/navigation.

- Core analysis and all 79 tests passed, including nine new example/service tests.
- The default example completed real typed and text requests to JSONPlaceholder.
- Formatting, structure checks (189 Dart files), and local documentation file and
  heading links passed.
- No public core API or runtime dependency changed. Version metadata is 1.0.2 for
  both packages; this entry does not claim a new hosted pub score or publication.

## Publication workflow checks — 2026-10-11

The docs deployment and separate core/adapter publishing workflows passed
actionlint 1.7.12 and YAML parsing. Release-tag checks accepted matching package
tags and rejected mismatched versions, wrong-package tags, and branch refs.
The same documentation build commands produced 16 core libraries and one adapter
library with zero warnings/errors; the landing page's local links resolved.
Flutter documentation generation requires Flutter on PATH with FLUTTER_ROOT set,
as provided by the workflow's Flutter setup action.

These are local checks. No workflow was dispatched, package published, tag pushed,
or GitHub Pages setting changed. Hosted adapter resolution remains a prerequisite
for its publication job. See [workflow setup](releasing.md#github-pages-deployment).

## Initial validation

Initial local work recorded on 2026-10-10; subsequent checks are dated below.
These results are evidence for the tested
combinations, not a claim that every device or network schedule has been exercised.

| Check | Result |
| --- | --- |
| Core static analysis, Dart 3.13.4 and 3.4.4 | No issues |
| Formatting | 163 Dart files, no changes required |
| Structure and runtime imports | 163 files checked; one type per file |
| Core unit/native integration suite, Dart 3.13.4 | 46 passed |
| Core unit/native integration suite, Dart 3.4.4 | 46 passed in isolated dependency resolution |
| Current SDK browser JS and Wasm | Both passed against local HTTP/CORS/WebSocket fixtures |
| Minimum SDK browser JS | Passed, including three-argument browser callback compatibility |
| Minimum SDK browser Wasm | Passed with the Dart 3.4 loader API |
| Flutter 3.47.5 adapter + example analysis | No issues |
| Flutter notifier/widget tests | 2 passed |
| Dart example commands | Typed client, HTTP, resilience, testing, SSE and WebSocket examples all passed |
| API docs | Core: 16 libraries; adapter: 1 library; no dartdoc warnings/errors |
| Package dry run | Pre-rename archive inspected; rerun against the final release manifest |
| Local pana 0.23.19 | Core 150/160; adapter 150/160 |

The initial minimum-SDK browser execution caught callback arity differences that
compilation did not catch. The transport now accepts all arguments passed by
Headers.forEach. The harness handles both old and current Wasm loader APIs.
Dart 3.4's Wasm compiler labels its support experimental.

## Rename verification

The core is `flutter_client_factory`; its main import is
`package:flutter_client_factory/flutter_client_factory.dart`. The optional adapter
is `flutter_client_factory_widgets`, including its folder and library entry point.
Local Git origin points to the renamed repository. Core and Flutter dependency
resolution, analysis, all 46 core tests and both Flutter tests were rerun successfully.
The minimum-SDK runtime results above precede this naming-only change. Generated API
documentation was rebuilt with the new package/library identities.

## Convenience API verification — 2026-10-11

- Core analysis and all 70 tests passed on Dart 3.13.4 and 3.4.4. The minimum SDK
  used an isolated copy with its own dependency resolution from the local cache.
- Browser JavaScript and WebAssembly integration passed on both SDKs, including
  multipart shortcuts, response decoding, and an overall response-body timeout.
  The new browser check exposed Fetch AbortError masking the timeout during
  cleanup; cancellation now retains the original typed error.
- Flutter adapter/example analysis passed; all three tests passed, including
  explicit loader startup and cancellation when the notifier is disposed.
- Typed-client, local HTTP, testing, resilience, and SSE/WebSocket examples passed.
- Formatting and structural checks passed for 181 Dart files. No third-party
  runtime dependencies were added. Core API docs rebuilt with zero warnings/errors.

New coverage includes every convenience verb through middleware, repeated query
values, header overrides, immutable request transforms, status rejection, bounded
reading, response cleanup, timeout overrides, retry-backoff cancellation, stalled
native/browser bodies, late responses, testing waits and diagnostics, multipart
snapshots, one-shot file upload, download, SSE, and Flutter resource ownership.
These checks do not establish exhaustive device/network coverage or a new pub score.

## Covered behavior

### Single interceptor pipeline verification — 2026-10-11

Removed `attemptInterceptors` and the second pipeline assembly. Dart 3.13.4
analysis passed for `lib`, `test`, `example`, and `tool`; the full core suite passed
all 50 tests. Four new tests cover downstream replay across retry and auth refresh,
discarded-response cleanup, fresh timeout scopes with linked cancellation, and
transport-dispatch guards after cancellation or client disposal. Changed Dart files
were formatted, structure checks passed for 164 files, and `git diff --check` passed.
Minimum-SDK, browser-runtime, and Flutter results above predate this migration.

### Registration convenience verification — 2026-10-11

The new `registerClient` API passed Dart 3.13.4 analysis and the complete 58-test
core suite. Eight added tests cover direct settings, lazy transport creation and
rotation, callback precedence and execution count, immutable snapshots,
case-insensitive headers, invalid settings, and failed registration cleanup.
The updated local HTTP example passed with the default platform transport.
Formatting and structure checks passed (167 Dart files); API documentation rebuilt
with zero warnings or errors. Minimum-SDK, browser-runtime, and Flutter tests were
not rerun for this convenience API change.

### Existing coverage

- Native upload/streaming, connection reuse, per-request/body cancellation,
  cross-origin credential stripping, custom TLS trust and validated file resume.
- TCP, UDP and native/browser WebSocket echo; bounded WebSocket reconnects and
  heartbeat send failure cleanup.
- Middleware order, bounded retries, Retry-After, write-replay restrictions,
  deadlines, queue cancellation, circuit recovery, failover and hedge cancellation.
- Session-scoped concurrent auth refresh, foreign-origin isolation, ETag cache
  validation, Vary, cache limits and exclusion of private cookie responses.
- Header/body snapshots, multipart framing, bounded readers, decoder failure
  cleanup, request events and consumer test-controller verification.
- SSE fragmented UTF-8, multiline data, last-event ID/retry metadata and 204 stop.
- Superseded resource reads and Flutter widget/notifier cleanup.
- Browser Fetch upload, streaming download cancellation, XSRF origin boundary,
  CORS, restricted headers, stalled upload disposal and declared body length.

## Historical pre-1.0.0 audit notes (superseded by release audit)

After the rename, both local audits earned full documentation, analysis, dependency
and static platform points. Both retained 150/160 because the remote repository
still contained the old package manifests at audit time. Repository, homepage and
issue tracker URLs now point to `https://github.com/arlamend7/flutter_client_factory`.
Pana requires matching named manifests on the remote, with a version and without a
`publish_to` property, before granting the remaining repository metadata points. Core documented API coverage was 135/427 (31.6%);
adapter coverage was 7/7 (100%). Static platform points do not mean device tests ran.
Generated core API documentation is available locally at `doc/api/index.html`.
The raw local audit reports are in `build/pana-report.json` and
`build/pana-widgets-report.json`; build outputs are excluded from publication.

The 1.0.0 manifests now remove publish_to and the adapter declares ^1.0.0, with
checkout-only overrides. No publication has occurred. See the [current release audit](release_audit.md)
for verified scores and the remaining GitHub/hosted-dependency prerequisites.

CI workflows are prepared; their execution on the renamed GitHub repository has
not been verified in this local session. Native tests ran on this macOS host, not Android/iOS devices
or Windows/Linux machines. No exhaustive TLS/proxy/server interoperability, long
soak test, or real Flutter APK/IPA size comparison has been completed. Use those
checks before declaring a stable production release.

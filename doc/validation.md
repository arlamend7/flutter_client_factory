# Validation record

Local work recorded on 2026-10-10. These results are evidence for the tested
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
| Package dry run | Archive inspected; metadata warning remains pending the repository URL |
| Local pana 0.23.19 | Core 150/160; adapter 150/160 |

The initial minimum-SDK browser execution caught callback arity differences that
compilation did not catch. The transport now accepts all arguments passed by
Headers.forEach. The harness handles both old and current Wasm loader APIs.
Dart 3.4's Wasm compiler labels its support experimental.

## Covered behavior

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

## Scores and remaining release work

The two local audits earned full documentation, analysis, dependency and static
platform points. Both lost 10 metadata points because real homepage/repository
URLs have not been supplied. Core documented API coverage was 135/427 (31.6%);
adapter coverage was 7/7 (100%). Static platform points do not mean device tests ran.
Generated core API documentation is available locally at `doc/api/index.html`.
The raw local audit reports are in `build/pana-report.json` and
`build/pana-widgets-report.json`; build outputs are excluded from publication.

A 160/160 claim would be premature. After the public name/repository is confirmed,
add real metadata, publish the reviewed core, replace the adapter's path dependency
with its hosted version, then audit the final releases again. Keep `publish_to: none`
until publication is deliberately authorized.

CI workflows are prepared, but remote GitHub CI has not run because the repository
has not been created. Native tests ran on this macOS host, not Android/iOS devices
or Windows/Linux machines. No exhaustive TLS/proxy/server interoperability, long
soak test, or real Flutter APK/IPA size comparison has been completed. Use those
checks before declaring a stable production release.

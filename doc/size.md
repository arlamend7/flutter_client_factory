# Package and application size

There are three separate costs: downloaded source/dependencies, compiled application
code, and runtime memory. Splitting import files only directly affects the API
surface and compiler reachability; pub downloads the entire selected package.

## Implemented limits

- No third-party runtime dependency in the Dart package.
- Flutter integration is a separate optional package.
- Feature-specific exports; no all-features umbrella or eager global registrations.
- Native/browser implementations selected conditionally.
- Typed byte buffers instead of ordinary integer lists for stored response/request
  bytes and readers. Snapshots remain immutable and copy caller-owned buffers.
- Native streaming; browser uploads explicitly bounded to 8 MiB by default.
- Default reader buffering: 8 MiB. Default cache: 100 entries / 16 MiB, with 1 MiB
  per-entry middleware limit. Uncacheable/unknown-length responses stay streaming.
- `.pubignore` excludes tests, tools, build outputs, generated API docs, local package
  state and the nested Flutter package from the core's published source archive.

These defaults bound representation bytes, not all object overhead. A consumer that
collects a stream into an unbounded list can still use excessive memory.

The publication dry run reported a **51 KB compressed archive**. Runtime Dart
source totals about **122 KB** before compression. This includes the examples and
written documentation in the archive; it excludes build/test/development files.

## Measurements

Local sample: macOS ARM64, Dart 3.13.4. These are small Dart fixture artifacts,
not the incremental size of a Flutter APK/IPA. Reproduce with
`bash tool/measure_size.sh` and `python3 tool/package_size.py`.

| Fixture | Native executable | Optimized JavaScript | Gzipped JavaScript |
| --- | ---: | ---: | ---: |
| HTTP usage only | 6,437,024 bytes | 151,922 bytes | 46,832 bytes |
| Same usage + unused portable feature imports | 6,437,040 bytes | 151,930 bytes | 46,839 bytes |

The two JS outputs are identical after normalizing the source-map filename. The
16-byte native artifact difference is too small to infer a feature cost. These
fixtures verify that unused imports do not retain the optional implementations in
this build; actual feature usage and compiler changes can change results. The
native executable includes the Dart runtime and is not this library's standalone
contribution. Compiler versions and future code changes may alter exact byte counts.

An AOT microbenchmark streamed 64 MiB using repeated 64 KiB chunks with 786,432 bytes
of sampled RSS growth. Over 5,000 in-memory requests, zero pass-through interceptors
averaged 1.808 microseconds per request and five averaged 1.9192 microseconds. This
is a single local run with no real network, reused chunks, and sampled process RSS;
it is not a production memory/latency guarantee. Reproduce by compiling and running
`tool/benchmark.dart`. The native integration suite separately checks connection reuse.

## Application verification

Compare matching release builds of your real Flutter application, using the same
SDK, architecture, compiler flags and assets. See Flutter's official
[application size guidance](https://docs.flutter.dev/perf/app-size). Measure the
smallest HTTP use case and your selected feature set. Report both download and
installed size, not source line count or debug build size.

Keep this package together while its archive remains small. Further package splitting
would reduce source download only for users who omit those packages, at the cost
of independent versions and dependency coordination. The separate Flutter adapter
already removes the largest unnecessary dependency boundary for pure Dart users.

# Examples

Run from the repository root after `dart pub get`:

| Command | Demonstrates |
| --- | --- |
| `dart run example/lib/main.dart` | Typed client with deterministic fake transport |
| `dart run example/lib/local_http.dart` | Real loopback HTTP server, named client and JSON decoding |
| `dart run example/lib/resilient_request.dart` | Retry + deadline and response disposal without external services |
| `dart run example/lib/testing_client.dart` | Capture, inspect, flush and verify a consumer request |
| `dart run example/lib/connections.dart` | Real local SSE and WebSocket connections |
| `dart run example/lib/download_file.dart URL OUTPUT_PATH` | Validator-based file resumption against your endpoint |

The local HTTP/connection examples need permission to bind loopback sockets.
The download example contacts the URL you supply and writes the output path.
The typed, resilience and testing examples work offline. `lib/models`, `lib/services` and `lib/defaults` keep one type per file.
For browser integration see `tool/verify_browser.sh`. For Flutter see the separate
[adapter example](../packages/flutter_client_widgets/example/README.md).

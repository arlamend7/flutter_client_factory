# flutter_client

Dependency-free networking for Dart and Flutter: named and typed HTTP clients,
shared transport lifetimes, streaming bodies, and opt-in policies.

**Development preview.** MIT licensed. Publication is disabled while release
validation and repository metadata are completed. Requires Dart 3.4 or newer
(below Dart 4); older Flutter releases whose Dart SDK predates 3.4 cannot use it.
The proposed public name is `flutter_client_factory`, pending the owner's choice.

## Quick start

Until publication, use a local path dependency:

```yaml
dependencies:
  flutter_client:
    path: /path/to/flutter_client
```

```dart
import 'package:flutter_client/flutter_client.dart';

Future<String> load(Uri endpoint) async {
  final factory = DefaultHttpClientFactory();
  factory.register('api', ClientRegistration(
    createTransport: createPlatformTransport,
    options: HttpClientOptions(baseUri: endpoint),
  ));
  final client = factory.create('api');
  try {
    final response = await client.send(HttpRequest(uri: Uri.parse('status')));
    if (!response.isSuccessful) {
      await response.dispose();
      throw StateError('HTTP ${response.statusCode}');
    }
    return const ResponseBodyReader().readText(response);
  } finally {
    client.dispose();
    await factory.close();
  }
}
```

In an application, keep the factory at application/session scope and reuse it.
Always consume or dispose each response. Disposing a logical client does not close
shared connections. Decoders buffer at most 8 MiB by default; stream larger bodies.
HTTP error statuses are responses, while cancellation, timeouts and network errors
are exceptions. JSON decoding takes an explicit domain conversion callback.

## Choose what you use

| Import suffix | Capability |
| --- | --- |
| `flutter_client.dart` | HTTP models, bodies, events, factory, middleware, platform transport |
| `io.dart` / `web.dart` | Native TLS/proxy configuration / browser Fetch options |
| `resilience.dart` | Deadlines, retries, queue limits, circuit breaker, failover, hedging |
| `authentication.dart` | Origin-scoped bearer authentication and coordinated refresh |
| `caching.dart` | Bounded public-response cache and conditional validation |
| `diagnostics.dart` | Header redaction and request/header diagnostics |
| `sse.dart` | Event-stream parsing, last-event ID and bounded reconnects |
| `websocket.dart` | Reconnect orchestration and application heartbeat |
| `websocket_io.dart` / `websocket_web.dart` | Native / browser WebSocket connections |
| `sockets.dart` | Native TCP, TLS and UDP |
| `downloads.dart` / `cookies.dart` | Native resumable files / host-scoped cookie jar |
| `resources.dart` | Explicit refresh with cancellation of superseded reads |
| `testing.dart` | Fake transport and pending-request testing controller |

The optional [`flutter_client_widgets`](packages/flutter_client_widgets/README.md)
package provides a `ValueNotifier` adapter. The core imports no Flutter libraries
and has **zero third-party runtime dependencies**. Optional imports allow focused
APIs and tree shaking; they do not make pub download individual source files.

## Examples and guidance

- [Runnable examples](example/README.md): typed client, real local HTTP, policies,
  consumer tests, and Flutter UI.
- [Usage and policy ordering](doc/usage.md)
- [Migration from the existing ApiClient](doc/migration.md)
- [Platform support and limits](doc/platforms.md)
- [Architecture and folder responsibilities](doc/architecture.md)
- [Testing and release checks](doc/releasing.md)
- [Package and application size](doc/size.md)
- [.NET and Angular design mapping](doc/design_comparison.md)
- [Validation results](doc/validation.md) and [remaining release work](doc/implementation_plan.md)

## Develop

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test example tool
dart analyze lib test example tool
dart test
python3 tool/check_structure.py
dart run example/lib/main.dart
dart run example/lib/local_http.dart
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for one-type-per-file conventions.
See [LICENSE](LICENSE) for the MIT license.

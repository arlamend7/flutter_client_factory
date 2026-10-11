# flutter_client_factory

Dependency-free networking for Dart and Flutter: named and typed HTTP clients,
shared transport lifetimes, streaming bodies, and opt-in policies.

**Version 1.0.0.** MIT licensed. Requires Dart 3.4 or newer
(below Dart 4); older Flutter releases whose Dart SDK predates 3.4 cannot use it.
Repository: [arlamend7/flutter_client_factory](https://github.com/arlamend7/flutter_client_factory).

## Quick start

For this checkout, use a local path dependency. After 1.0.0 is published, use
`flutter_client_factory: ^1.0.0`:

```yaml
dependencies:
  flutter_client_factory:
    path: /path/to/flutter_client_factory
```

```dart
import 'package:flutter_client_factory/flutter_client_factory.dart';

Future<void> main() async {
  final factory = DefaultHttpClientFactory();
  factory.registerClient('api',
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      timeout: const Duration(seconds: 10));

  try {
    final response = await factory.create('api').getAsync('todos/1');
    await response.requireSuccess();
    print(await response.readText());
  } finally {
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
| `flutter_client_factory.dart` | HTTP models, bodies, events, factory, middleware, platform transport |
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

The optional [`flutter_client_factory_widgets`](packages/flutter_client_factory_widgets/README.md)
package provides a `ValueNotifier` adapter. The core imports no Flutter libraries
and has **zero third-party runtime dependencies**. Optional imports allow focused
APIs and tree shaking; they do not make pub download individual source files.

## Examples and guidance

Start with the [documentation learning path](doc/README.md), from one request
through tested application services to production policy composition.


- [Advanced use cases](doc/advanced.md)
- [Error handling and troubleshooting](doc/troubleshooting.md)
- [Runnable examples](example/README.md): typed client, real local HTTP, policies,
  consumer tests, and Flutter UI.
- [Request, response, form, testing, and timeout shortcuts](doc/conveniences.md)
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

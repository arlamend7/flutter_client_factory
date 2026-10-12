# Examples — 1.0.2

Run from the repository root after `dart pub get`:

| Command | Demonstrates |
| --- | --- |
| `dart run example/flutter_client_factory_example.dart` | Client registration with logging/headers/timeout, injected UserService, caller status validation, custom model and raw text |
| `dart run example/lib/main.dart` | Same default example through the conventional entry point |
| `dart run example/lib/typed_client.dart` | Typed service with deterministic fake transport |
| `dart run example/lib/local_http.dart` | Real loopback HTTP server, named client and JSON decoding |
| `dart run example/lib/resilient_request.dart` | Retry + deadline and response disposal without external services |
| `dart run example/lib/testing_client.dart` | Capture, inspect, flush and verify a consumer request |
| `dart run example/lib/authenticated_client.dart` | Retry, auth refresh, and timeout against a fake backend |
| `dart run example/lib/connections.dart` | Real local SSE and WebSocket connections |
| `dart run example/lib/download_file.dart URL OUTPUT_PATH` | Validator-based file resumption against your endpoint |

Start with `lib/main.dart`, then `local_http.dart`, `typed_client.dart`,
`testing_client.dart`, and `resilient_request.dart`. See the
[documentation learning path](../doc/README.md) for advanced composition.

The default example contacts the public JSONPlaceholder service and requires
internet access. The local HTTP/connection examples need permission to bind loopback sockets.
The download example contacts the URL you supply and writes the output path.
The typed, resilience and testing examples work offline. `lib/models`, `lib/services` and `lib/defaults` keep one type per file.
For browser integration see `tool/verify_browser.sh`. For Flutter see the separate
[adapter example](../packages/flutter_client_factory_widgets/example/README.md).


## Default example structure

1. Register `api` with `Accept: application/json`, a timeout, and
   `DiagnosticsInterceptor.intercept` for logging.
2. Inject `factory.create('api')` into [UserService](lib/services/user_service.dart).
3. Request a user and check `response.isSuccessful` at the calling boundary.
4. Return early on an unsuccessful status, releasing the unread response.
5. Decode with [ExampleUser.fromJson](lib/models/example_user.dart), or read a
   separate response with `readText()`.
6. Close clients/factory when their owning scope ends.

`UserService` also demonstrates query parameters, JSON POST/PUT, and optional
cancellation. It returns the public `HttpResponse`; it does not invent an ApiResult
wrapper. The [alternative typed service](lib/services/example_users_api.dart)
validates and decodes internally when that suits an application better.
The [sign-in recipe](../doc/application_services.md) uses the same separation for
an application-owned login endpoint.

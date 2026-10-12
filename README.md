# flutter_client_factory

Build reusable HTTP services for Dart and Flutter with named clients, shared
connections, explicit response handling, and composable interceptors. The pure
Dart core has **zero third-party runtime dependencies**. Version **1.0.2**, MIT.

## Contents

- [Install and compatibility](#install-and-compatibility)
- [Run the example](#run-the-example)
- [Quick start: configure a client](#quick-start-configure-a-client)
- [Inject the client into a service](#inject-the-client-into-a-service)
- [Application sign-in recipe](doc/application_services.md)
- [Validate HTTP responses](#validate-http-responses)
- [Parse JSON into your own model](#parse-json-into-your-own-model)
- [Read a response as text](#read-a-response-as-text)
- [Send JSON and use other HTTP verbs](#send-json-and-use-other-http-verbs)
- [Set headers and query parameters](#set-headers-and-query-parameters)
- [Configure timeouts and cancellation](#configure-timeouts-and-cancellation)
- [Log requests and compose interceptors](#log-requests-and-compose-interceptors)
- [Send forms and upload files](#send-forms-and-upload-files)
- [Test a service without networking](#test-a-service-without-networking)
- [Use the client in Flutter](#use-the-client-in-flutter)
- [Manage clients and response lifetimes](#manage-clients-and-response-lifetimes)
- [Choose optional networking features](#choose-optional-networking-features)
- [Limitations and troubleshooting](#limitations-and-troubleshooting)
- [Examples and guidance](#examples-and-guidance)

## Install and compatibility

```yaml
dependencies:
  flutter_client_factory: ^1.0.2
```

Use this constraint once 1.0.2 is published. To try this source checkout first,
replace the version with `path: /path/to/flutter_client_factory`.
Requires Dart **>=3.4.0 <4.0.0**, including Flutter versions that bundle a compatible
Dart SDK. No Flutter dependency is needed for the core. Browser HTTP uses Fetch;
native HTTP uses `dart:io`. See [platform support](doc/platforms.md).

## Run the example

```sh
dart pub get
dart run example/flutter_client_factory_example.dart
```

The example configures logging, a JSON Accept header and a ten-second timeout,
injects a client into a service, validates HTTP statuses, and reads both a custom
model and plain text. It contacts JSONPlaceholder, so it needs internet access.
Replace its base URL and relative paths with your API's routes.

Source files have separate responsibilities:

| File | Responsibility |
| --- | --- |
| [Example entry point](example/flutter_client_factory_example.dart) | Register the client, inject it, call the service, close the factory |
| [UserService](example/lib/services/user_service.dart) | Send requests; let callers validate and decode responses |
| [ExampleUser](example/lib/models/example_user.dart) | Validate and convert decoded JSON |
| [Service tests](test/example/user_service_test.dart) | Exercise success, HTTP errors, invalid payloads and cleanup without networking |

## Quick start: configure a client

```dart
import 'dart:developer' as developer;
import 'package:flutter_client_factory/diagnostics.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';

final factory = DefaultHttpClientFactory();
final logging = DiagnosticsInterceptor(
  (event) => developer.log('$event', name: 'http'),
);

factory.registerClient(
  'api',
  baseUrl: 'https://jsonplaceholder.typicode.com/',
  defaultHeaders: {'Accept': 'application/json'},
  timeout: const Duration(seconds: 10),
  interceptors: [logging.intercept],
);

final client = factory.create('api');
```

`DiagnosticsInterceptor` is the built-in logging interceptor. It is enabled in
this example, not globally enabled for every library user. Pass its `intercept`
method to the single interceptor list. The platform transport is selected for you.

Keep the factory at application or session scope. The remaining snippets assume
`factory` and `client` were created as above, and asynchronous snippets run in an
`async` function. Optional-feature snippets show the extra imports they need.

## Inject the client into a service

A thin service receives a client through a public named constructor parameter and
returns `Future<HttpResponse>`. The caller chooses error handling and decoding;
no application-specific result wrapper or serializer dependency is required.
Put the service and model in separate files:

```dart
import 'package:flutter_client_factory/flutter_client_factory.dart';
import '../models/example_user.dart';

/// Sends user requests; callers own response validation, decoding and cleanup.
class UserService {
  UserService({required HttpClient client}) : _client = client;

  final HttpClient _client;

  Future<HttpResponse> getUser(int id, {CancellationToken? cancellationToken}) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');
    return _client.getAsync('users/$id', cancellationToken: cancellationToken);
  }

  Future<HttpResponse> findUsers(String email,
          {CancellationToken? cancellationToken}) =>
      _client.getAsync('users',
          queryParameters: {'email': email},
          cancellationToken: cancellationToken);

  Future<HttpResponse> createUser(ExampleUser user,
          {CancellationToken? cancellationToken}) =>
      _client.postAsync('users',
          body: JsonRequestBody(user.toJson()),
          cancellationToken: cancellationToken);

  Future<HttpResponse> updateUser(ExampleUser user,
          {CancellationToken? cancellationToken}) =>
      _client.putAsync('users/${user.id}',
          body: JsonRequestBody(user.toJson()),
          cancellationToken: cancellationToken);
}
```

```dart
final users = UserService(client: client);
// Or: factory.createTyped('api', (client) => UserService(client: client));

final response = await users.getUser(1);
if (!response.isSuccessful) {
  await response.dispose();
  return; // Show an error or keep current application state.
}
final user = await response.readJson(decode: ExampleUser.fromJson);
// Store user or navigate only after successful validation and decoding.
print(user.name);
```

The [complete default example](example/flutter_client_factory_example.dart) includes
this calling code and a separate plain-text use case. For applications that prefer
services to return models and throw on HTTP errors, see the alternative
[ExampleUsersApi](example/lib/services/example_users_api.dart).

## Validate HTTP responses

`response.isSuccessful` is the existing success check: it is true for HTTP 200–299.
The property is named `isSuccessful`, not `isSuccess`. HTTP 400/404/500 responses do
not automatically throw; choose how your application handles them.

```dart
final response = await client.getAsync('users/1');
if (!response.isSuccessful) {
  final status = response.statusCode;
  await response.dispose(); // Release an unread error body.
  print('Request failed: HTTP $status');
  return;
}
final text = await response.readText();
print(text);
```

To handle an API's error message, read its body inside the failure branch instead
of disposing it unread. Readers release the response even when decoding fails.
When every non-2xx status should throw, use `await response.requireSuccess()`;
it disposes unsuccessful responses and throws `HttpStatusException` with metadata.

Network failures, cancellation and timeouts are exceptions, separate from HTTP
status responses. A service can propagate them to its UI/application boundary.

## Parse JSON into your own model

`readJson` parses JSON and calls your conversion function. No reflection or code
generation is needed. This model validates the shape before constructing a value:

```dart
class ExampleUser {
  const ExampleUser({required this.id, required this.name});

  factory ExampleUser.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected a user object.');
    }

    final Object? id = json['id'];
    final Object? name = json['name'];
    if (id is! int || name is! String) {
      throw const FormatException('Expected an integer id and a string name.');
    }

    return ExampleUser(id: id, name: name);
  }

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  final int id;
  final String name;
}
```

```dart
final response = await client.getAsync('users/1');
await response.requireSuccess();
final user = await response.readJson(decode: ExampleUser.fromJson);
print(user.name);
```

For lists, validate that the decoded value is a list, then map each item:

```dart
final response = await client.getAsync('users');
await response.requireSuccess();
final users = await response.readJson<List<ExampleUser>>(decode: (value) {
  if (value is! List) throw const FormatException('Expected a user list.');
  return value.map(ExampleUser.fromJson).toList();
});
```

## Read a response as text

```dart
final response = await client.getAsync('users/1');
await response.requireSuccess();
final String text = await response.readText();
```

This preserves the response as UTF-8 text, including JSON text if that is what
the server sends. It also works with plain-text endpoints. Use `readBytes()` for
binary data. A response body is read **once**: use a separate request for another
representation, or `buffer()` and `toResponse()` when repeated reading is needed.
Readers default to an 8 MiB limit; pass `maxBytes` or stream larger bodies.

## Send JSON and use other HTTP verbs

```dart
final response = await client.postAsync(
  'users',
  body: JsonRequestBody({'name': 'Ada'}),
);
await response.requireSuccess();
final created = await response.readJson(decode: ExampleUser.fromJson);
```

`JsonRequestBody` provides the JSON content type. `Accept` describes the response
you want; `Content-Type` describes the body you send.

| Method | Typical use |
| --- | --- |
| `getAsync` | Read a resource |
| `postAsync` | Create or submit |
| `putAsync` | Replace a resource |
| `patchAsync` | Partially update |
| `deleteAsync` | Remove a resource |
| `headAsync` | Read headers without a response body |
| `optionsAsync` | Ask about supported operations |

Each accepts a string URL and optional headers, query parameters, request body,
cancellation token and timeout. For a successful empty response such as 204 or
HEAD, dispose it instead of decoding JSON:

```dart
final response = await client.deleteAsync('users/1');
await response.requireSuccess();
await response.dispose();
```

## Set headers and query parameters

```dart
final response = await client.getAsync(
  'users',
  queryParameters: {'page': 1, 'role': ['admin', 'editor']},
  headers: {'Accept': 'application/json', 'X-Request-ID': 'request-123'},
);
await response.requireSuccess();
final text = await response.readText();
```

Request headers override registered defaults case-insensitively. Query values
support strings, numbers, booleans and repeated string values. With an `/api/`
base URL, `users` preserves that path; `/users` starts at the origin root.

Direct registration options and a configuration callback can be combined. The
callback runs last, once per registration, and the result is copied:

```dart
factory.registerClient(
  'reports',
  baseUrl: 'https://example.com/api/',
  defaultHeaders: {'Accept': 'application/json'},
  transportLifetime: const Duration(minutes: 5),
  configure: (client) {
    client.defaultHeaders['X-App-Version'] = '1.0.2';
  },
);
```

## Configure timeouts and cancellation

The registered timeout covers the operation through consuming/discarding the body,
including middleware and retries. Override it for one request:

```dart
final response = await client.getAsync(
  'users/1',
  timeout: const Duration(seconds: 3),
);
await response.requireSuccess();
final user = await response.readJson(decode: ExampleUser.fromJson);
```

For cancellation, retain a token at the owning scope and cancel when work becomes
unnecessary (for example when a screen closes):

```dart
final token = CancellationToken();
final pending = client.getAsync('users/1', cancellationToken: token);
// The owning scope may call token.cancel('Screen closed') while pending.
try {
  final response = await pending;
  await response.requireSuccess();
  final text = await response.readText();
} finally {
  token.dispose();
}
```

Disposing a token detaches links; cancellation is explicit. For a deadline at a
specific interceptor position, use `TimeoutInterceptor` from `resilience.dart`.
An explicit timeout interceptor is independent of client/request timeouts;
the earliest deadline wins. See [timeout semantics](doc/conveniences.md#client-setup-and-overall-timeouts).

## Log requests and compose interceptors

```dart
import 'package:flutter_client_factory/diagnostics.dart';
import 'package:flutter_client_factory/resilience.dart';

final logging = DiagnosticsInterceptor((event) {
  developer.log('$event', name: 'http');
});
factory.registerClient(
  'resilient-api',
  baseUrl: 'https://example.com/api/',
  defaultHeaders: {'Accept': 'application/json'},
  timeout: const Duration(seconds: 10),
  interceptors: [
    RetryInterceptor().intercept,
    logging.intercept, // Log each send, including retries.
  ],
);
```

There is **one interceptor list**, evaluated in registration order; responses
unwind in reverse order. Retry/auth interceptors repeat only what follows them.
Put logging before retry to observe a logical operation, or after retry to observe
each attempt. Retrying writes or one-shot uploads requires an explicit safe policy.

Diagnostics logs the method, origin/path, redacted request headers, status and time
until headers arrive. It does not log body/query contents or full download duration.
Default redaction covers authorization and cookie headers; URL paths may still
contain application-sensitive data. A custom `HeaderRedactor` replaces the default
sensitive-name set, so include the defaults when adding your own secret headers.

A custom interceptor is just a function; no extra interceptor type is required:

```dart
Future<HttpResponse> addAppHeader(
  HttpRequest request,
  CancellationToken token,
  HttpRequestHandler next,
) {
  return next(request.withHeader('X-App', 'my-app'), token);
}
// Register with interceptors: [addAppHeader, logging.intercept].
```

## Send forms and upload files

URL-encoded form:

```dart
final response = await client.postAsync(
  'preferences',
  body: FormRequestBody.single({'language': 'en'}),
);
await response.requireSuccess();
await response.dispose();
```

Multipart fields and in-memory file bytes:

```dart
final response = await client.postAsync(
  'uploads',
  body: FormData(
    fields: {'description': 'Example file'},
    files: [MultipartPart.bytes(name: 'file', bytes: [72, 105], filename: 'hello.txt')],
  ),
);
await response.requireSuccess();
await response.dispose();
```

The body sets its multipart boundary; do not supply a manual multipart content-type.
For streamed native files, import `dart:io` and the package's `io.dart`, then use
`File(...).asMultipartPart(...)`. See [file upload/download recipes](doc/conveniences.md).

## Test a service without networking

Use the same service with a captured-request client. No HTTP server or mocking
framework is needed:

```dart
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';

final testing = HttpTestingController();
final client = testing.createClient(
  baseUrl: 'https://example.test/',
  defaultHeaders: {'Accept': 'application/json'},
);
final users = UserService(client: client);
try {
  final pending = users.getUser(1);
  final request = await testing.waitForOne('https://example.test/users/1');
  request.flushJson({'id': 1, 'name': 'Ada'});
  final response = await pending;
  expect(response.isSuccessful, isTrue);
  final user = await response.readJson(decode: ExampleUser.fromJson);
  expect(user.name, 'Ada');
  testing.verify();
} finally {
  client.dispose();
  await testing.close();
}
```

Use `flushText`, `flushJson(..., statusCode: 404)`, or `fail(error)` for other
outcomes. Attach error expectations before flushing failures. See the
[service regression tests](test/example/user_service_test.dart) and
[testing guide](doc/testing.md) for cleanup, invalid payloads and timeout coverage.

## Use the client in Flutter

Create the factory and services in your app's composition root and inject the
service into the widget/state layer. Do not register clients or send requests in
`build()`. A FutureBuilder can display a service Future captured in `initState`.

For explicit refresh/loading/error state, the optional
[flutter_client_factory_widgets](packages/flutter_client_factory_widgets/README.md)
package supplies `HttpResourceNotifier`. It supports cancellation of superseded
reads and `ValueListenableBuilder` rendering. See its
[runnable Flutter example](packages/flutter_client_factory_widgets/example/README.md).

## Manage clients and response lifetimes

| Object | Ownership rule |
| --- | --- |
| Factory | Close when the application/session scope ends; it owns transports |
| Logical client | `dispose()` when its owner releases it; shared connections stay open |
| Response | Read or dispose every body, including error responses |
| Injected service | Dispose the client only if the service owns that client |
| Flutter notifier | Dispose when its widget/scope ends; it does not own the factory |

The command-line example closes everything in `finally`. In a running app, keep
the factory and service alive across requests. Use `response.use(...)` to guarantee
cleanup around custom response processing; do not return a live stream from it.

## Choose optional networking features

| Import suffix | Use case / guide |
| --- | --- |
| `flutter_client_factory.dart` | Core requests, bodies, factory, platform transport |
| `diagnostics.dart` | Logging and header redaction, as above |
| `resilience.dart` | [Retry, timeouts, circuit breaker, queues, routing](doc/usage.md) |
| `authentication.dart` | [Bearer tokens and coordinated refresh](doc/advanced.md#authentication-and-retries) |
| `caching.dart` | [Bounded cache and session boundaries](doc/advanced.md#cache-and-session-boundaries) |
| `io.dart` / `web.dart` | [TLS/proxy and Fetch configuration](doc/platforms.md) |
| `downloads.dart` / `cookies.dart` | [Native resumable downloads and cookies](doc/usage.md) |
| `sse.dart` | [Server-sent events](doc/advanced.md#persistent-connections) |
| `websocket.dart`, `websocket_io.dart`, `websocket_web.dart` | [WebSocket connection/reconnect](doc/advanced.md#persistent-connections) |
| `sockets.dart` | [Native TCP/TLS/UDP](doc/platforms.md) |
| `resources.dart` | [Refreshable application state](doc/usage.md) |
| `testing.dart` | [Deterministic service tests](doc/testing.md) |

Optional imports keep APIs focused and support tree shaking. Pub still downloads
the package archive as a whole; see [size measurements](doc/size.md).

## Limitations and troubleshooting

- Browser networking follows CORS and browser-controlled headers, cookies and pooling.
- HTTP failure statuses are responses until your code rejects them.
- Empty bodies (204/HEAD) are not JSON; body streams are consumed once.
- SDK support starts at Dart 3.4; this package cannot run on every historic Flutter version.
- Tests and pub points are evidence for specific checks, not universal server/device support.

See [troubleshooting](doc/troubleshooting.md), [platform limits](doc/platforms.md),
and [validation history](doc/validation.md).

## Examples and guidance

- [Runnable example catalogue](example/README.md)
- [Documentation learning path](doc/README.md)
- [Advanced composition](doc/advanced.md) and [API conveniences](doc/conveniences.md)
- [Migration](doc/migration.md) and [.NET/Angular comparison](doc/design_comparison.md)
- [Architecture](doc/architecture.md), [contributing](CONTRIBUTING.md), and [release setup](doc/releasing.md)
- [Source repository](https://github.com/arlamend7/flutter_client_factory) and [MIT license](LICENSE)

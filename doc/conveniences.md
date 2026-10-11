# Convenience APIs

All examples use the same generic interceptor pipeline. No runtime dependencies,
reflection, generated clients, singleton, or extra interceptor categories are added.
Core conveniences are exported by `flutter_client_factory.dart`.

## Client setup and overall timeouts

```dart
final factory = DefaultHttpClientFactory();
factory.registerClient(
  'api',
  baseUrl: 'https://example.com/api/',
  defaultHeaders: {'Accept': 'application/json'},
  timeout: const Duration(seconds: 30),
  configure: (client) {
    client.defaultHeaders['X-App-Version'] = '1.0';
  },
);
final client = factory.create('api');
```

All settings are optional except the registration name. `configure` runs once after
named settings, before validation and snapshotting. The application/session owns
this factory and awaits `factory.close()` when that scope ends. Borrowing screens
must not close a shared factory. Disposing a client only blocks that wrapper's new
requests; cancellation tokens stop active work. Always consume or dispose responses.

`timeout` is a positive overall deadline: it covers middleware, queues, retry
backoff, sending, and consuming the response body. It uses linked cancellation,
not merely a Future wait timeout. A request's non-null timeout overrides the client
default; null inherits it. With neither set there is no overall deadline, though
transport-specific idle/connect limits can still apply. Timers are released when
the body is consumed/disposed or the operation fails. A response that arrives after
timing out is disposed. Custom transports must honor cancellation for actual I/O
abortion; custom HttpClient implementations must enforce HttpRequest.timeout.

`TimeoutInterceptor` remains available for policies at a particular pipeline
position, including fresh deadlines after retry/authentication. An explicit
interceptor is independent of the convenience timeout: whichever deadline expires
first wins. A request override does not disable such middleware.

## Requests and immutable transformations

```dart
final response = await client.getAsync(
  'users',
  queryParameters: {'page': 1, 'role': ['admin', 'editor']},
  headers: {'Accept': 'application/json'},
  timeout: const Duration(seconds: 5),
  cancellationToken: token,
);
```

Available verbs: `getAsync`, `postAsync`, `putAsync`, `patchAsync`, `deleteAsync`,
`headAsync`, and `optionsAsync`. Each supports a string URL, headers, query
parameters, body, request context, cancellation token, and timeout. Relative URLs
use the configured base URI: `users` preserves an `/api/` base path, while `/users`
starts at the origin root. Supplied query keys replace existing values; other keys
and repeated values survive. Values accept strings, numbers, booleans, or an
Iterable<String>. Null or an empty iterable removes a key. Unsupported values fail
instead of being implicitly serialized. Request headers override client defaults
case-insensitively. Use `send(HttpRequest(...))` for multivalue headers and Uri inputs.

Interceptors can transform requests without changing the original:

```dart
return next(
  request.withHeader('Authorization', 'Bearer $token')
      .withoutHeader('X-Unneeded')
      .withQueryParameters({'language': 'en'}),
  cancellationToken,
);
```

The transformations preserve body, context, method, and timeout. Retry safety and
one-shot request bodies still apply. HTTP status errors are not automatically thrown.

## Reading and owning responses

```dart
await response.requireSuccess();
final user = await response.readJson(decode: User.fromJson);
```

`readBytes`, `readText`, `readJson`, and `buffer` accept `maxBytes` (default 8 MiB).
They consume the body and dispose it even if size validation, decoding, or the
custom decoder fails. JSON uses an explicit decoder; empty 204/HEAD bodies are not
JSON and should instead be disposed or handled explicitly. `requireSuccess()`
returns the same response for 2xx, or disposes it and throws `HttpStatusException`
with status, headers, and URI. It does not buffer the error body. Read the response
yourself when an API's error payload matters.

A body may be consumed once. `buffer()` returns a reusable snapshot whose
`toResponse()` creates a fresh consumable response. Stream large responses directly.
For custom processing, `response.use((response) async { ... })` guarantees disposal
when the callback finishes or throws. Do not return a live response stream from it.

## JSON, forms, and file uploads

```dart
final response = await client.postAsync('users',
  body: JsonRequestBody({'name': 'Ada'}));
await response.dispose();

final form = FormData(
  fields: {'name': 'Ada'},
  files: [MultipartPart.bytes(name: 'avatar', filename: 'avatar.png',
    bytes: avatarBytes, contentType: 'image/png')],
  parts: [MultipartPart.text(name: 'tag', value: 'one'),
          MultipartPart.text(name: 'tag', value: 'two')],
);
```

`FormData` uses the existing multipart encoder and generated boundary; do not set a
conflicting Content-Type yourself. Parts determine replayability and content length.
For URL-encoded forms use `FormRequestBody.single({'name': 'Ada'})`; its original
constructor supports repeated values. `HttpHeaders.single` converts simple maps
when constructing advanced requests/responses directly.

Import `io.dart` for a streaming native file part:

```dart
final part = await file.asMultipartPart(name: 'upload', contentType: 'text/plain');
final response = await client.postAsync('upload', body: FormData(files: [part]));
await response.dispose();
```

Keep the file stable during upload. File parts are one-shot and do not automatically
retry. Browser multipart uploads retain the browser transport's known-length and
buffering limits; native filesystem access is not exported to browsers.

## Testing without a server

Import `testing.dart` alongside the core. Its helpers do not depend on package:test.

```dart
final controller = HttpTestingController();
final client = controller.createClient(baseUrl: 'https://test.invalid/');
try {
  final pending = client.getAsync('users');
  final request = await controller.waitForOne(
    'https://test.invalid/users', method: HttpMethod.get);
  request.flushJson([{'name': 'Ada'}]);
  final response = await pending;
  final users = await response.readJson(decode: (json) => json);
  controller.verify();
} finally {
  client.dispose();
  await controller.close();
}
```

`expectOne(url, method: ...)` matches requests already captured. `waitForOne` waits
for asynchronous middleware without polling; its timeout defaults to five seconds.
Both use full URLs including query strings. `expectOneWhere` and `waitForOneWhere`
accept predicates. A match reserves a request; flush/fail it, await the work, then
verify. Duplicate matches fail without reserving candidates. `match` supports
intentional batches. Waiting on a closed controller fails; all wait timers and
subscriptions are released. Failure messages list actual outstanding requests.

`flushJson` and `flushText` default to HTTP 200 with the appropriate UTF-8 content
type; named statusCode and headers override these defaults. `flush` still accepts
streamed responses, and `fail` simulates network/other exceptions. Use a non-2xx
flush to test server errors. Always verify before close so cleanup does not mask
unhandled requests; use ignoreCanceled only when cancellation is expected.

## Optional features

- `downloads.dart`: `client.downloadFile(absoluteUrl, destinationFile,
  cancellationToken: token)` delegates to validator-based resumable downloads.
  One caller may own a destination at a time. It is native-only.
- `sse.dart`: `client.serverSentEvents(url, cancellationToken: token,
  maxReconnects: 3, reconnectDelay: duration)` returns the existing event stream.
  Cancel the token to interrupt a stalled connection. A client default timeout
  applies to each HTTP connection; retries/reconnects do not imply an unlimited
  overall subscription lifetime.
- `flutter_client_factory_widgets`: `HttpResourceNotifier<T>.fromLoader(loader)`
  constructs and owns a resource; call refresh to start. Disposal cancels loading.
  It never takes ownership of an injected HTTP client or factory.
- WebSockets retain their separate connection lifecycle. They do not silently
  inherit HTTP interceptors, HTTP timeouts, or HTTP base URLs.

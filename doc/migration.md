# Migrating the Kap Games ApiClient

This mapping is based on the existing `lib/packages/api` implementation, which
currently uses `package:http`, a shared factory, single-value query maps, cancellation
flag checks, and an `ApiResult` hierarchy. The original application is not modified.

| Existing concept | Replacement |
| --- | --- |
| ApiClientFactory singleton | Application/session-owned DefaultHttpClientFactory |
| ApiClientConfiguration | HttpClientOptions + ClientRegistration |
| ApiRequest path/query | HttpRequest with Uri; use list-valued queryParameters |
| ApiMethod | HttpMethod |
| Map<String, String> headers | HttpHeaders with case-insensitive multivalue lookup |
| Object body type guessing | Explicit Json/Text/Byte/Form/Multipart/StreamRequestBody |
| CancelToken flag | CancellationToken notifications connected to active I/O |
| ApiInterceptor class | HttpMiddleware.intercept or HttpInterceptor function |
| ApiResponse bodyBytes | Streaming HttpResponse + bounded ResponseBodyReader |
| ApiFailure / ApiCanceled | NetworkException / RequestCanceledException / timeout |
| client.close closes shared HTTP client | client.dispose only retires the wrapper |
| factory.close | await factory.close to drain owned transport lifetimes |

For repeated query values, construct a URI explicitly:

```dart
final request = HttpRequest(uri: Uri(path: 'users', queryParameters: {
  'role': ['admin', 'editor'],
}));
```

Replace `send<T>` calls that merely assert a generic result type with a real domain
converter. `example/lib/services/example_users_api.dart` uses
`ResponseBodyReader.readJson(response, ExampleUser.fromJson)` and validates the
response status before decoding. It disposes unsuccessful responses immediately.

The error contract changes deliberately: 4xx/5xx remain inspectable HTTP responses;
network/cancellation/decode failures throw. If existing presentation code needs
`ApiResult`, implement that mapping in the application's typed service boundary.
Keep original causes and stack traces rather than reducing them to a message string.

Move a timeout value into a TimeoutInterceptor. Place it outside retries for a total
budget or after the retry interceptor for a fresh budget per attempt. Keep separate
factories/coordinators/cookie jars for unrelated authenticated sessions. Test the
migrated service with HttpTestingController before replacing production call sites.

## Consolidating the preview interceptor configuration

`HttpClientOptions.attemptInterceptors` has been removed. There is now one
`interceptors` list with the same generic `HttpInterceptor` contract. Append the
former attempt list after the existing interceptors, preserving both lists' order:

```dart
HttpClientOptions(
  interceptors: [
    overall.intercept,
    retry.intercept,
    authentication.intercept,
    attempt.intercept,
    logging.intercept,
  ],
);
```

Retry and authentication refresh repeat only what follows them. In this example,
the attempt timeout and logging run on every send, including authentication replay.
The overall policy runs around the whole operation. No separate interceptor types,
execution modes, or second configuration list are required.

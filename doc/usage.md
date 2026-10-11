# Usage and lifecycle

See [convenience APIs](conveniences.md) for request verbs, responses, forms,
testing, timeouts, and optional feature shortcuts.

## Register with named options

```dart
factory.registerClient(
  'api',
  baseUrl: 'https://example.com/api/',
  defaultHeaders: {'Accept': 'application/json'},
  interceptors: [authentication.intercept, logging.intercept],
  transportLifetime: const Duration(minutes: 5),
  configure: (client) {
    client.defaultHeaders['X-App-Version'] = appVersion;
    // All named settings are also available here for further customization.
  },
);
```

All arguments except the name are optional. `createTransport` defaults to the
platform transport and is not called until the first send. `timeout` sets an
overall request deadline, including retries and response-body consumption. Supply a builder for
tests or custom platform settings. `onEvent` is available both as a named argument
and on the callback builder. Base URLs must be absolute HTTP(S) URLs without
embedded credentials; omit the base URL when every request has an absolute URI.

Named arguments initialize the builder, then `configure` runs synchronously once
before the registration is validated and saved. Callback assignments override
named values. Header names are case-insensitive. Adding interceptors appends to the
supplied list; call `client.interceptors.clear()` first to replace it. Input maps
and lists are copied, and later builder mutations do not affect registered clients.
Stateful interceptor instances still have the owners you supplied. A failing
callback or invalid configuration leaves no partial registration.

The existing `register(name, ClientRegistration(...))` API remains available for
advanced configuration, including `Uri` values and multivalue `HttpHeaders`.

## Compose policies deliberately

```dart
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';

final factory = DefaultHttpClientFactory();
final overall = TimeoutInterceptor(const Duration(seconds: 20));
final retry = RetryInterceptor();
final concurrency = ConcurrencyInterceptor(maxConcurrent: 4, maxQueued: 30);
final attempt = TimeoutInterceptor(const Duration(seconds: 5), phase: 'attempt');
factory.registerClient(
  'api',
  baseUrl: 'https://api.example.com/v1/',
  interceptors: [
    overall.intercept,
    concurrency.intercept,
    retry.intercept,
    attempt.intercept,
  ],
);
```

There is one ordered `interceptors` list. The first interceptor is outermost;
responses unwind in reverse order. Calling `next` again repeats only the remaining
interceptors. An operation deadline before retry includes backoff and all attempts.
A timeout after retry resets for each retry attempt. To run a policy on every
transport send, put it after all retry, auth refresh, failover and hedging policies.
An interceptor that returns a cached or synthetic response skips everything after
it, including the transport. Both timeout placements cover body
consumption. Queues and circuit breakers are stateful: reuse the intended instance.
A permit covers the response lifetime, so unread responses can exhaust concurrency.
Retries dispose failed responses before another attempt and respect replayability.
GET/HEAD/OPTIONS are the default retry methods; enabling write replay is a business
policy and needs idempotency support from the server. Hedging duplicates only
bodyless GET/HEAD requests to the original URI; its first response wins, including
an error status. Failover strips sensitive headers on origin changes. Combining
retry, auth refresh, failover and hedging multiplies possible sends; set a total
deadline and conservative budgets.

## Cancellation and streams

Pass a `CancellationToken` to `client.send`, and call `cancel()` when work becomes
obsolete. Cancellation remains connected while the response body is open. Consume
`response.body`, use `ResponseBodyReader`, or call `await response.dispose()`.
Do not listen twice. A body stream error is terminal and does not restart the
request. Observers and cancellation callbacks should be lightweight and must not
throw. Observer failures are propagated; events do not trigger extra requests.
Upload progress measures bytes handed to the transport, not peer acknowledgment.

Use `ByteRequestBody`, `TextRequestBody`, `JsonRequestBody`, `FormRequestBody` or
`MultipartRequestBody`. `StreamRequestBody` is one-shot by default; use its replayable
constructor only when each invocation can produce equivalent bytes. Multipart
parts also retain their bodies' replayability. Native uploads stream; browser
uploads require a known length and are buffered within `maxUploadBytes`.

## Authentication, cookies and cache

Implement `TokenProvider`, and create a `TokenRefreshCoordinator` per signed-in
session. Add `AuthenticationInterceptor` with explicit allowed origins. Concurrent
401s share one refresh; canceling one waiter does not cancel another. Dispose the
coordinator on sign-out. Credentials and refresh requests must not recurse through
the same auth middleware. Place cache after authentication so credentialed requests
bypass it. Native redirects strip authorization and cookies across origins; disable
redirects when each hop must pass middleware or update the cookie jar.

`MemoryCacheStore` is bounded in entries and bytes. `CacheInterceptor` handles public
GET responses, max-age, age/date, Vary and validators. It skips credentialed/cookie
requests, private/no-store responses, Set-Cookie, unknown-size and oversized bodies.
It is a conservative subset of HTTP caching: no persistent storage, stale-while-
revalidate, or automatic cross-resource mutation invalidation. Use `CacheStore` to
supply persistence and invalidate related URLs explicitly.

`CookieJar` is native-only and host-scoped; it rejects parent-domain cookies rather
than shipping a public-suffix database. It is not a browser security-policy engine.
Browsers manage cookies, CORS and forbidden headers themselves.

## Long-lived protocols

`ServerSentEventsClient` reconnects a bounded number of times with last-event IDs
and server retry hints. Cancel its token when disposing the consumer. A 204 stops
reconnection. `ReconnectingWebSocket.start()` runs until the connection loop ends;
subscribe to `messages` first and dispose the service when done. Heartbeats use
application messages (`ping`/`pong` by default), so the server must support them.
Messages are never implicitly replayed. Native WebSockets also support SDK ping
frames. TCP, TLS and UDP are separate native contracts; they are not HTTP requests.

`ResumableDownloader` stores sibling `.part`/`.part.json` files and resumes only
with a strong ETag and consistent Content-Range. Give one caller exclusive ownership
of a destination. Server 200 responses restart the file; invalid ranges fail without
promoting the partial file to the completed destination.

## Resources and Flutter

`HttpResource<T>` stores loading/data/error state. Refresh cancels the prior read
and rejects its late results. It does not track dependencies automatically; refresh
explicitly when inputs change. The separate Flutter adapter exposes this state as a
`ValueNotifier`. Dispose the notifier, logical client, and application-owned factory
at their corresponding lifecycle boundaries.

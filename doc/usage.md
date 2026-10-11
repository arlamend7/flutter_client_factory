# Usage and lifecycle

## Compose policies deliberately

```dart
import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/resilience.dart';

final factory = DefaultHttpClientFactory();
final overall = TimeoutInterceptor(const Duration(seconds: 20));
final retry = RetryInterceptor();
final concurrency = ConcurrencyInterceptor(maxConcurrent: 4, maxQueued: 30);
final attempt = TimeoutInterceptor(const Duration(seconds: 5), phase: 'attempt');
factory.register('api', ClientRegistration(
  createTransport: createPlatformTransport,
  options: HttpClientOptions(
    baseUri: Uri.parse('https://api.example.com/v1/'),
    interceptors: [overall.intercept, concurrency.intercept, retry.intercept],
    attemptInterceptors: [attempt.intercept],
  ),
));
```

The first interceptor is outermost. An operation deadline outside retry includes
backoff and all attempts. An attempt timeout resets per dispatch. Both cover body
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

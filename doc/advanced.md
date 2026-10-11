# Advanced application composition

Start with the [simple example](../example/lib/main.dart). Add policies only when
the application's requirements justify them; all examples retain one generic
interceptor pipeline and explicit ownership.

## Typed services and ownership

Register API configuration once at the application/session boundary, then inject
`factory.createTyped('api', UsersApi.new)` into consumers. Typed services validate
inputs, inspect HTTP statuses, and decode domain models. See the runnable
[typed example](../example/lib/typed_client.dart). The owner closes the factory;
borrowers must not close shared transports. Consume or dispose each response.

Do not create a factory for each request or in a widget build method. A logical
client can be retained within its scope: this factory selects the current transport
lease on every dispatch, even for existing client wrappers. Its rotation behavior
therefore differs from .NET clients bound to a handler at creation time.

## Authentication and retries

The [authenticated example](../example/lib/authenticated_client.dart) combines a
client deadline, retry, token refresh, and a deterministic testing backend. It sends
503, then 401, then 200 so each stage is visible without external credentials.

```dart
factory.registerClient('api',
  baseUrl: 'https://example.com/',
  timeout: const Duration(seconds: 20),
  interceptors: [
    retry.intercept,
    authentication.intercept,
    logging.intercept,
  ],
);
```

Policies before a resender surround its work; policies after it run on each resend.
Here logging observes both retry and auth refresh sends. Reversing retry and auth
changes the resend budget. Combine them deliberately and use an overall deadline.
Retry defaults to safe methods and replayable bodies. Retrying writes requires both
explicit opt-in and an application/server idempotency strategy.

Implement `TokenProvider` using your credential store. Share a
`TokenRefreshCoordinator` only within the intended signed-in session, configure
allowed origins, and dispose the coordinator at sign-out. Refresh requests must use
a separate unauthenticated path to avoid recursion. Never snapshot expiring tokens
as global default headers. The sample's fixed strings are demonstration tokens only.

## Cache and session boundaries

Use a bounded `MemoryCacheStore`; cache is an explicit interceptor, not a default.
Place it after authentication so credentialed requests bypass shared caching.
Private/no-store responses, cookies, unknown-size bodies, and oversized responses
are excluded. The implementation supports a conservative HTTP caching subset;
no persistence or cross-resource invalidation is implied. Invalidate related data
in the application's write workflows. Keep credential, cookie, and cache ownership
separate between unrelated users.

Concurrency permits cover response lifetimes. An unread response can exhaust a
queue; dispose it even for unsuccessful status codes. Put concurrency outside retry
when one permit should cover the entire operation. Place circuit breaking according
to whether failures should count individual attempts or overall operations.

## Transport configuration and credentials

Use `createTransport` for `IoHttpTransport(options: ...)` or `WebHttpTransport(...)`
from their focused imports. Each builder invocation must create an independently
owned transport. Native options include TLS trust/client certificates and proxies;
browsers control connection pooling, CORS, cookies, and forbidden headers.

Native redirects strip sensitive headers across origins. Disable automatic
redirects when each hop must pass your middleware. Browser redirects are constrained
by Fetch and cannot expose all redirect details. Keep certificate validation enabled.
The native cookie jar is deliberately host-scoped; it is not a full browser cookie
engine. See [platform limitations](platforms.md) before designing browser parity.

## Streaming and files

Use `response.body` for large responses and cancel/dispose it at the owning boundary.
Bounded readers default to 8 MiB. Multipart boundaries are generated automatically;
manual Content-Type overrides can break server decoding. Native file parts stream
and are one-shot so retries cannot silently reread a changing file. Browser uploads
require known lengths and stay within the configured upload buffer limit.

Downloads require a single writer per destination. Resume checkpoints use validators
and Content-Range checks; they do not make arbitrary server content trustworthy.
Cancel through the supplied token, and protect application-selected destinations.

## Persistent connections

SSE has its own reconnect budget and last-event ID handling. Cancel its token to
interrupt a stalled connection. A client deadline applies to each HTTP connection;
it is not an automatic infinite subscription or reconnect policy for every error.
WebSockets own their connection lifecycle separately; HTTP middleware and deadlines
do not implicitly apply. Subscribe before starting reconnection, observe errors,
and dispose the service. Heartbeats require server support. Messages are not
implicitly replayed after disconnect. TCP/TLS/UDP remain native-only APIs.

## Flutter resources

`HttpResourceNotifier.fromLoader` creates an owned core resource with explicit
refresh. Pass its cancellation token through every HTTP call. Refresh cancels an
older load and ignores stale completion. Dispose the notifier when its UI owner
ends; it does not own an injected client/factory. Loading state can retain previous
data, and errors include a stack trace. See the [Flutter example](../packages/flutter_client_factory_widgets/example/README.md).

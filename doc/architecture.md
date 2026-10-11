# Architecture

The core is a pure Dart package. Transports own platform networking; HTTP models
and middleware are portable. Persistent protocols have their own lifecycles.
There is no singleton, mandatory dependency injection container, reflection,
code generation, plugin registration, or third-party runtime dependency.

## Contexts

```text
lib/
  flutter_client.dart       core HTTP/factory public API and conditional transport
  <feature>.dart            focused, optional public entry points
  src/
    core/                   cancellation, errors, typed local request context
    http/                   bodies, models, events, middleware, bounded readers
    factory/                registration, borrowed clients, transport leases
    transports/             contracts, io, web interop, platform selection
    authentication/         token provider, refresh coordination, auth middleware
    resilience/             timeouts, retry, concurrency, circuit breaker, routing
    caching/                store contract, LRU implementation, HTTP validation
    diagnostics/            redaction and observations
    downloads/io/           validator-based file resumption
    cookies/io/             deliberately host-scoped cookie storage
    server_sent_events/     parser and reconnecting HTTP consumer
    websocket/              contracts, native/browser adapters, reconnect service
    sockets/io/             TCP, TLS and UDP adapters
    resources/              current loading/data/error state and refresh lifecycle
    testing/                fake transport and captured-request control
packages/flutter_client_widgets/
  lib/src/resources/services/   optional Flutter ValueNotifier bridge
example/lib/                runnable composition roots, models, typed services
```

Within each context: `contracts` defines boundaries, `models` holds data,
`configuration` validates options, `services` orchestrates state, `middleware`
composes requests, `helpers` performs deterministic feature-specific work, and
`defaults` holds built-in policies. Sample configuration belongs in `example`.
Every class, enum, extension type and typedef lives in its own named file.
`tool/check_structure.py` verifies this convention. No generic utilities bucket.

## Request flow

1. A named registration describes options and how to create an owned transport.
2. Logical clients retain the registration's options snapshot.
3. The client resolves relative URIs and merges headers, then executes operation
   interceptors in registration order. Responses unwind in reverse order.
4. Retry/auth/routing middleware can dispatch additional attempts. Each dispatch
   runs `attemptInterceptors`, then optional events, then the transport lease.
5. The factory lazily creates a transport and rotates it on a subsequent dispatch
   after its configured lifetime. Even existing logical clients use the new lease.
6. A lease remains active until its response body is consumed or disposed. Retired
   leases drain up to the factory grace period, then invoke transport shutdown.
7. Client disposal blocks new sends. Factory shutdown owns transport closure.

Factory grace and native shutdown timeout are separate stages, so total shutdown
can include both. Browser connection pooling and DNS decisions belong to the
browser; native transport rotation does not promise immediate operating-system
DNS cache refresh. Registration builders must return independently owned objects.
Direct `HttpClientService` users close their transport themselves.

## Ownership and memory

Requests/headers are immutable snapshots. Bodies explicitly advertise replayability.
Responses have a single-consumption managed stream with cleanup before or after
subscription. Buffering uses compact typed bytes and a size limit. Retrying after
partially delivering a response body is intentionally unsupported.

Caches, credentials, cookie jars, circuit breakers and queues have explicit owners;
share them only across the intended users/requests. The Flutter package depends on
the core, never the reverse. Native-only and browser-only APIs stay behind their
own imports. Browser interop uses SDK `dart:js_interop`, not `dart:html`.

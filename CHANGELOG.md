# Changelog

## 1.0.0

Initial stable-version API for the dependency-free Dart networking core.

- Named and typed clients with lazy shared transports, lifetime rotation, explicit
  ownership, and `registerClient` named settings plus a configuration callback.
- Native HTTP and browser Fetch with streamed responses and cancellation.
- String-URL HTTP verbs, repeated query values, immutable header/request helpers,
  bounded JSON/text/byte readers, status exceptions, and scoped response disposal.
- One ordered interceptor pipeline with optional retry, timeout, concurrency,
  circuit breaker, failover, hedging, authentication refresh, cache, and diagnostics.
- Client and request timeouts cover middleware, retries, and response consumption.
- JSON, URL-encoded forms, multipart fields/files, native streaming file parts,
  and explicit request-body replayability.
- Request-testing controller with method/predicate matching, bounded asynchronous
  waits, JSON/text flushing, and verification diagnostics.
- Native resumable downloads, host-scoped cookies, TCP/TLS/UDP, SSE, WebSockets,
  reconnect policies, and resource state APIs through focused optional imports.
- Simple default example, progressive use-case guides, runnable examples,
  automated validation, MIT license, and GitHub contribution templates.

### Migration from development snapshots

- Import `package:flutter_client_factory/flutter_client_factory.dart`.
- Replace `attemptInterceptors` with entries appended to `interceptors`; ordering
  determines which policies repeat on retry/authentication replay.
- The optional Flutter adapter is `flutter_client_factory_widgets` 1.0.0.
- Requires Dart >=3.4.0 <4.0.0. Platform-specific restrictions and tested environments
  are listed in `doc/platforms.md` and `doc/validation.md`.

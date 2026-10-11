# Design influences

| Source idea | Package equivalent | Deliberate boundary |
| --- | --- | --- |
| .NET named/typed clients | DefaultHttpClientFactory, createTyped | Constructor injection; no container required |
| .NET handler reuse/lifetime | Lazy shared transport leases and retirement | Pool mechanics are owned by each SDK transport |
| .NET outgoing handlers | Ordered operation/attempt interceptors | Plain Dart functions and interfaces |
| .NET logging/resilience composition | Diagnostics and optional resilience imports | No mandatory logging or policy framework |
| Angular immutable requests/context | HttpRequest.copyWith, HttpHeaders, typed RequestContext | Body replayability is explicit |
| Angular functional interceptors | HttpInterceptor / HttpMiddleware | Future and Stream semantics |
| Angular HTTP testing controller | expectOne, flush, fail, verify | No live server required for consumer tests |
| Angular progress/resource patterns | HttpEvent, HttpResource, Flutter notifier | Explicit refresh; no implicit dependency tracking |

The factory idea follows [Microsoft's IHttpClientFactory documentation](https://learn.microsoft.com/en-us/dotnet/core/extensions/httpclient-factory).
Immutable request transformation and ordered functions follow [Angular's interceptor
guide](https://angular.dev/guide/http/interceptors). These are design inspirations,
not API compatibility guarantees. Existing mature frameworks already implement many
of these concepts; this project adapts the useful parts to Dart's SDK-only constraint.

Useful additions here are bounded buffering, explicit stream disposal, replay-aware
policies, separate operation/attempt budgets, origin-scoped credentials, and request
capture testing. Protocol adapters remain separate instead of hiding their different
semantics behind a universal connection class.

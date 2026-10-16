# Documentation learning path

The package is version 1.0.3. Its core has no third-party runtime dependencies and
requires Dart >=3.4.0 <4.0.0. Publication status and verified checks are recorded
separately in [release guidance](releasing.md) and [validation](validation.md).

| Level / use case | Start here | Runnable example |
| --- | --- | --- |
| Application service and sign-in | [Injection, validation and application state](application_services.md) | [UserService](../example/lib/services/user_service.dart) |
| First GET request | [README quick start](../README.md#quick-start-configure-a-client) | [main.dart](../example/lib/main.dart) |
| Deterministic local HTTP | [Requests and readers](conveniences.md) | [local_http.dart](../example/lib/local_http.dart) |
| Typed application service | [Advanced composition](advanced.md#typed-services-and-ownership) | [typed_client.dart](../example/lib/typed_client.dart) |
| Headers, query, JSON, forms, uploads | [Convenience APIs](conveniences.md) | [Core regression examples](../test/http/services/convenience_test.dart) |
| Tests without networking | [Testing guide](testing.md) | [testing_client.dart](../example/lib/testing_client.dart) |
| Retries and timeout ordering | [Policy composition](usage.md) | [resilient_request.dart](../example/lib/resilient_request.dart) |
| Authentication refresh and retries | [Authenticated clients](advanced.md#authentication-and-retries) | [authenticated_client.dart](../example/lib/authenticated_client.dart) |
| Cache and credentials | [Cache boundaries](advanced.md#cache-and-session-boundaries) | [Cache tests](../test/caching/cache_interceptor_test.dart) |
| Native file uploads/downloads | [Files](conveniences.md#json-forms-and-file-uploads) | [download_file.dart](../example/lib/download_file.dart) |
| SSE and WebSockets | [Long-lived connections](advanced.md#persistent-connections) | [connections.dart](../example/lib/connections.dart) |
| Flutter loading/data/error UI | [Adapter README](../packages/flutter_client_factory_widgets/README.md) | [Flutter example](../packages/flutter_client_factory_widgets/example/README.md) |
| Browser / native transport configuration | [Platform matrix](platforms.md) | [Browser harness](../tool/browser/main.dart) |
| Lifecycle and common errors | [Troubleshooting](troubleshooting.md) | [Ownership tests](../test/factory/services/default_http_client_factory_test.dart) |
| API migration | [Migration guide](migration.md) | — |
| Package/application size | [Size methodology](size.md) | [Size fixtures](../tool/size/) |
| Contributing and releasing | [Architecture](architecture.md), [release checks](releasing.md) | [CI](../.github/workflows/ci.yaml) |

Links to test/tool files are repository references; those files are intentionally
excluded from the published source archive. Generated API documentation can be
built with `dart doc`; the generated output is excluded from publication.

There is one ordered interceptor list. Convenience APIs reuse the same pipeline,
streaming bodies, cancellation, and cleanup contracts. A high pub score checks
package conventions; it does not establish production suitability for every use case.

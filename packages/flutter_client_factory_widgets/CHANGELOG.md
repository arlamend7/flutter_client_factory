# Changelog

## 1.0.0

- Provide `HttpResourceNotifier<T>` to expose core resource state to Flutter.
- Add `fromLoader` for simple setup, explicit refresh, and owned cancellation.
- Support borrowed resources through `ownsResource: false`.
- Include a runnable ValueListenableBuilder example, lifecycle tests, and MIT license.
- Depend on `flutter_client_factory: ^1.0.0`; local checkout overrides are excluded
  from published archives. The core must be published before this adapter.

Requires Dart >=3.4.0 <4.0.0 and a compatible Flutter SDK. Notifiers do not own an
injected HTTP client or factory; dispose those at their owning scope boundary.

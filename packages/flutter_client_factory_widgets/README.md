# flutter_client_factory_widgets

An optional Flutter `ValueNotifier` adapter for `flutter_client_factory` resource state.
The pure Dart core has no dependency on this package or Flutter.

```dart
final notifier = HttpResourceNotifier<String>.fromLoader((token) async {
  final response = await client.getAsync('status', cancellationToken: token);
  await response.requireSuccess();
  return response.readText();
});
await notifier.refresh();
// Use ValueListenableBuilder<ResourceState<String>> to render notifier.value.
// Dispose notifier when its owner is removed.
```

Import `flutter_client_factory/flutter_client_factory.dart`, `flutter_client_factory/resources.dart` and
`flutter_client_factory_widgets/flutter_client_factory_widgets.dart`. The notifier owns its resource
by default. `fromLoader` always creates and owns its resource without eager loading;
use the existing resource constructor with `ownsResource: false` for a borrowed resource. It does
not own the HTTP client/factory. Refresh is explicit and cancels superseded reads.

See the [runnable Flutter example](example/README.md). Run `flutter pub get`,
`flutter analyze lib test example/lib`, and `flutter test` in this directory. MIT licensed. Release
version 1.0.0. The manifest uses `flutter_client_factory: ^1.0.0`; checkout-only
`pubspec_overrides.yaml` files resolve the local core during development. Publish
the core first. No publishing action is performed by this repository setup. Dart 3.4+ is required.

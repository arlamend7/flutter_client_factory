# flutter_client_widgets

An optional Flutter `ValueNotifier` adapter for `flutter_client` resource state.
The pure Dart core has no dependency on this package or Flutter.

```dart
final notifier = HttpResourceNotifier<String>(HttpResource((token) async {
  final response = await client.send(request, cancellationToken: token);
  return const ResponseBodyReader().readText(response);
}));
await notifier.refresh();
// Use ValueListenableBuilder<ResourceState<String>> to render notifier.value.
// Dispose notifier when its owner is removed.
```

Import `flutter_client/flutter_client.dart`, `flutter_client/resources.dart` and
`flutter_client_widgets/flutter_client_widgets.dart`. The notifier owns its resource
by default; pass `ownsResource: false` when another owner will dispose it. It does
not own the HTTP client/factory. Refresh is explicit and cancels superseded reads.

See the [runnable Flutter example](example/README.md). Run `flutter pub get`,
`flutter analyze`, and `flutter test` in this directory. MIT licensed. Development
preview, publication disabled. The local path dependency must become a hosted
version constraint after the core is published. Dart 3.4+ is required.

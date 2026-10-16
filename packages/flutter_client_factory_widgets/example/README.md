# Flutter user profile example

A complete example of loading API data into Flutter with `HttpResourceNotifier`.
It registers a named HTTP client with logging, a JSON Accept header and a ten-second
timeout, injects a service into a screen, validates responses, and decodes a model.
The UI displays loading, data and error states and supports refresh and retry.

## Run locally

From `packages/flutter_client_factory_widgets/example`:

```sh
flutter pub get
flutter create --platforms=web .
flutter run -d chrome
```

Generate the runner locally; platform runner files are not included in the package.
The application calls JSONPlaceholder and needs internet access. It has no login
or credentials. Its widget tests use a fake backend and do not require networking.

## Ownership and refresh

- The application state creates and owns the factory/client/service once.
- The screen receives the service and owns its notifier. It starts loading in
  `initState`, not `build`.
- The loader passes cancellation to the request, checks `isSuccessful`, disposes
  HTTP failures, and converts successful JSON into `UserSummary`.
- Refresh cancels a pending read; the Refresh button remains usable during loading.
  Previous data remains visible while reloading or showing a refresh error.
- Removing the screen disposes its notifier and cancels its request. Removing the
  application root also disposes its client and starts factory shutdown. Flutter's
  synchronous `dispose` cannot await shutdown; applications with an explicit async
  session lifecycle can await `factory.close()` there instead.

Each class is in its own file. Copy the following files under `example/lib`.

See [the complete example](example.md) for every source file, including the
registration, service, model, widget and state. This is also the higher-priority
file selected for the pub.dev Example tab. Keep its code blocks synchronized with
the runnable source files.

For adapter behavior tests, run `flutter test` from the adapter package directory.

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

## Entry point

`lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'client_example_app.dart';

void main() => runApp(const ClientExampleApp());
```

## Application widget

`lib/client_example_app.dart`

```dart
import 'package:flutter/material.dart';
import 'client_example_app_state.dart';

/// Owns the example application's HTTP configuration and lifetime.
class ClientExampleApp extends StatefulWidget {
  const ClientExampleApp({super.key});

  @override
  State<ClientExampleApp> createState() => ClientExampleAppState();
}
```

## Client registration and lifetime

`lib/client_example_app_state.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_client_factory/diagnostics.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'client_example_app.dart';
import 'resource_demo.dart';
import 'services/users_service.dart';

class ClientExampleAppState extends State<ClientExampleApp> {
  final _factory = DefaultHttpClientFactory();
  late final HttpClient _client;
  late final UsersService _users;

  @override
  void initState() {
    super.initState();
    final logging = DiagnosticsInterceptor((event) => debugPrint('$event'));
    _factory.registerClient('api',
        baseUrl: 'https://jsonplaceholder.typicode.com/',
        defaultHeaders: {'Accept': 'application/json'},
        timeout: const Duration(seconds: 10),
        interceptors: [logging.intercept]);
    _client = _factory.create('api');
    _users = UsersService(client: _client);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'HTTP resource example', home: ResourceDemo(users: _users));

  @override
  void dispose() {
    _client.dispose();
    // Flutter's dispose is synchronous; the app owns asynchronous shutdown.
    unawaited(_factory.close());
    super.dispose();
  }
}
```

## HTTP service

`lib/services/users_service.dart`

```dart
import 'package:flutter_client_factory/flutter_client_factory.dart';

/// Borrows its client; callers own response validation and consumption.
class UsersService {
  UsersService({required HttpClient client}) : _client = client;
  final HttpClient _client;

  Future<HttpResponse> getUser(int id, {CancellationToken? cancellationToken}) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');
    return _client.getAsync('users/$id', cancellationToken: cancellationToken);
  }
}
```

## Typed response model

`lib/models/user_summary.dart`

```dart
/// The fields this screen needs from its API response.
class UserSummary {
  const UserSummary({required this.id, required this.name});

  factory UserSummary.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a user object.');
    }
    final id = value['id'];
    final name = value['name'];
    if (id is! int || name is! String) {
      throw const FormatException('Expected an integer id and a string name.');
    }
    return UserSummary(id: id, name: name);
  }

  final int id;
  final String name;
}
```

## Screen with an injected service

`lib/resource_demo.dart`

```dart
import 'package:flutter/material.dart';
import 'resource_demo_state.dart';
import 'services/users_service.dart';

/// Receives a reusable service; owns only its screen's resource notifier.
class ResourceDemo extends StatefulWidget {
  const ResourceDemo({required this.users, super.key});
  final UsersService users;

  @override
  State<ResourceDemo> createState() => ResourceDemoState();
}
```

## Loading, validation, refresh and error UI

`lib/resource_demo_state.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resources.dart';
import 'package:flutter_client_factory_widgets/flutter_client_factory_widgets.dart';
import 'models/user_summary.dart';
import 'resource_demo.dart';

class ResourceDemoState extends State<ResourceDemo> {
  late final HttpResourceNotifier<UserSummary> _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = HttpResourceNotifier.fromLoader(_loadUser);
    unawaited(_notifier.refresh());
  }

  Future<UserSummary> _loadUser(CancellationToken token) async {
    final response = await widget.users.getUser(1, cancellationToken: token);
    if (!response.isSuccessful) {
      await response.dispose();
      throw HttpStatusException(response.statusCode,
          headers: response.headers, uri: response.uri);
    }
    return response.readJson(decode: UserSummary.fromJson);
  }

  @override
  void didUpdateWidget(covariant ResourceDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.users, widget.users)) return;
    unawaited(_notifier.refresh());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('User profile')),
        body: Center(
          child: ValueListenableBuilder<ResourceState<UserSummary>>(
            valueListenable: _notifier,
            builder: (context, state, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isLoading) const CircularProgressIndicator(),
                if (state.error != null)
                  const Text('Could not load the user. Please try again.'),
                if (state.data != null) Text('Hello, ${state.data!.name}'),
                if (!state.isLoading &&
                    state.error == null &&
                    state.data == null)
                  const Text('No user loaded yet.'),
                FilledButton(
                  onPressed: () => unawaited(_notifier.refresh()),
                  child: Text(state.error == null ? 'Refresh' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  void dispose() {
    // Cancels the owned resource's pending request before releasing listeners.
    _notifier.dispose();
    super.dispose();
  }
}
```

## Test without a live API

From the adapter package directory:

```sh
flutter test
```

The widget tests inject `UsersService` with an `HttpTestingController` client.
They cover loading → typed data, refreshing, HTTP failure → retry → recovery,
cancellation of superseded reads, and disposal during a pending request.

# Client registration, services, and response handling

This example uses the existing public API to configure logging, a JSON Accept
header and a timeout, inject a client into a service, validate HTTP responses,
and read either a custom model or plain text.

Run it from the repository checkout:

```sh
dart pub get
dart run example/flutter_client_factory_example.dart
```

It uses the public JSONPlaceholder API and requires internet access. Replace its
base URL and routes with your own backend. Each class remains in a separate file.

## What this example demonstrates

1. Register a named client with logging, default headers and an overall timeout.
2. Inject the client into a reusable service.
3. Check `response.isSuccessful` and return early on HTTP failure.
4. Decode JSON into `ExampleUser`, or read a separate response as `String`.
5. Release responses and close clients at their owning scope boundary.

## Register and use the client

`example/flutter_client_factory_example.dart`

```dart
import 'dart:developer' as developer;

import 'package:flutter_client_factory/diagnostics.dart';
import 'package:flutter_client_factory/flutter_client_factory.dart';

import 'lib/models/example_user.dart';
import 'lib/services/user_service.dart';

/// Run with `dart run example/flutter_client_factory_example.dart`.
/// JSONPlaceholder requires internet access; substitute your own API as needed.
Future<void> main() async {
  final factory = DefaultHttpClientFactory();
  final logging = DiagnosticsInterceptor(
    (event) => developer.log('$event', name: 'http'),
  );
  factory.registerClient(
    'api',
    baseUrl: 'https://jsonplaceholder.typicode.com/',
    defaultHeaders: {'Accept': 'application/json'},
    timeout: const Duration(seconds: 10),
    interceptors: [logging.intercept],
  );

  // Register/inject this service once at the application or session boundary.
  final client = factory.create('api');
  final users = UserService(client: client);
  try {
    await showUser(users);
    await showUserAsText(users);
  } finally {
    client.dispose();
    // A real application closes its factory when the owning scope ends.
    await factory.close();
  }
}

/// The caller decides how HTTP failures affect application/UI state.
Future<void> showUser(UserService users) async {
  final response = await users.getUser(1);
  if (!response.isSuccessful) {
    await response.dispose();
    developer.log('Could not load user: HTTP ${response.statusCode}',
        name: 'example');
    return;
  }

  final user = await response.readJson(decode: ExampleUser.fromJson);
  // Update application state or navigate here, after validation and decoding.
  // ignore: avoid_print
  print('User ${user.id}: ${user.name}');
}

/// Text reading works for any UTF-8 body, including unparsed JSON text.
Future<void> showUserAsText(UserService users) async {
  final response = await users.getUser(1);
  if (!response.isSuccessful) {
    await response.dispose();
    developer.log('Could not load text: HTTP ${response.statusCode}',
        name: 'example');
    return;
  }

  final String text = await response.readText();
  // ignore: avoid_print
  print(text);
}
```

## Keep API requests in a service

`example/lib/services/user_service.dart`

```dart
import 'package:flutter_client_factory/flutter_client_factory.dart';
import '../models/example_user.dart';

/// Sends user requests; callers own response validation, decoding and cleanup.
class UserService {
  UserService({required HttpClient client}) : _client = client;

  final HttpClient _client;

  Future<HttpResponse> getUser(int id, {CancellationToken? cancellationToken}) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');
    return _client.getAsync('users/$id', cancellationToken: cancellationToken);
  }

  Future<HttpResponse> findUsers(String email,
          {CancellationToken? cancellationToken}) =>
      _client.getAsync('users',
          queryParameters: {'email': email},
          cancellationToken: cancellationToken);

  Future<HttpResponse> createUser(ExampleUser user,
          {CancellationToken? cancellationToken}) =>
      _client.postAsync('users',
          body: JsonRequestBody(user.toJson()),
          cancellationToken: cancellationToken);

  Future<HttpResponse> updateUser(ExampleUser user,
          {CancellationToken? cancellationToken}) =>
      _client.putAsync('users/${user.id}',
          body: JsonRequestBody(user.toJson()),
          cancellationToken: cancellationToken);
}
```

## Convert JSON to your own model

`example/lib/models/example_user.dart`

```dart
class ExampleUser {
  const ExampleUser({required this.id, required this.name});

  factory ExampleUser.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected a user object.');
    }

    final Object? id = json['id'];
    final Object? name = json['name'];
    if (id is! int || name is! String) {
      throw const FormatException('Expected an integer id and a string name.');
    }

    return ExampleUser(id: id, name: name);
  }

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  final int id;
  final String name;
}
```

## Response and client ownership

- `isSuccessful` is true for HTTP 200–299. Dispose unsuccessful responses before
  returning early, or consume the error body when your application needs it.
- `readJson(decode: ...)` converts JSON into your model; `readText()` returns a
  UTF-8 string. Both consume and release the response, including on decoding failure.
- Each response body can be read once. The example makes separate requests for
  the model and text demonstrations.
- HTTP failures are responses; network errors, timeouts and cancellation throw.
  Handle those exceptions at your application's owning boundary.
- `DiagnosticsInterceptor` is the built-in logging interceptor. It omits body and
  query contents and redacts standard credential headers.
- Keep the factory at application/session scope and close it when that scope ends.
  Dispose a logical client when its owner releases it.

For forms, authentication, retries, cancellation, tests and Flutter integration,
see the [usage recipes](https://github.com/arlamend7/flutter_client_factory/blob/main/README.md)
and [example catalogue](https://github.com/arlamend7/flutter_client_factory/blob/main/example/README.md).


## Validate the example without internet access

The same service is tested using `HttpTestingController`, including HTTP failures,
invalid JSON models, response cleanup, cancellation and POST/PUT request bodies:

```sh
dart test test/example/user_service_test.dart
```

JSONPlaceholder simulates writes; it does not persist created or updated users.

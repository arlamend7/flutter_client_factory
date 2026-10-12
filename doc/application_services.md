# Application services and sign-in

Use this pattern when the application should choose whether an HTTP failure shows
an error, returns early, or updates state. Services return the existing
`HttpResponse`; JSON conversion is an explicit callback. HTTP responses always
exist on successful completion of the Future; network/cancellation/timeout failures
throw instead. There is no separate `hasResponse` or `asResponse` wrapper.

## Separate registration from service code

Register a named client with logging, headers and timeout as shown in the
[README](../README.md#quick-start-configure-a-client), then inject it:

```dart
final client = factory.create('api');
final authentication = AuthenticationService(client: client);
```

The service only owns the endpoint contract. This example assumes your backend
accepts `POST auth/login` and returns `{"token":"...","user":{"id":1,"name":"Ada"}}`.
It is not an endpoint provided by JSONPlaceholder; adapt its route and JSON keys.

```dart
import 'package:flutter_client_factory/flutter_client_factory.dart';

/// Example contract for your backend, not a JSONPlaceholder endpoint.
class AuthenticationService {
  AuthenticationService({required HttpClient client}) : _client = client;

  final HttpClient _client;

  Future<HttpResponse> login(String email, String password,
          {CancellationToken? cancellationToken}) =>
      _client.postAsync('auth/login',
          body: JsonRequestBody({'email': email, 'password': password}),
          cancellationToken: cancellationToken);
}
```

## Decode an application value

Keep the model in its own file. Validate required fields instead of silently
accepting an invalid response. `ExampleUser` is the model from the default example.

```dart
import 'example_user.dart';

/// Example application contract; adapt these JSON keys to your own backend.
class LoginResult {
  const LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected a login object.');
    }
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Expected a non-empty token.');
    }
    return LoginResult(token: token, user: ExampleUser.fromJson(json['user']));
  }

  final String token;
  final ExampleUser user;
}
```

## Validate before updating state

Place this function in your application/controller layer. The callbacks stand for
your own storage and navigation, keeping the example independent of UI, persistence
and service-locator packages:

```dart
Future<void> signIn({
  required AuthenticationService authentication,
  required String email,
  required String password,
  required Future<void> Function(LoginResult result) saveSession,
  required void Function() onSignedIn,
  required void Function(int statusCode) onHttpFailure,
  CancellationToken? cancellationToken,
}) async {
  final response = await authentication.login(
    email,
    password,
    cancellationToken: cancellationToken,
  );
  if (!response.isSuccessful) {
    await response.dispose();
    onHttpFailure(response.statusCode);
    return;
  }

  final result = await response.readJson(decode: LoginResult.fromJson);
  await saveSession(result);
  onSignedIn();
}
```

Handle transport/timeout/cancellation and malformed JSON exceptions at your owning
application boundary; they do not produce a successful sign-in or trigger navigation.
`readJson` releases the response even if the decoder throws. Never log the password,
token, or complete login body. The built-in diagnostics interceptor omits bodies.
Use your platform's appropriate session/token storage, supplied through the callback.

## Choose where decoding belongs

- `UserService` / `AuthenticationService`: return responses; the caller controls
  status handling and conversion, as above.
- `ExampleUsersApi`: returns a model, validates internally, and throws
  `HttpStatusException` for HTTP failures.

Both use the same client and interceptor pipeline. Choose one convention per
application layer and document who consumes each response. Services borrow their
injected clients; the composition root owns their lifetime.

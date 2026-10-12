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

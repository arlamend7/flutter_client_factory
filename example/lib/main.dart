import 'dart:convert';
import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/testing.dart';
import 'defaults/example_client_options.dart';
import 'services/example_users_api.dart';

Future<void> main() async {
  final factory = DefaultHttpClientFactory();
  factory.register(
    'users',
    ClientRegistration(
      options: ExampleClientOptions.create(),
      createTransport: () =>
          FakeHttpTransport((request, cancellationToken) async {
        return HttpResponse.bytes(
          statusCode: 200,
          bytes: utf8.encode('{"id":1,"name":"Ada"}'),
        );
      }),
    ),
  );

  final users = factory.createTyped('users', ExampleUsersApi.new);

  try {
    final user = await users.getById(1);
    // ignore: avoid_print
    print('${user.id}: ${user.name}');
  } finally {
    users.dispose();
    await factory.close();
  }
}

import 'package:flutter_client_factory/flutter_client_factory.dart';

Future<void> main() async {
  final factory = DefaultHttpClientFactory();
  factory.registerClient('api',
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      timeout: const Duration(seconds: 10));

  try {
    final response = await factory.create('api').getAsync('todos/1');
    await response.requireSuccess();
    // ignore: avoid_print
    print(await response.readText());
  } finally {
    await factory.close();
  }
}

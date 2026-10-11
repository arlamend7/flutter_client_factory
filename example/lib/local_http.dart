import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_client_factory/flutter_client_factory.dart';

Future<void> main() async {
  final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response.headers.contentType = io.ContentType.json;
    request.response.write(jsonEncode({'message': 'Hello from real HTTP'}));
    await request.response.close();
  });
  final factory = DefaultHttpClientFactory();
  factory.registerClient(
    'local',
    baseUrl: 'http://127.0.0.1:${server.port}/',
    defaultHeaders: {'Accept': 'application/json'},
  );
  final client = factory.create('local');
  try {
    final response =
        await client.getAsync('greeting', timeout: const Duration(seconds: 5));
    final message = await response.readJson<String>(decode: (value) {
      if (value is! Map<String, dynamic> || value['message'] is! String) {
        throw const FormatException('Expected a message.');
      }
      return value['message'] as String;
    });
    io.stdout.writeln(message);
  } finally {
    client.dispose();
    await factory.close();
    await server.close(force: true);
  }
}

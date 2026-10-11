import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_client/flutter_client.dart';

Future<void> main() async {
  final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response.headers.contentType = io.ContentType.json;
    request.response.write(jsonEncode({'message': 'Hello from real HTTP'}));
    await request.response.close();
  });
  final factory = DefaultHttpClientFactory();
  factory.register(
      'local',
      ClientRegistration(
        createTransport: createPlatformTransport,
        options: HttpClientOptions(
            baseUri: Uri.parse('http://127.0.0.1:${server.port}/')),
      ));
  final client = factory.create('local');
  try {
    final response = await client.send(HttpRequest(uri: Uri.parse('greeting')));
    final message =
        await const ResponseBodyReader().readJson<String>(response, (value) {
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

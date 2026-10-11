import 'dart:convert';
import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/testing.dart';

Future<void> main() async {
  final controller = HttpTestingController();
  final client = HttpClientService(transport: controller);
  try {
    final pending = client
        .send(HttpRequest(uri: Uri.parse('https://example.invalid/users')));
    controller.expectOne('https://example.invalid/users').flush(
        HttpResponse.bytes(statusCode: 200, bytes: utf8.encode('["Ada"]')));
    final response = await pending;
    // ignore: avoid_print
    print(await const ResponseBodyReader().readText(response));
    controller.verify();
  } finally {
    client.dispose();
    await controller.close();
  }
}

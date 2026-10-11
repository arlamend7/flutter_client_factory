import 'dart:convert';
import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/resilience.dart';
import 'package:flutter_client/testing.dart';

Future<void> main() async {
  var attempts = 0;
  final transport = FakeHttpTransport((request, token) async {
    attempts++;
    return HttpResponse.bytes(
        statusCode: attempts == 1 ? 503 : 200,
        bytes: utf8.encode(attempts == 1 ? 'Try again' : 'Recovered'));
  });
  final client = HttpClientService(
      transport: transport,
      options: HttpClientOptions(
        interceptors: [
          TimeoutInterceptor(const Duration(seconds: 2)).intercept,
          RetryInterceptor(options: RetryOptions(baseDelay: Duration.zero))
              .intercept,
        ],
      ));
  try {
    final response = await client
        .send(HttpRequest(uri: Uri.parse('https://example.invalid/status')));
    final text = await const ResponseBodyReader().readText(response);
    // ignore: avoid_print
    print('$text after $attempts attempts');
  } finally {
    client.dispose();
    await transport.close();
  }
}

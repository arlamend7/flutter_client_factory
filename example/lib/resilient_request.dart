import 'dart:convert';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/resilience.dart';
import 'package:flutter_client_factory/testing.dart';

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
    final response = await client.getAsync('https://example.invalid/status');
    final text = await response.readText();
    // ignore: avoid_print
    print('$text after $attempts attempts');
  } finally {
    client.dispose();
    await transport.close();
  }
}

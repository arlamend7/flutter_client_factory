import 'dart:async';
import 'package:flutter_client_factory/flutter_client_factory.dart';
import 'package:flutter_client_factory/testing.dart';
import 'package:test/test.dart';

void main() {
  test(
      'retirement keeps active streams alive and routes old clients to new transports',
      () async {
    var clock = DateTime.utc(2026);
    final transports = <FakeHttpTransport>[];
    final factory = DefaultHttpClientFactory(clock: () => clock);
    factory.register(
        'api',
        ClientRegistration(
            transportLifetime: const Duration(seconds: 1),
            createTransport: () {
              final transport = FakeHttpTransport(
                  (r, t) async => HttpResponse.bytes(statusCode: 200));
              transports.add(transport);
              return transport;
            }));
    final client = factory.create('api');
    final first = await client
        .send(HttpRequest(uri: Uri.parse('https://example.invalid/')));
    clock = clock.add(const Duration(seconds: 2));
    final second = await client
        .send(HttpRequest(uri: Uri.parse('https://example.invalid/')));
    expect(transports.length, 2);
    expect(transports.first.isClosed, isFalse);
    await first.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(transports.first.isClosed, isTrue);
    await second.dispose();
    await factory.close();
  });
}

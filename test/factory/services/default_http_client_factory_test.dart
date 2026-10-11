import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/testing.dart';
import 'package:test/test.dart';

void main() {
  test('disposing a wrapper leaves the shared transport usable', () async {
    final factory = DefaultHttpClientFactory();
    final transport = FakeHttpTransport((request, token) async {
      return HttpResponse.bytes(statusCode: 200);
    });
    var builds = 0;
    factory.register('api', ClientRegistration(createTransport: () {
      builds++;
      return transport;
    }));
    addTearDown(factory.close);

    final first = factory.create('api');
    final second = factory.create('api');
    addTearDown(second.dispose);
    first.dispose();

    final response = await second.send(
      HttpRequest(uri: Uri.parse('https://example.invalid/')),
    );
    await response.body.drain<void>();

    expect(builds, 1);
    expect(transport.isClosed, isFalse);
    await expectLater(
      first.send(HttpRequest(uri: Uri.parse('https://example.invalid/'))),
      throwsStateError,
    );

    final closing = factory.close();
    expect(identical(closing, factory.close()), isTrue);
    await closing;

    expect(transport.isClosed, isTrue);
    expect(() => factory.create('api'), throwsStateError);
    await expectLater(
      second.send(HttpRequest(uri: Uri.parse('https://example.invalid/'))),
      throwsStateError,
    );
  });

  test('duplicate registration cannot silently replace a live configuration',
      () {
    final factory = DefaultHttpClientFactory();
    final registration = ClientRegistration(
      createTransport: () => FakeHttpTransport((request, token) async {
        return HttpResponse.bytes(statusCode: 200);
      }),
    );
    addTearDown(factory.close);
    factory.register('api', registration);

    expect(() => factory.register('api', registration), throwsStateError);
    expect(() => factory.create('missing'), throwsStateError);
  });
}

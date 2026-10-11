import 'package:flutter_client/flutter_client.dart';
import 'package:flutter_client/testing.dart';
import 'package:test/test.dart';

void main() {
  test('middleware runs in order and unwinds responses in reverse order',
      () async {
    final events = <String>[];
    final transport = FakeHttpTransport((request, token) async {
      events.add('transport');
      return HttpResponse.bytes(statusCode: 200);
    });
    final client = HttpClientService(
      transport: transport,
      options: HttpClientOptions(
        baseUri: Uri.parse('https://example.invalid/api/'),
        interceptors: <HttpInterceptor>[
          (request, token, next) async {
            events.add('first request');
            final response = await next(request, token);
            events.add('first response');
            return response;
          },
          (request, token, next) async {
            events.add('second request');
            final response = await next(request, token);
            events.add('second response');
            return response;
          },
        ],
      ),
    );
    addTearDown(transport.close);
    addTearDown(client.dispose);

    final response = await client.send(
      HttpRequest(uri: Uri.parse('users?tag=one&tag=two')),
    );
    await response.body.drain<void>();

    expect(events, <String>[
      'first request',
      'second request',
      'transport',
      'second response',
      'first response',
    ]);
    expect(transport.requests.single.uri.path, '/api/users');
    expect(transport.requests.single.uri.queryParametersAll['tag'],
        <String>['one', 'two']);
  });

  test('pre-canceled requests never reach the transport', () async {
    final transport = FakeHttpTransport((request, token) async {
      return HttpResponse.bytes(statusCode: 200);
    });
    final client = HttpClientService(transport: transport);
    final token = CancellationToken()..cancel('No longer needed');
    addTearDown(transport.close);
    addTearDown(client.dispose);

    await expectLater(
      client.send(
        HttpRequest(uri: Uri.parse('https://example.invalid/')),
        cancellationToken: token,
      ),
      throwsA(isA<RequestCanceledException>()),
    );

    expect(transport.requests, isEmpty);
  });

  test('synthetic responses skip transport and 500 is not successful',
      () async {
    final transport = FakeHttpTransport((request, token) async {
      fail('A short-circuit response must not reach the transport.');
    });
    final client = HttpClientService(
      transport: transport,
      options: HttpClientOptions(interceptors: <HttpInterceptor>[
        (request, token, next) async => HttpResponse.bytes(statusCode: 500),
      ]),
    );
    addTearDown(transport.close);
    addTearDown(client.dispose);

    final response = await client.send(
      HttpRequest(uri: Uri.parse('https://example.invalid/')),
    );

    expect(response.isSuccessful, isFalse);
    expect(transport.requests, isEmpty);
    await response.body.drain<void>();
  });
}
